"""Tests for gallery_submission.py: python3 -m unittest discover -s tool"""

import base64
import datetime
import json
import tempfile
import unittest
from pathlib import Path

from gallery_submission import SubmissionError, build_submission, read_form

THEME = {
    "format": "materialcraft-theme",
    "version": 1,
    "name": "My theme",
    "style": "neobrutalism.orange",
    "colors": {},
    "globals": {"radius": 8},
    "edits": {},
}


def link(theme=THEME, version="1"):
    data = base64.urlsafe_b64encode(json.dumps(theme).encode()).decode()
    return f"https://materialcraft.danieleorlando.me/?t={version}.{data.rstrip('=')}"


def body(link_value, name="Sunrise", description="Warm and bold.", agree=True):
    return (
        f"### Theme link\n\n{link_value}\n\n"
        f"### Theme name\n\n{name}\n\n"
        f"### Description\n\n{description}\n\n"
        f"### License\n\n- [{'X' if agree else ' '}] I publish this theme "
        "under the MIT license\n"
    )


class GallerySubmissionTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.gallery = Path(self.tmp.name)
        self.now = datetime.datetime(2026, 11, 6, 9, 30, 5, tzinfo=datetime.timezone.utc)

    def tearDown(self):
        self.tmp.cleanup()

    def build(self, text, author="someone"):
        return build_submission(text, author, self.gallery, self.now)

    def test_reads_issue_forms(self):
        form = read_form("### A\n\nx\ny\n\n### B\n\n_No response_\n")
        self.assertEqual(form, {"A": "x\ny", "B": ""})

    def test_valid_submission(self):
        slug, entry = self.build(body(link()))
        self.assertEqual(slug, "sunrise")
        self.assertEqual(entry["name"], "Sunrise")
        self.assertEqual(entry["style"], "neobrutalism.orange")
        self.assertEqual(
            entry["gallery"],
            {"author": "someone", "description": "Warm and bold.",
             "added": "2026-11-06T09:30:05Z"},
        )

    def test_unknown_keys_are_dropped(self):
        _, entry = self.build(body(link({**THEME, "evil": 1, "gallery": {}})))
        self.assertNotIn("evil", entry)
        self.assertEqual(entry["gallery"]["author"], "someone")

    def test_name_falls_back_to_the_theme(self):
        slug, entry = self.build(body(link(), name="_No response_"))
        self.assertEqual((slug, entry["name"]), ("my-theme", "My theme"))

    def test_taken_slug_gets_a_suffix(self):
        (self.gallery / "sunrise.materialcraft.json").write_text(
            json.dumps({**THEME, "name": "Sun rise"}))
        slug, _ = self.build(body(link()))
        self.assertEqual(slug, "sunrise-2")

    def test_rejections(self):
        (self.gallery / "taken.materialcraft.json").write_text(
            json.dumps({**THEME, "name": "Taken"}))
        cases = {
            "no link": body("just text"),
            "broken": body(link()[:-30]),
            "newer": body(link(version="2")),
            "not a theme": body(link({"hello": 1})),
            "license": body(link(), agree=False),
            "long name": body(link(), name="x" * 41),
            "symbols": body(link(), name="!!!"),
            "taken": body(link(), name="taken"),
            "no description": body(link(), description="_No response_"),
            "long description": body(link(), description="x" * 121),
        }
        for label, text in cases.items():
            with self.subTest(label):
                with self.assertRaises(SubmissionError):
                    self.build(text)
        with self.assertRaises(SubmissionError):
            self.build(body(link()), author="not a login")


if __name__ == "__main__":
    unittest.main()
