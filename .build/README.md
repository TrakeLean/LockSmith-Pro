# Build Tools

This folder only contains tools still used by the current workflow.

## Scripts

- `create-symlink.ps1`: Create symlinks to WoW AddOns folders for live local testing.
- `remove-symlink.ps1`: Remove those symlinks.
- `push-release-tag.ps1`: Create and push a release/beta/alpha tag that triggers CurseForge automatic packaging.

## Quick Usage

### Local Development

```powershell
# Run as Administrator
.\.build\create-symlink.ps1

# Remove symlinks later
.\.build\remove-symlink.ps1
```

### Automatic CurseForge Release

```powershell
# Release
.\.build\push-release-tag.ps1 -Version "1.0.1" -Channel release

# Beta
.\.build\push-release-tag.ps1 -Version "1.1.0" -Channel beta -Iteration 1

# Alpha
.\.build\push-release-tag.ps1 -Version "1.1.0" -Channel alpha -Iteration 1
```

## Webhook

Configure GitHub webhook payload URL once:

`https://www.curseforge.com/api/projects/1443477/package?token=YOUR_TOKEN`

Tag mapping used by CurseForge:
- `vX.Y.Z` => release
- `vX.Y.Z-beta` / `vX.Y.Z-beta.N` => beta
- `vX.Y.Z-alpha` / `vX.Y.Z-alpha.N` => alpha
