import tempfile
import unittest
from pathlib import Path

from asset_ledger import audit, digest, resolve


class AssetLedgerTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        data = self.root / "art.txt"
        data.write_text("fixture", encoding="utf-8")
        self.entry = {"path": "art.txt", "origin": "original", "license": "CC0-1.0", "sha256": digest(data)}

    def test_verifies_then_detects_edit(self):
        self.assertEqual(audit(self.root, {"assets": [self.entry]})["verified"], 1)
        (self.root / "art.txt").write_text("modified", encoding="utf-8")
        self.assertIn("checksum mismatch", audit(self.root, {"assets": [self.entry]})["problems"][0]["error"])

    def test_requires_notice(self):
        entry = dict(self.entry, origin="https://example.org")
        self.assertIn("notice file", audit(self.root, {"assets": [entry]})["problems"][0]["error"])
        (self.root / "NOTICE").write_text("Attribution fixture", encoding="utf-8")
        self.assertEqual(audit(self.root, {"assets": [dict(entry, notice="NOTICE")]})["verified"], 1)

    def test_case_collision(self):
        duplicate = dict(self.entry, path="ART.TXT")
        self.assertIn("duplicate", audit(self.root, {"assets": [self.entry, duplicate]})["problems"][0]["error"])

    def test_paths_cannot_escape(self):
        for path in ["../a", "/etc/config", "C:/file", "assets/../a", "a\\b", "a//b", "./a"]:
            with self.assertRaises(ValueError):
                resolve(self.root.resolve(), path)
