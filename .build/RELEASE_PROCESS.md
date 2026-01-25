# LockSmithPro - Release Process

## Steps to Create a New Version Release

### 1. Update Version Numbers
- **Init.lua**: Update `LockSmithPro.version = "X.X.X"`
- **LockSmithPro.toc**:
  - Update `## Version: X.X.X`
  - Update the `## Notes:` section with new version info and features

### 2. Update Documentation
- **CHANGELOG.md**: Add new version section at the top with:
  - Version number and edition name
  - Bug fixes (if any)
  - New features (if any)
  - Breaking changes (if any)
- **README.md**: Update version badge if needed

### 3. Create Version Archive

#### Option A: Using PowerShell Script (Recommended)
```powershell
.\update-version.ps1 -NewVersion "1.0.1"
```
This will automatically update all version references in the files.

#### Option B: Manual Process
1. Create a temporary folder named `LockSmithPro`
2. Copy all the required files to the `LockSmithPro` folder:
   - **All Lua files**:
     - Init.lua
     - SlashCommands.lua
   - **Folders**:
     - Core/ (Utils.lua, Skills.lua, Statistics.lua)
     - Data/ (Database.lua)
     - Features/ (Advertisement.lua, AutoResponse.lua, ChatMonitor.lua)
     - UI/ (Dashboard.lua, Notification.lua, Settings.lua, Minimap.lua)
     - logo/ (all icon/texture files)
   - **TOC file**:
     - LockSmithPro.toc
3. Create a zip archive of the entire `LockSmithPro` folder using PowerShell:
   ```powershell
   Compress-Archive -Path .\LockSmithPro -DestinationPath ".\versions\LockSmithPro V1.0.X - Edition Name.zip" -Force
   ```
   - Replace `1.0.X` with the new version number
   - Replace `Edition Name` with a descriptive name (e.g., "Initial Release", "Bug Fix Edition", "Feature Update")
4. Clean up the temporary folder:
   ```powershell
   Remove-Item -Recurse -Force .\LockSmithPro
   ```

### 4. Verify Archive
- Check that the zip file was created in the `versions/` folder
- **Important**: When extracted, the zip should create a `LockSmithPro` folder containing all the addon files
- This allows users to extract directly to their `Interface/AddOns/` folder
- Verify all Lua files and the logo folder are present

### 5. Push to GitHub
Commit and push all changes to the repository:
```bash
git add .
git commit -m "Version X.X.X - Edition Name"
git push origin main
```

### 6. Upload to CurseForge
1. Log in to CurseForge Authors portal
2. Go to your LockSmithPro project
3. Click "Files" → "Upload File"
4. Upload the zip file from `versions/` folder
5. Fill in the version information and changelog
6. Select compatible WoW versions
7. Publish the release

## File Inclusion Rules

### **Included in release:**
- All .lua files in root directory (Init.lua, SlashCommands.lua)
- All .lua files in subdirectories:
  - Core/ (Utils.lua, Skills.lua, Statistics.lua)
  - Data/ (Database.lua)
  - Features/ (Advertisement.lua, AutoResponse.lua, ChatMonitor.lua)
  - UI/ (Dashboard.lua, Notification.lua, Settings.lua, Minimap.lua)
- LockSmithPro.toc file
- logo/ folder with all texture files

### **Excluded from release:**
- .git folder and git files (.gitignore)
- .claude folder
- .vscode folder
- versions/ folder and its contents
- .md files (README.md, CHANGELOG.md, RELEASE_PROCESS.md, Curseforge_Description.mkd)
- update-version scripts (.ps1, .sh)
- Development and documentation files

## Version Naming Convention
Format: `LockSmithPro VX.X.X - Edition Name.zip`

Examples:
- `LockSmithPro V1.0.0 - Initial Release.zip`
- `LockSmithPro V1.0.1 - Bug Fix Edition.zip`
- `LockSmithPro V1.1.0 - Feature Update.zip`

## Quick Checklist
- [ ] Update version in Init.lua
- [ ] Update version and notes in .toc file
- [ ] Add changelog entry in CHANGELOG.md
- [ ] Update README.md version badge
- [ ] Create LockSmithPro folder with all required files
- [ ] Create zip archive (use PowerShell command or script)
- [ ] Verify zip contains correct files and folder structure
- [ ] Test the release in-game (extract and load addon)
- [ ] Commit and push to GitHub
- [ ] Upload to CurseForge
- [ ] Verify CurseForge listing looks correct

## Automated Version Update Script

Use the PowerShell or Bash script to automatically update version numbers:

**PowerShell (Windows):**
```powershell
.\update-version.ps1 -NewVersion "1.0.1"
```

**Bash (Mac/Linux):**
```bash
./update-version.sh 1.0.1
```

The script will:
1. Update version in Init.lua
2. Update version in LockSmithPro.toc
3. Update version badge in README.md
4. Add new section to CHANGELOG.md
5. Remind you to update changelog with actual changes

## Testing Before Release
1. Extract the zip file to a test AddOns folder
2. Launch WoW and verify the addon loads without errors
3. Test core functionality:
   - Start/Stop monitoring
   - Advertisement system
   - Notification popups
   - Statistics tracking
   - Settings persistence
4. Check for Lua errors in chat
5. Verify version number displays correctly

## CurseForge Compatibility Settings
When uploading to CurseForge, select these game versions:
- Classic Era (1.15.x)
- TBC Classic (2.5.x)
- Wrath Classic (3.4.x)
- Retail (10.x, 11.x, 12.x)
