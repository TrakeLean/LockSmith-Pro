param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^\d+\.\d+\.\d+([.-][0-9A-Za-z.-]+)?$')]
    [string]$Version,

    [ValidateSet("release", "beta", "alpha")]
    [string]$Channel = "release",

    [ValidateRange(1, 999)]
    [int]$Iteration,

    [string]$TagPrefix = "v",

    [switch]$AllowDirty,

    [switch]$SkipBranchPush
)

$ErrorActionPreference = "Stop"

function Assert-LastExitCode {
    param(
        [string]$CommandDescription
    )

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $CommandDescription"
    }
}

if (-not (Test-Path ".git")) {
    throw "Run this script from the repository root."
}

$status = git status --porcelain
Assert-LastExitCode "git status --porcelain"

if (-not $AllowDirty -and $status) {
    throw "Working tree is not clean. Commit or stash changes first, or use -AllowDirty."
}

$branch = git rev-parse --abbrev-ref HEAD
Assert-LastExitCode "git rev-parse --abbrev-ref HEAD"
$branch = "$branch".Trim()

if (-not $branch -or $branch -eq "HEAD") {
    throw "Could not determine current branch (detached HEAD)."
}

$baseTag = "$TagPrefix$Version"
$tagName = $baseTag

if ($Channel -ne "release") {
    $tagName = "$baseTag-$Channel"
    if ($PSBoundParameters.ContainsKey("Iteration")) {
        $tagName = "$tagName.$Iteration"
    }
}

git rev-parse --quiet --verify "refs/tags/$tagName" *> $null
if ($LASTEXITCODE -eq 0) {
    throw "Tag already exists locally: $tagName"
}

$remoteTag = git ls-remote --tags origin "refs/tags/$tagName"
Assert-LastExitCode "git ls-remote --tags origin refs/tags/$tagName"
if ($remoteTag) {
    throw "Tag already exists on origin: $tagName"
}

$tagMessage = "LockSmithPro $Channel $Version"
if ($PSBoundParameters.ContainsKey("Iteration")) {
    $tagMessage = "$tagMessage (iteration $Iteration)"
}

Write-Host "Creating tag: $tagName" -ForegroundColor Cyan
git tag -a $tagName -m $tagMessage
Assert-LastExitCode "git tag -a $tagName -m <message>"

if (-not $SkipBranchPush) {
    Write-Host "Pushing branch: $branch" -ForegroundColor Cyan
    git push origin $branch
    Assert-LastExitCode "git push origin $branch"
}

Write-Host "Pushing tag: $tagName" -ForegroundColor Cyan
git push origin $tagName
Assert-LastExitCode "git push origin $tagName"

Write-Host ""
Write-Host "Done. CurseForge webhook should now package this tag." -ForegroundColor Green
Write-Host "Tag: $tagName (release type: $Channel)" -ForegroundColor Green
