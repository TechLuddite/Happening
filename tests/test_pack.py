"""Standalone packaging tests; no game, engine, saves, or private references needed."""

import hashlib
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("happening_pack", ROOT / "scripts/pack.py")
packer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packer)


class PackTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name) / "source"
        for source in packer.FILES:
            path = self.root / source
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes((ROOT / source).read_bytes())
        self.out = Path(self.directory.name) / "dist/Happening.vmz"

    def test_exact_allowlist_and_manifest(self):
        extra = self.root / "mods/Happening/private.log"
        extra.write_text("not public")
        (self.root / "AGENTS.md").write_text("not public")
        (self.root / "mods/Happening/Other.gd").write_text("not approved")
        packer.pack(self.out, self.root)
        with zipfile.ZipFile(self.out) as archive:
            self.assertIsNone(archive.testzip())
            self.assertEqual(set(archive.namelist()), set(packer.FILES.values()))
            for source, target in packer.FILES.items():
                self.assertEqual(archive.read(target), (self.root / source).read_bytes())
            self.assertIn(b'HappeningMain="res://mods/Happening/Main.gd"', archive.read("mod.txt"))
        checksum = self.out.with_name("Happening.vmz.sha256").read_text()
        self.assertEqual(checksum, f"{hashlib.sha256(self.out.read_bytes()).hexdigest()}  Happening.vmz\n")

    def test_build_is_independent_of_source_mtimes_and_permissions(self):
        packer.pack(self.out, self.root)
        first = self.out.read_bytes()
        for source in packer.FILES:
            path = self.root / source
            os.utime(path, (2_000_000_000, 2_000_000_000))
            path.chmod(0o600)
        packer.pack(self.out, self.root)
        self.assertEqual(first, self.out.read_bytes())

    def test_missing_runtime_is_rejected_before_overwriting_output(self):
        packer.pack(self.out, self.root)
        first = self.out.read_bytes()
        (self.root / "mods/Happening/Selection.gd").unlink()
        with self.assertRaises(FileNotFoundError):
            packer.pack(self.out, self.root)
        self.assertEqual(first, self.out.read_bytes())

    def test_symlink_is_rejected(self):
        path = self.root / "mods/Happening/Main.gd"
        path.unlink()
        secret = Path(self.directory.name) / "private.txt"
        secret.write_text("not public")
        path.symlink_to(secret)
        with self.assertRaises(ValueError):
            packer.pack(self.out, self.root)
        self.assertFalse(self.out.exists())

    def test_output_cannot_replace_runtime(self):
        original = (self.root / "mods/Happening/Main.gd").read_bytes()
        with self.assertRaises(ValueError):
            packer.pack(self.root / "mods/Happening/Main.gd", self.root)
        self.assertEqual(original, (self.root / "mods/Happening/Main.gd").read_bytes())

    def test_invalid_version_or_autoload_is_rejected(self):
        path = self.root / "mod.txt"
        original = path.read_text()
        for broken in [original.replace(f'version="{packer.version(self.root)}"', 'version="bad"'),
                       original.replace("res://mods/Happening/Main.gd", "res://Scripts/Main.gd")]:
            path.write_text(broken)
            with self.assertRaises(ValueError):
                packer.pack(self.out, self.root)
            self.assertFalse(self.out.exists())

    def test_release_notes_extract_only_current_version(self):
        current = packer.version(self.root)
        (self.root / "CHANGELOG.md").write_text(
            f"# Changelog\n\n## {current}\n\n- Current release.\n\n### Details\n\nMore detail.\n\n"
            "## 999.0.0\n\nOther release.\n"
        )
        self.assertEqual(packer.release_notes(self.root), "- Current release.\n\n### Details\n\nMore detail.\n")

    def test_release_notes_reject_missing_duplicate_or_empty_section(self):
        current = packer.version(self.root)
        for text in ["# Changelog\n", f"## {current}\n\n", f"## {current}\n\nA\n\n## {current}\n\nB\n"]:
            (self.root / "CHANGELOG.md").write_text(text)
            with self.assertRaises(ValueError):
                packer.release_notes(self.root)


if __name__ == "__main__":
    unittest.main()
