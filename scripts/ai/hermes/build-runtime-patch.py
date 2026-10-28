#!/usr/bin/env python3
import difflib
import hashlib
import json
import sys
from pathlib import Path

original_root, patched_root = map(Path, sys.argv[1:3])
expected = {
    "src/store/db.ts": "c1564d454b31af43d3ca1b26a258d17642050a2e8b83910737bdcc348f24d11b",
    "src/index.ts": "2b057356d63b23fa81a5b0454e3a9525f0d292cdc116bb6c2b8eb680e5d69703",
}
files = []
for relative, expected_hash in expected.items():
    original = (original_root / relative).read_bytes()
    patched = (patched_root / relative).read_bytes()
    original_hash = hashlib.sha256(original).hexdigest()
    if original_hash != expected_hash:
        raise SystemExit(f"Expected the unmodified npm pi-hermes-memory 0.9.11 {relative}")
    before = original.decode().splitlines(keepends=True)
    after = patched.decode().splitlines(keepends=True)
    offsets = [0]
    for line in before:
        offsets.append(offsets[-1] + len(line.encode("utf-16-le")) // 2)
    edits = [
        {"start": offsets[i], "oldText": "".join(before[i:end_i]), "newText": "".join(after[j:end_j])}
        for tag, i, end_i, j, end_j in difflib.SequenceMatcher(None, before, after).get_opcodes()
        if tag != "equal"
    ]
    files.append({
        "path": relative,
        "originalSha256": original_hash,
        "patchedSha256": hashlib.sha256(patched).hexdigest(),
        "edits": edits,
    })
specification = {
    "name": "pi-hermes-memory",
    "version": "0.9.11",
    "sourceRevision": "71cf5ab7d909318a383bf52bb3ad3cf83a9efc03",
    "files": files,
}
destination = Path(__file__).resolve().parents[3] / "user/apps/ai/patches/pi-hermes-0.9.11-runtime.json"
destination.write_text(json.dumps(specification, ensure_ascii=True, indent=2) + "\n")
print(f"Generated {destination.name}: {sum(len(file['edits']) for file in files)} edits")
