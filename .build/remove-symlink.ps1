param(
    [Parameter(Mandatory=$false)]
    [string]$WowPath = "C:\Program Files (x86)\World of Warcraft"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LockSmithPro - Symlink Remover" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$AddonName = "LockSmithPro"

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

$removed = 0

foreach ($version in $wowVersions) {
    $addonsPath = Join-Path $WowPath "$($version.Path)\Interface\AddOns"
    $targetPath = Join-Path $addonsPath $AddonName

    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Host "[$($version.Name)] Removing symlink..." -ForegroundColor Yellow
            Remove-Item $targetPath -Force
            Write-Host "[$($version.Name)] Symlink removed!" -ForegroundColor Green
            $removed++
        } else {
            Write-Host "[$($version.Name)] Not a symlink (regular folder) - skipping" -ForegroundColor Gray
        }
    } else {
        Write-Host "[$($version.Name)] Not found - skipping" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Removed $removed symlink(s)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
