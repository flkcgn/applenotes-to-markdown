-- Export & convert Apple Notes to MD (final version v11 - obsidian final)
-- Author: Falk Baumhauer

set exportFolder to (choose folder with prompt "Select the destination folder:")

tell application "Notes"
	-- collect all folder names
	set folderNames to {}
	repeat with f in folders
		set end of folderNames to name of f
	end repeat
end tell

-- Add "All Notes" option
set end of folderNames to "All Notes"

-- choose user folder
set chosenFolderName to (choose from list folderNames with prompt "Which notes folder would you like to export?" without multiple selections allowed)
if chosenFolderName is false then
	display dialog "No folder selected." buttons {"OK"} default button "OK"
	return
end if

set chosenFolderName to item 1 of chosenFolderName

-- Collect all notes from the selected folder(s)
set noteNames to {}
set errorNotes to {}
set totalNotes to 0

tell application "Notes"
	if chosenFolderName is "All Notes" then
		-- Collect notes from all folders
		repeat with f in folders
			set notesInFolder to notes of f
			repeat with thisNote in notesInFolder
				set noteName to name of thisNote
				set noteID to id of thisNote
				set folderName to name of f
				set end of noteNames to {noteName, noteID, folderName}
				set totalNotes to totalNotes + 1
			end repeat
		end repeat
	else
		-- Collect notes from selected folder
		set chosenFolder to first folder whose name is chosenFolderName
		set notesInFolder to notes of chosenFolder
		
		repeat with thisNote in notesInFolder
			set noteName to name of thisNote
			set noteID to id of thisNote
			set end of noteNames to {noteName, noteID, chosenFolderName}
			set totalNotes to totalNotes + 1
		end repeat
	end if
end tell

