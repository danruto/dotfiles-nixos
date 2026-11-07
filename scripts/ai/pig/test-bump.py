import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SOURCE_HASH = "sha256-" + "B" * 43 + "="
VENDOR_HASH = "sha256-" + "C" * 43 + "="
REVISION = "a" * 40

MOCK = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["CALLS"], "a") as log:
    log.write(json.dumps([name, *args]) + "\n")
if name == "gh":
    print(os.environ["RELEASE"] if args[0] == "release" else "a" * 40)
elif name == "nix-prefetch-url":
    print("source-hash")
elif args[:2] == ["hash", "convert"]:
    print("sha256-" + "B" * 43 + "=")
elif args[0] == "build":
    candidate = Path(args[args.index("package") + 1])
    text = candidate.read_text()
    assert 'version = "999.0.0";' in text
    assert 'upstreamRevision = "' + "a" * 40 + '";' in text
    assert 'hash = "sha256-' + "B" * 43 + '=";' in text
    assert list((candidate.parent / "patches").glob("*.patch"))
    mode = os.environ["MODE"]
    if "modulesOnly" in args:
        assert 'vendorHash = "sha256-' + "A" * 43 + '=";' in text
        if mode == "unexpected-success":
            sys.exit(0)
        if mode == "module-failure":
            print("patch or toolchain failed", file=sys.stderr)
        else:
            print("error: hash mismatch in fixed-output derivation", file=sys.stderr)
            print("  got:    sha256-" + "C" * 43 + "=", file=sys.stderr)
            if mode == "ambiguous-hashes":
                print("  got:    sha256-" + "D" * 43 + "=", file=sys.stderr)
        sys.exit(1)
    assert 'vendorHash = "sha256-' + "C" * 43 + '=";' in text
    sys.exit(1 if mode == "build-failure" else 0)
else:
    sys.exit("unexpected command: " + repr(args))
'''


class BumpPigTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for relative in ("scripts/bump", "scripts/ai/pig/package.nix", "user/apps/ai/pi-pig.nix"):
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, target)
        shutil.copytree(ROOT / "user/apps/ai/patches", self.root / "user/apps/ai/patches")
        self.package = self.root / "user/apps/ai/pi-pig.nix"
        self.original = self.package.read_text()
        version_match = re.search(r'  version = "([^"]+)";', self.original)
        assert version_match is not None
        self.current_version = version_match.group(1)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("gh", "nix-prefetch-url", "nix"):
            mock = self.bin / name
            mock.write_text(MOCK)
            mock.chmod(0o755)
        self.calls = self.root / "calls.jsonl"

    def run_bump(self, mode="success", release="v999.0.0"):
        env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}",
                   CALLS=str(self.calls), MODE=mode, RELEASE=release)
        result = subprocess.run(["bash", str(self.root / "scripts/bump"), "pig"],
                                env=env, capture_output=True, text=True, check=False)
        try:
            calls = [json.loads(line) for line in self.calls.read_text().splitlines()]
        except (OSError, json.JSONDecodeError) as error:
            self.fail(f"Invalid mock command log: {error}")
        return result, calls

    def test_already_current(self):
        result, calls = self.run_bump(release=f"v{self.current_version}")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"pig: already {self.current_version}", result.stdout)
        self.assertEqual(len(calls), 1)
        self.assertEqual(self.package.read_text(), self.original)

    def test_updates_only_release_pins_after_checks(self):
        result, calls = self.run_bump()
        self.assertEqual(result.returncode, 0, result.stderr)
        expected = self.original.replace(f'version = "{self.current_version}";', 'version = "999.0.0";')
        expected = re.sub(r'upstreamRevision = "[^"]+";', f'upstreamRevision = "{REVISION}";', expected)
        expected = re.sub(r'(src = fetchurl \{.*?hash = ")[^"]+(";)',
                          rf'\g<1>{SOURCE_HASH}\2', expected, flags=re.DOTALL)
        expected = re.sub(r'vendorHash = "[^"]+";', f'vendorHash = "{VENDOR_HASH}";', expected)
        self.assertEqual(self.package.read_text(), expected)
        builds = [call for call in calls if call[:2] == ["nix", "build"]]
        self.assertEqual(len(builds), 2)
        self.assertIn("modulesOnly", builds[0])
        candidate = Path(builds[0][builds[0].index("package") + 1])
        self.assertFalse(candidate.parent.exists(), "temporary package was not removed")

    def test_failures_leave_package_unchanged(self):
        for mode in ("module-failure", "ambiguous-hashes", "unexpected-success", "build-failure"):
            with self.subTest(mode=mode):
                self.calls.unlink(missing_ok=True)
                result, calls = self.run_bump(mode=mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("pin unchanged", result.stderr)
                self.assertEqual(self.package.read_text(), self.original)
                builds = [call for call in calls if call[:2] == ["nix", "build"]]
                self.assertEqual(len(builds), 2 if mode == "build-failure" else 1)
                candidate = Path(builds[0][builds[0].index("package") + 1])
                self.assertFalse(candidate.parent.exists())


if __name__ == "__main__":
    unittest.main()
