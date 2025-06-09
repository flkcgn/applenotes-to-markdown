# Export & Convert Apple Notes to Markdown (Obsidian-Ready)
This is an AppleScript that exports your Apple Notes to clean Markdown (`.md`) files, fully compatible with [Obsidian](https://obsidian.md/).

## Features
✅ Select a folder from Apple Notes → all notes in that folder will be exported  
✅ Converts notes to Markdown using Pandoc  
✅ Removes all HTML tags  
✅ Replaces embedded base64 images with Markdown image placeholders  
✅ Normalizes all headers (H1-H6) → ensures proper `# Header` format  
✅ Removes unnecessary empty lines  

---

## Requirements
### macOS Version
- macOS Ventura or later recommended
- Tested with Apple Notes App (2025)

### Software dependencies
- **Pandoc** must be installed  

#### Install Pandoc with Homebrew:
```bash
brew install pandoc
