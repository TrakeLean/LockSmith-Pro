#!/bin/bash
# Version update script - automatically updates all version references

if [ -z "$1" ]; then
    echo "Usage: ./update-version.sh <new-version>"
    echo "Example: ./update-version.sh 1.0.1"
    exit 1
fi

NEW_VERSION="$1"
echo "Updating to version $NEW_VERSION..."

# Update Init.lua
sed -i "s/local addonVersion = \"[^\"]*\"/local addonVersion = \"$NEW_VERSION\"/" Init.lua

# Update LockSmithPro.toc
sed -i "s/## Version: [0-9.]*/## Version: $NEW_VERSION/" LockSmithPro.toc

# Update README.md
sed -i "s/Version-[0-9.]*-brightgreen/Version-$NEW_VERSION-brightgreen/" README.md

# Update CHANGELOG.md (add new section at top)
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << EOF
# LockSmithPro - Changelog

## Version $NEW_VERSION - Edition Name

### New Features
- [Add your changes here]

### Bug Fixes
- [Add your changes here]

### Changes
- [Add your changes here]

---

EOF

# Append existing changelog (skip first line)
tail -n +2 CHANGELOG.md >> "$TEMP_FILE"
mv "$TEMP_FILE" CHANGELOG.md

echo "Version updated to $NEW_VERSION in all files!"
echo ""
echo "Don't forget to:"
echo "1. Update CHANGELOG.md with actual changes and edition name"
echo "2. Test the addon in-game"
echo "3. Create release archive (see RELEASE_PROCESS.md)"
echo "4. Commit and push: git add . && git commit -m 'Version $NEW_VERSION - Edition Name' && git push"
echo "5. Upload to CurseForge"
