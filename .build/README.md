# Build & Release Tools

This folder contains scripts and documentation for creating releases of LockSmithPro.

## Files

### Development Scripts
- **create-symlink.ps1** - Create symbolic links from GitHub folder to WoW AddOns folders for live development
- **remove-symlink.ps1** - Remove symbolic links when done developing

### Release Scripts
- **create-release.ps1** - Automated PowerShell script to create release archives
- **update-version.ps1** - PowerShell script to update version numbers across all files
- **update-version.sh** - Bash script to update version numbers (Mac/Linux)

### Documentation
- **QUICK_RELEASE_GUIDE.md** - Fast reference guide for creating releases
- **RELEASE_PROCESS.md** - Comprehensive release documentation with step-by-step instructions

## Quick Usage

### Development Setup (Live Testing)

**Create symlinks for instant development** - Edit files in GitHub folder, see changes immediately in WoW:

```powershell
# Run as Administrator
.\.build\create-symlink.ps1
```

This automatically detects all WoW installations and creates symlinks:
- Retail (_retail_)
- Classic Era (_classic_era_)
- Wrath/Cata Classic (_classic_)
- Anniversary (_anniversary_)

After running this, any changes you make in your GitHub folder will instantly appear in WoW. Just type `/reload` in-game to see changes.

**Remove symlinks when done**:
```powershell
# Run as Administrator
.\.build\remove-symlink.ps1
```

You can also manually specify a WoW path:
```powershell
.\.build\create-symlink.ps1 -WowPath "D:\Games\World of Warcraft"
```

### Create a Release
```powershell
.\.build\create-release.ps1 -Version "1.0.1" -EditionName "Bug Fix Edition"
```

### Update Version Numbers
```powershell
.\.build\update-version.ps1 -NewVersion "1.0.1"
```

## What Gets Included in Releases

### ✅ Included
- All .lua files (Init.lua, SlashCommands.lua)
- All folders: Core/, Data/, Features/, UI/, logo/
- LockSmithPro.toc file

### ❌ Excluded (Development Files)
- .git/, .claude/, .build/, versions/
- README.md, CHANGELOG.md, Curseforge_Description.mkd
- All scripts (.ps1, .sh)
- Documentation files

## Release Workflow

1. Run create-release.ps1 to package the addon
2. Test the zip file in WoW
3. Upload to CurseForge
4. Commit and push to GitHub

See QUICK_RELEASE_GUIDE.md for detailed instructions.
