# Quick Release Guide

## Creating a New Release (Fast Method)

### Step 1: Create the Release
Run the automated release script:

```powershell
.\create-release.ps1 -Version "1.0.1" -EditionName "Bug Fix Edition"
```

This will:
- Create a temporary LockSmithPro folder
- Copy all required addon files (Lua, TOC, folders)
- Verify all files are present
- Create a zip archive in the `versions/` folder
- Clean up temporary files

### Step 2: Update Version Numbers (Optional)
If you want to update version numbers across all files:

```powershell
.\update-version.ps1 -NewVersion "1.0.1"
```

This updates:
- Init.lua (addonVersion)
- LockSmithPro.toc (Version)
- README.md (version badge)
- CHANGELOG.md (adds new section)

### Step 3: Edit Changelog
Open `CHANGELOG.md` and update the new section with actual changes:
- Replace "Edition Name" with your edition name
- Add your bug fixes, features, and changes
- Remove placeholder text

### Step 4: Test the Release
1. Extract the zip from `versions/` to your WoW AddOns folder
2. Launch WoW and test all features
3. Check for Lua errors
4. Verify version number displays correctly

### Step 5: Commit and Push
```bash
git add .
git commit -m "Version 1.0.1 - Bug Fix Edition"
git push origin main
```

### Step 6: Upload to CurseForge
1. Go to [CurseForge Authors](https://authors.curseforge.com)
2. Select LockSmithPro project
3. Click "Files" → "Upload File"
4. Upload the zip from `versions/` folder
5. Fill in changelog (copy from CHANGELOG.md)
6. Select game versions (Classic Era, TBC, Wrath, Retail)
7. Publish

---

## One-Liner for Experienced Users

```powershell
# Create release
.\create-release.ps1 -Version "1.0.1" -EditionName "Bug Fix Edition"

# Update version numbers (optional, if you want to bump version in code)
.\update-version.ps1 -NewVersion "1.0.1"

# Edit CHANGELOG.md, test, commit, and upload to CurseForge
```

---

## Files Included in Release

### ✅ Included
- `Init.lua`
- `SlashCommands.lua`
- `LockSmithPro.toc`
- `Core/` folder (Utils.lua, Skills.lua, Statistics.lua)
- `Data/` folder (Database.lua)
- `Features/` folder (Advertisement.lua, AutoResponse.lua, ChatMonitor.lua)
- `UI/` folder (Dashboard.lua, Notification.lua, Settings.lua, Minimap.lua)
- `logo/` folder (all texture files)

### ❌ Excluded (Development Files)
- `.git/` and `.gitignore`
- `.claude/`
- `versions/` folder
- `README.md`
- `CHANGELOG.md`
- `RELEASE_PROCESS.md`
- `Curseforge_Description.mkd`
- `*.ps1` and `*.sh` scripts

---

## Troubleshooting

**Script execution blocked?**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Missing files in archive?**
- Check that all Lua files exist in their folders
- Verify folder names match exactly (case-sensitive)
- Re-run the create-release script

**Archive too large?**
- Check if extra files were accidentally included
- Verify only required files are in temp folder

---

## CurseForge Game Version Support

When uploading, select these versions:
- ✅ Classic Era (1.15.x) - Interface: 11505
- ✅ TBC Classic (2.5.x) - Interface: 20505
- ✅ Wrath Classic (3.4.x) - Interface: 30403
- ✅ Cataclysm Classic (4.4.x) - Interface: 40400
- ✅ Retail (11.x) - Interface: 110207
- ✅ Retail (12.x) - Interface: 120000, 120001

---

## Version Naming Convention

Format: `LockSmithPro VX.X.X - Edition Name.zip`

Examples:
- `LockSmithPro V1.0.0 - Initial Release.zip`
- `LockSmithPro V1.0.1 - Bug Fix Edition.zip`
- `LockSmithPro V1.1.0 - Feature Update.zip`
- `LockSmithPro V2.0.0 - Major Overhaul.zip`

Edition Name Ideas:
- Bug Fix Edition
- Stability Update
- Feature Update
- Performance Boost
- UI Redesign
- Major Overhaul
- Hotfix Edition
- Polish Update
