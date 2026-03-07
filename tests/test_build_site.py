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


class ProjectLinksParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.in_project_nav = False
        self.current_href = None
        self.current_text = []
        self.links = []

    def handle_starttag(self, tag: str, attrs) -> None:
        attrs_dict = dict(attrs)
        if tag == "nav" and attrs_dict.get("aria-label") == "Project links":
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
        elif tag == "nav" and self.in_project_nav:
            self.in_project_nav = False


class BuildSiteRegressionTests(unittest.TestCase):
    def test_build_keeps_header_project_links(self) -> None:
        subprocess.run(["python3", str(BUILD_SCRIPT)], cwd=REPO_ROOT, check=True)

        parser = ProjectLinksParser()
        parser.feed(SITE_INDEX.read_text(encoding="utf-8"))
        self.assertEqual(parser.links, EXPECTED_LINKS)

    def test_build_keeps_header_link_styles(self) -> None:
        subprocess.run(["python3", str(BUILD_SCRIPT)], cwd=REPO_ROOT, check=True)

        style = SITE_STYLE.read_text(encoding="utf-8")
        self.assertIn(".header-links {", style)
        self.assertIn(".header-link {", style)


if __name__ == "__main__":
    unittest.main()
