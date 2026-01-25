param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$true)]
    [string]$EditionName
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LockSmithPro Release Creator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$TempFolder = "LockSmithPro"
$ZipName = "LockSmithPro V$Version - $EditionName.zip"
$ZipPath = ".\versions\$ZipName"

# Step 1: Create temp folder
Write-Host "[1/6] Creating temporary folder..." -ForegroundColor Yellow
if (Test-Path $TempFolder) {
    Remove-Item -Recurse -Force $TempFolder
}
New-Item -ItemType Directory -Path $TempFolder | Out-Null

# Step 2: Copy required files
Write-Host "[2/6] Copying addon files..." -ForegroundColor Yellow

# Root Lua files
Copy-Item "Init.lua" -Destination $TempFolder
Copy-Item "SlashCommands.lua" -Destination $TempFolder

# TOC file
Copy-Item "LockSmithPro.toc" -Destination $TempFolder

# Core folder
Write-Host "  - Copying Core folder..." -ForegroundColor Gray
Copy-Item "Core" -Destination $TempFolder -Recurse

# Data folder
Write-Host "  - Copying Data folder..." -ForegroundColor Gray
Copy-Item "Data" -Destination $TempFolder -Recurse

# Features folder
Write-Host "  - Copying Features folder..." -ForegroundColor Gray
Copy-Item "Features" -Destination $TempFolder -Recurse

# UI folder
Write-Host "  - Copying UI folder..." -ForegroundColor Gray
Copy-Item "UI" -Destination $TempFolder -Recurse

# Logo folder
Write-Host "  - Copying logo folder..." -ForegroundColor Gray
Copy-Item "logo" -Destination $TempFolder -Recurse

# Step 3: Verify files
Write-Host "[3/6] Verifying files..." -ForegroundColor Yellow
$requiredFiles = @(
    "$TempFolder\Init.lua",
    "$TempFolder\SlashCommands.lua",
    "$TempFolder\LockSmithPro.toc",
    "$TempFolder\Core\Utils.lua",
    "$TempFolder\Core\Skills.lua",
    "$TempFolder\Core\Statistics.lua",
    "$TempFolder\Data\Database.lua",
    "$TempFolder\Features\Advertisement.lua",
    "$TempFolder\Features\AutoResponse.lua",
    "$TempFolder\Features\ChatMonitor.lua",
    "$TempFolder\UI\Dashboard.lua",
    "$TempFolder\UI\Notification.lua",
    "$TempFolder\UI\Settings.lua",
    "$TempFolder\UI\Minimap.lua"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "  ERROR: Missing file: $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host ""
    Write-Host "ERROR: Some required files are missing!" -ForegroundColor Red
    Remove-Item -Recurse -Force $TempFolder
    exit 1
}

Write-Host "  All required files present!" -ForegroundColor Green

# Step 4: Create versions folder if it doesn't exist
Write-Host "[4/6] Preparing versions folder..." -ForegroundColor Yellow
if (-not (Test-Path "versions")) {
    New-Item -ItemType Directory -Path "versions" | Out-Null
}

# Step 5: Create zip archive
Write-Host "[5/6] Creating zip archive..." -ForegroundColor Yellow
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Compress-Archive -Path $TempFolder -DestinationPath $ZipPath -Force

# Verify zip was created
if (Test-Path $ZipPath) {
    $zipSize = (Get-Item $ZipPath).Length / 1KB
    Write-Host "  Archive created: $ZipName ($([math]::Round($zipSize, 2)) KB)" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Failed to create archive!" -ForegroundColor Red
    Remove-Item -Recurse -Force $TempFolder
    exit 1
}

# Step 6: Cleanup
Write-Host "[6/6] Cleaning up..." -ForegroundColor Yellow
Remove-Item -Recurse -Force $TempFolder
Write-Host "  Temporary folder removed" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Release created successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Archive: $ZipPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test the release by extracting to AddOns folder" -ForegroundColor White
Write-Host "2. Verify addon loads in-game without errors" -ForegroundColor White
Write-Host "3. Upload to CurseForge" -ForegroundColor White
Write-Host "4. Commit and push to GitHub:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m `"Version $Version - $EditionName`"" -ForegroundColor Gray
Write-Host "   git push origin main" -ForegroundColor Gray
Write-Host ""
