# Release Checklist

Use this checklist for each CurseForge release.

## Pre-Release

- Confirm working tree is clean (`git status`).
- Update version values:
  - `Init.lua` (`addonVersion`)
  - `LockSmithPro.toc` (`## Version`)
  - `README.md` version badge/current version
  - `CHANGELOG.md` top section
- Verify `.pkgmeta` includes:
  - `manual-changelog: CHANGELOG.md`
  - `markup-type: markdown`

## Publish

- Commit release changes.
- Push branch.
- Push release tag:

```powershell
.\.build\push-release-tag.ps1 -Version "X.Y.Z" -Channel release
```

## Verify

- Confirm tag exists on GitHub.
- Confirm CurseForge created a new file.
- Check CurseForge changelog formatting and release type.
- Smoke test in-game (`/reload`, start/stop, ad send, stats update).
