import importlib.util
import subprocess
import unittest
from html.parser import HTMLParser
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
BUILD_SCRIPT = REPO_ROOT / "scripts" / "build_site.py"
SITE_INDEX = REPO_ROOT / "site" / "index.html"
SITE_STYLE = REPO_ROOT / "site" / "style.css"

EXPECTED_LINKS = [
    ("Harness", "https://github.com/tim-osterhus/turnloop"),
    ("Project", "https://github.com/tim-osterhus/corebound"),
    ("Game", "https://game.millrace.ai"),
    ("Updates", "https://millrace.ai/#waitlist"),
]


def load_build_site_module():
    spec = importlib.util.spec_from_file_location("build_site", BUILD_SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class ProjectLinksParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.in_project_nav = False
        self.current_href = None
        self.current_text = []
        self.links = []

    def handle_starttag(self, tag: str, attrs) -> None:
        attrs_dict = dict(attrs)
        if tag == "div" and attrs_dict.get("aria-label") == "Project links":
            self.in_project_nav = True
        elif tag == "a" and self.in_project_nav:
            self.current_href = attrs_dict.get("href")
            self.current_text = []

    def handle_data(self, data: str) -> None:
        if self.current_href is not None:
            self.current_text.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag == "a" and self.current_href is not None:
            label = "".join(self.current_text).strip()
            self.links.append((label, self.current_href))
            self.current_href = None
            self.current_text = []
        elif tag == "div" and self.in_project_nav:
            self.in_project_nav = False


class BuildSiteRegressionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.build_site = load_build_site_module()

    def test_parse_historylog_sorts_timestamped_entries_newest_first(self) -> None:
        historylog = """
[2026-03-05 07:30:00] Builder • Earlier
- Summary: Earlier summary

[2026-03-05 09:45:00] QA • Latest
- Summary: Latest summary

[2026-03-04 23:59:59] Researcher • Oldest
- Summary: Oldest summary
""".strip()

        entries = self.build_site.parse_historylog(historylog)

        self.assertEqual(
            [entry["title"] for entry in entries],
            ["Latest", "Earlier", "Oldest"],
        )
        self.assertEqual(entries[0]["timestamp"], "2026-03-05 09:45:00")
        self.assertEqual(entries[0]["time"], "09:45:00")
        self.assertEqual(entries[0]["summary"], "Latest summary")

    def test_parse_historylog_accepts_date_only_headers(self) -> None:
        historylog = """
[2026-03-05] Update • Date Only
- Summary: Date-only headers still parse.
""".strip()

        entries = self.build_site.parse_historylog(historylog)

        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]["date"], "2026-03-05")
        self.assertFalse(entries[0]["has_time"])
        self.assertEqual(entries[0]["time"], "")

    def test_build_keeps_header_project_links(self) -> None:
        subprocess.run(["python3", str(BUILD_SCRIPT)], cwd=REPO_ROOT, check=True)

        parser = ProjectLinksParser()
        parser.feed(SITE_INDEX.read_text(encoding="utf-8"))
        self.assertEqual(parser.links, EXPECTED_LINKS)

    def test_build_outputs_summary_only_timeline_layout(self) -> None:
        subprocess.run(["python3", str(BUILD_SCRIPT)], cwd=REPO_ROOT, check=True)

        index = SITE_INDEX.read_text(encoding="utf-8")
        style = SITE_STYLE.read_text(encoding="utf-8")

        self.assertIn("timeline-shell", index)
        self.assertIn("Grouped by calendar day from timestamped history entries.", index)
        self.assertNotIn("<details", index)
        self.assertIn(".day-group {", style)
        self.assertIn(".entry-card {", style)
        self.assertIn(".hero-title {", style)


if __name__ == "__main__":
    unittest.main()
