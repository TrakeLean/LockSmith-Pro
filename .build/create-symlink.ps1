param(
    [Parameter(Mandatory=$false)]
    [string]$WowPath = "C:\Program Files (x86)\World of Warcraft"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LockSmithPro - Symlink Creator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$SourcePath = Split-Path -Parent $PSScriptRoot
$AddonName = "LockSmithPro"

Write-Host "Source: $SourcePath" -ForegroundColor Yellow
Write-Host "WoW Path: $WowPath" -ForegroundColor Yellow
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

# WoW version folders to check
$wowVersions = @(
    @{Name="Retail"; Path="_retail_"},
    @{Name="Classic Era"; Path="_classic_era_"},
    @{Name="Wrath/Cata Classic"; Path="_classic_"},
    @{Name="Anniversary"; Path="_anniversary_"},
    @{Name="Classic (old)"; Path="_classic_ptr_"}
)

$created = 0
$skipped = 0

foreach ($version in $wowVersions) {
    $addonsPath = Join-Path $WowPath "$($version.Path)\Interface\AddOns"

    if (Test-Path $addonsPath) {
        $targetPath = Join-Path $addonsPath $AddonName

        # Check if symlink already exists
        if (Test-Path $targetPath) {
            $item = Get-Item $targetPath
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Write-Host "[$($version.Name)] Symlink already exists - skipping" -ForegroundColor Gray
                $skipped++
            } else {
                Write-Host "[$($version.Name)] Regular folder exists - removing and creating symlink..." -ForegroundColor Yellow
                Remove-Item $targetPath -Recurse -Force
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $SourcePath | Out-Null
                Write-Host "[$($version.Name)] Symlink created!" -ForegroundColor Green
                $created++
            }
        } else {
            Write-Host "[$($version.Name)] Creating symlink..." -ForegroundColor Yellow
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $SourcePath | Out-Null
            Write-Host "[$($version.Name)] Symlink created!" -ForegroundColor Green
            $created++
        }
    } else {
        Write-Host "[$($version.Name)] Not found - skipping" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Created: $created symlink(s)" -ForegroundColor Green
Write-Host "Skipped: $skipped symlink(s)" -ForegroundColor Gray
Write-Host ""
Write-Host "You can now edit files in:" -ForegroundColor Cyan
Write-Host "  $SourcePath" -ForegroundColor White
Write-Host ""
Write-Host "Changes will instantly appear in WoW!" -ForegroundColor Cyan
Write-Host "Just use /reload in-game to reload the UI" -ForegroundColor Yellow
Write-Host ""
