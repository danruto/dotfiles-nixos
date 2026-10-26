#!/usr/bin/env python3
import difflib
import hashlib
import json
import sys
from pathlib import Path

original = Path(sys.argv[1]).read_bytes()
patched = Path(sys.argv[2]).read_bytes()
original_hash = hashlib.sha256(original).hexdigest()
expected = "25e799830fc1f2a1ea8e23472ea5784af3f62ab3f01eea056b5e13e67e8cff6d"
if original_hash != expected:
    raise SystemExit("Expected the unmodified npm pi-lens 4.4.5 bundle")

before = original.decode("utf-8").splitlines(keepends=True)
after = patched.decode("utf-8").splitlines(keepends=True)
offsets = [0]
for line in before:
    offsets.append(offsets[-1] + len(line.encode("utf-16-le")) // 2)
edits = []
for tag, i, end_i, j, end_j in difflib.SequenceMatcher(None, before, after).get_opcodes():
    if tag != "equal":
        edits.append({
            "start": offsets[i],
            "oldText": "".join(before[i:end_i]),
            "newText": "".join(after[j:end_j]),
        })

spec = {
    "version": "4.4.5",
    "sourceRevision": "3778663223c70ccabb11c352840817bb8fb9fb4e",
    "originalSha256": original_hash,
    "patchedSha256": hashlib.sha256(patched).hexdigest(),
    "edits": edits,
}
root = Path(__file__).resolve().parents[1]
destination = root / "user/apps/ai/patches/pi-lens-4.4.5-runtime.json"
destination.write_text(json.dumps(spec, ensure_ascii=True, indent=2) + "\n")
print(f"Generated {destination.name}: {len(edits)} edits")
