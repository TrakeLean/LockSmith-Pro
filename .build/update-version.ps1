param(
    [Parameter(Mandatory=$true)]
    [string]$NewVersion
)

Write-Host "Updating to version $NewVersion..." -ForegroundColor Green

# Update Init.lua
(Get-Content Init.lua) -replace 'local addonVersion = "[^"]*"', "local addonVersion = `"$NewVersion`"" | Set-Content Init.lua

# Update LockSmithPro.toc
(Get-Content LockSmithPro.toc) -replace '## Version: [0-9.]*', "## Version: $NewVersion" | Set-Content LockSmithPro.toc

# Update README.md
(Get-Content README.md) -replace 'Version-[0-9.]+-brightgreen', "Version-$NewVersion-brightgreen" | Set-Content README.md

# Update CHANGELOG.md (add new section at top)
$newChangelog = @"
# LockSmithPro - Changelog

## Version $NewVersion - Edition Name

### New Features
- [Add your changes here]

### Bug Fixes
- [Add your changes here]

### Changes
- [Add your changes here]

---

"@

$existingChangelog = Get-Content CHANGELOG.md | Select-Object -Skip 1
$newChangelog + ($existingChangelog -join "`n") | Set-Content CHANGELOG.md

Write-Host "Version updated to $NewVersion in all files!" -ForegroundColor Green
Write-Host ""
Write-Host "Don't forget to:" -ForegroundColor Yellow
Write-Host "1. Update CHANGELOG.md with actual changes and edition name" -ForegroundColor Yellow
Write-Host "2. Test the addon in-game" -ForegroundColor Yellow
Write-Host "3. Create release archive: Compress-Archive -Path .\LockSmithPro -DestinationPath .\versions\LockSmithPro` V$NewVersion` -` Edition` Name.zip -Force" -ForegroundColor Yellow
Write-Host "4. Commit and push changes: git add . && git commit -m 'Version $NewVersion - Edition Name' && git push" -ForegroundColor Yellow
Write-Host "5. Upload to CurseForge" -ForegroundColor Yellow
