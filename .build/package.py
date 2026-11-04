"""Build a local install ZIP from the runtime manifest; never publish it."""
from pathlib import Path
import re
import zipfile

root = Path(__file__).resolve().parents[1]
manifest = root / "LockSmithPro.toc"
text = manifest.read_text()
version = re.search(r"^## Version: (.+)$", text, re.M).group(1)
runtime = [line.replace("\\", "/") for line in text.splitlines() if line.endswith(".lua")]
files = runtime + [p.name for p in sorted(root.glob("LockSmithPro*.toc"))] + ["logo/logonoText.tga", "CHANGELOG.md"]
for toc in root.glob("LockSmithPro*.toc"):
    entries = [line.replace("\\", "/") for line in toc.read_text().splitlines() if line.endswith(".lua")]
    assert entries == runtime, f"Mismatched load order: {toc.name}"
    assert f"## Version: {version}" in toc.read_text(), f"Mismatched version: {toc.name}"
for name in files:
    assert (root / name).is_file(), f"Missing file: {name}"
output = root / "dist" / f"LockSmithPro-{version}.zip"
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
    for name in files:
        archive.write(root / name, "LockSmithPro/" + name)
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert len(archive.namelist()) == len(set(files))
print(f"Created {output} ({len(files)} files)")