repeat with noteInfo in noteNames
	try
		set noteName to item 1 of noteInfo
		set noteID to item 2 of noteInfo
		set folderName to item 3 of noteInfo
		
		-- Create folder structure if exporting all notes
		if chosenFolderName is "All Notes" then
			set folderPath to (POSIX path of exportFolder) & folderName & "/"
			do shell script "mkdir -p " & quoted form of folderPath
		else
			set folderPath to (POSIX path of exportFolder)
		end if
		
		-- sanitize filename
		set safeNoteName to do shell script "echo " & quoted form of noteName & " | tr -cd '[:alnum:]-_'"
		set htmlPath to folderPath & safeNoteName & ".html"
		set mdPath to folderPath & safeNoteName & ".md"
		
		-- export note content as HTML
		tell application "Notes"
			set noteContent to body of (first note whose id is noteID)
		end tell
		
		-- wrap note content into valid HTML
		set htmlHeader to "<html><head><meta charset=\"utf-8\"></head><body>"
		set htmlFooter to "</body></html>"
		set fullHTML to htmlHeader & noteContent & htmlFooter
		
		-- write HTML to file
		set htmlFileRef to open for access (POSIX file htmlPath) with write permission
		set eof of htmlFileRef to 0
		write fullHTML to htmlFileRef as «class utf8»
		close access htmlFileRef
		
		-- convert HTML to Markdown via Pandoc
		do shell script "/opt/homebrew/bin/pandoc " & quoted form of htmlPath & " -f html -t markdown --wrap=none --standalone --extract-media=. --markdown-headings=atx -o " & quoted form of mdPath
		
		-- cleanup Markdown file
		set cleanupScript to "
		# Remove HTML tags and attributes
		sed -E -i '' 's/<[^>]+>//g' " & quoted form of mdPath & "
		sed -E -i '' 's/\\{[^}]+\\}//g' " & quoted form of mdPath & "
		
		# Handle attachments and images
		sed -E -i '' 's|!\\[.*\\]\\(data:image/[^;]+;base64,[^)]+\\)|![Attachment](attachment.png)|g' " & quoted form of mdPath & "
		sed -E -i '' 's|!\\[.*\\]\\([^)]+\\)\\{[^}]+\\}|![Attachment](attachment.png)|g' " & quoted form of mdPath & "
		sed -E -i '' 's|\\[([^\\]]+)\\]\\(data:image/[^;]+;base64,[^)]+\\)|[\\1](attachment.png)|g' " & quoted form of mdPath & "
		
		# Normalize headers
		sed -E -i '' -e 's/^([^]+)[[:space:]]*\\n=+$/# \\1/g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/^([^]+)[[:space:]]*\\n-+$/## \\1/g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/^(#{1,6})[[:space:]]*/\\1 /g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/^[[:space:]]*(#{1,6})[[:space:]]*/\\1 /g' " & quoted form of mdPath & "
		
		# Fix list formatting
		sed -E -i '' -e 's/^([[:space:]]*)[0-9]+\\./\\1- /g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/^([[:space:]]*)[a-z]\\)/\\1- /g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/^([[:space:]]*)[A-Z]\\)/\\1- /g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/^([[:space:]]*)[ivxIVX]+\\./\\1- /g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/^([[:space:]]*)[•○◆]/\\1- /g' " & quoted form of mdPath & "
		
		# Fix URL formatting
		sed -E -i '' -e 's/\\\\$//g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/&amp;/&/g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/%2a/*/g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/%2f/\\//g' " & quoted form of mdPath & "
		
		# Fix table formatting
		sed -E -i '' -e '/^\\+[-+]+\\+$/d' " & quoted form of mdPath & "
		sed -E -i '' -e '/^\\|[[:space:]]*\\|$/d' " & quoted form of mdPath & "
		sed -E -i '' -e 's/^\\|[[:space:]]*$//' " & quoted form of mdPath & "
		sed -E -i '' -e 's/\\|/ | /g' " & quoted form of mdPath & "
		
		# Fix code blocks
		sed -E -i '' -e 's/^```[[:space:]]*$/```\\n/g' " & quoted form of mdPath & "
		sed -E -i '' -e 's/^[[:space:]]*```$/\\n```/g' " & quoted form of mdPath & "
		
		# Normalize empty lines and remove trailing spaces
		sed -E -i '' -e 's/[[:space:]]+$//' " & quoted form of mdPath & "
		awk 'BEGIN{blank=0} {if ($0 ~ /^$/) {blank++; if (blank < 2) print \"\"} else {blank=0; print $0}}' " & quoted form of mdPath & " > " & quoted form of mdPath & ".tmp && mv " & quoted form of mdPath & ".tmp " & quoted form of mdPath & "
		
		# Add title at the top
		echo '# " & quoted form of noteName & "' > " & quoted form of mdPath & ".tmp
		cat " & quoted form of mdPath & " >> " & quoted form of mdPath & ".tmp
		mv " & quoted form of mdPath & ".tmp " & quoted form of mdPath & "
		"
		
		do shell script cleanupScript
		
		-- delete temporary HTML file
		do shell script "rm -f " & quoted form of htmlPath
		
	on error errMsg number errNum
		set end of errorNotes to {noteName, folderName, errMsg, errNum}
		-- Clean up any temporary files in case of error
		try
			do shell script "rm -f " & quoted form of htmlPath
			do shell script "rm -f " & quoted form of mdPath
		end try
	end try
end repeat

-- Show summary of errors
if (count of errorNotes) > 0 then
	set errorText to "Export completed with " & (count of errorNotes) & " errors out of " & totalNotes & " notes:" & return & return
	repeat with errorInfo in errorNotes
		set errorText to errorText & "• " & item 1 of errorInfo & " (" & item 2 of errorInfo & ")" & return
	end repeat
	
	-- Create a temporary file with the error list
	set tempFile to (POSIX path of exportFolder) & "export_errors.txt"
	do shell script "echo " & quoted form of errorText & " > " & quoted form of tempFile
	
	-- Show dialog with copy option
	display dialog errorText & return & "Error details have been saved to:" & return & tempFile buttons {"Copy to Clipboard", "OK"} default button "OK"
	
	-- If user chooses to copy, copy the error list to clipboard
	if button returned of result is "Copy to Clipboard" then
		set the clipboard to errorText
	end if
else
	display dialog "Export completed successfully! All " & totalNotes & " notes were exported." buttons {"OK"} default button "OK"
end if