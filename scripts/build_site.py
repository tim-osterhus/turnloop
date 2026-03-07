#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
HISTORYLOG = REPO_ROOT / "agents" / "historylog.md"
OUT_DIR = REPO_ROOT / "site"
DATA_JSON = OUT_DIR / "data.json"
INDEX_HTML = OUT_DIR / "index.html"
STYLE_CSS = OUT_DIR / "style.css"

HEADER_RE = re.compile(
    r"^\[(?P<stamp>\d{4}-\d{2}-\d{2}(?: \d{2}:\d{2}(?::\d{2})?)?)\]\s+(?P<role>[^•]+)•\s+(?P<title>.*)$"
)
FIELD_RE = re.compile(r"^\s*-?\s*([A-Za-z ][A-Za-z ]+):\s*(.*)$")

ROLE_TO_ENTRYPOINT = {
    "Reset": "_baseline",
    "Researcher": "_research",
    "Manager": "_manage",
    "Mechanic": "_mechanic",
    "Builder": "_start",
    "QA": "_check",
    "Troubleshooter": "_troubleshoot",
    "Update": "_update",
    "Updater": "_update",
    "Checker": "_check",
}

ROLE_TO_LOOP = {
    "Reset": "Baseline",
    "Researcher": "Research",
    "Manager": "Research",
    "Mechanic": "Research",
    "Builder": "Orchestrate",
    "QA": "Orchestrate",
    "Troubleshooter": "Orchestrate",
    "Update": "Orchestrate",
    "Updater": "Orchestrate",
    "Checker": "Orchestrate",
}

HEADER_LINKS = [
    ("Harness", "https://github.com/tim-osterhus/turnloop"),
    ("Project", "https://github.com/tim-osterhus/corebound"),
    ("Game", "https://game.millrace.ai"),
    ("Updates", "https://millrace.ai/#waitlist"),
]

TIMESTAMP_FORMATS = (
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%d %H:%M",
    "%Y-%m-%d",
)


def parse_timestamp(raw_stamp: str) -> tuple[datetime, bool]:
    for fmt in TIMESTAMP_FORMATS:
        try:
            parsed = datetime.strptime(raw_stamp, fmt)
            return parsed, "%H" in fmt
        except ValueError:
            continue
    raise ValueError(f"Unsupported timestamp format: {raw_stamp}")


def sort_entries(entries: list[dict]) -> list[dict]:
    return sorted(entries, key=lambda entry: entry["sort_key"], reverse=True)


def parse_historylog(text: str) -> list[dict]:
    entries: list[dict] = []
    current = None
    body_lines: list[str] = []

    def flush() -> None:
        nonlocal current, body_lines
        if not current:
            return
        summary = ""
        fields = {}
        for line in body_lines:
            match = FIELD_RE.match(line)
            if not match:
                continue
            key = match.group(1).strip()
            value = match.group(2).strip()
            fields[key] = value
            if key.lower() == "summary" and not summary:
                summary = value
        current["summary"] = summary
        current["fields"] = fields
        entries.append(current)
        current = None
        body_lines = []

    for line in text.splitlines():
        match = HEADER_RE.match(line)
        if match:
            flush()
            stamp = match.group("stamp")
            role = match.group("role").strip()
            title = match.group("title").strip()
            parsed_stamp, has_time = parse_timestamp(stamp)
            current = {
                "timestamp": stamp,
                "date": parsed_stamp.strftime("%Y-%m-%d"),
                "time": parsed_stamp.strftime("%H:%M:%S") if has_time else "",
                "day_key": parsed_stamp.strftime("%Y-%m-%d"),
                "sort_key": parsed_stamp.strftime("%Y-%m-%dT%H:%M:%S"),
                "has_time": has_time,
                "role": role,
                "title": title,
                "entrypoint": ROLE_TO_ENTRYPOINT.get(role, "unknown"),
                "loop": ROLE_TO_LOOP.get(role, "Unknown"),
            }
            continue
        if current is not None:
            body_lines.append(line)
    flush()
    return sort_entries(entries)


def write_style() -> None:
    STYLE_CSS.write_text(
        """
:root {
  --bg: #080b11;
  --bg-elevated: rgba(15, 20, 31, 0.82);
  --bg-panel: rgba(12, 17, 27, 0.96);
  --border: rgba(255, 255, 255, 0.08);
  --border-strong: rgba(255, 255, 255, 0.16);
  --text: #edf2fb;
  --text-muted: #97a4bb;
  --text-dim: #6e7a8d;
  --accent: #ff5b3d;
  --accent-soft: #ff8a6d;
  --accent-glow: rgba(255, 91, 61, 0.16);
  --mint: #83e2bf;
  --shadow: 0 18px 48px rgba(0, 0, 0, 0.26);
}

*,
*::before,
*::after {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  margin: 0;
  min-height: 100vh;
  color: var(--text);
  font-family: "DM Sans", sans-serif;
  line-height: 1.6;
  background:
    radial-gradient(circle at top, rgba(255, 91, 61, 0.12), transparent 34%),
    linear-gradient(180deg, #0b0f16 0%, #080b11 54%, #07090f 100%);
}

a {
  color: inherit;
}

code {
  padding: 0.12rem 0.4rem;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.04);
  font-family: "JetBrains Mono", monospace;
  font-size: 0.88em;
}

.shell {
  width: min(1080px, calc(100vw - 32px));
  margin: 0 auto;
  padding: 20px 0 72px;
}

.topbar {
  position: sticky;
  top: 0;
  z-index: 20;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 0 18px;
  margin-bottom: 10px;
  backdrop-filter: blur(16px);
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
}

.brand-kicker {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: 999px;
  border: 1px solid var(--border-strong);
  background: linear-gradient(180deg, rgba(255, 91, 61, 0.2), rgba(255, 91, 61, 0.05));
  color: var(--accent-soft);
  font-family: "JetBrains Mono", monospace;
  font-size: 0.82rem;
  letter-spacing: 0.08em;
}

.brand-copy {
  display: grid;
  gap: 2px;
}

.brand-name {
  font-family: "Clash Display", sans-serif;
  font-size: 1rem;
  letter-spacing: 0.02em;
}

.brand-tag {
  color: var(--text-dim);
  font-size: 0.74rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.nav-links {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.nav-link {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.7rem 0.95rem;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.03);
  text-decoration: none;
  color: var(--text-muted);
  font-size: 0.82rem;
  font-weight: 600;
}

.nav-link:hover,
.nav-link:focus-visible {
  border-color: var(--accent-soft);
  color: var(--text);
  outline: none;
}

.hero {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(280px, 0.9fr);
  gap: 24px;
  align-items: end;
  margin-bottom: 24px;
}

.hero-panel,
.hero-summary,
.controls-panel,
.day-group,
.empty-state {
  border: 1px solid var(--border);
  border-radius: 24px;
  background: var(--bg-elevated);
  box-shadow: var(--shadow);
}

.hero-panel {
  padding: 30px;
}

.hero-eyebrow {
  margin: 0 0 14px;
  color: var(--accent-soft);
  font-size: 0.8rem;
  font-weight: 700;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.hero-title {
  margin: 0;
  font-family: "Clash Display", sans-serif;
  font-size: clamp(2.8rem, 7vw, 5rem);
  line-height: 0.94;
  letter-spacing: -0.04em;
}

.hero-title-accent {
  color: var(--accent-soft);
}

.hero-copy {
  max-width: 52ch;
  margin: 16px 0 0;
  color: var(--text-muted);
  font-size: 1rem;
}

.hero-summary {
  padding: 24px;
}

.summary-label {
  margin: 0;
  color: var(--text-dim);
  font-size: 0.76rem;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.summary-grid {
  display: grid;
  gap: 12px;
  margin-top: 16px;
}

.summary-stat {
  display: grid;
  gap: 4px;
  padding: 14px 16px;
  border: 1px solid var(--border);
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.02);
}

.summary-stat-value {
  font-family: "Clash Display", sans-serif;
  font-size: 1.5rem;
  line-height: 1;
}

.summary-stat-note {
  color: var(--text-muted);
  font-size: 0.84rem;
}

.controls-panel {
  padding: 18px;
  margin-bottom: 24px;
}

.controls-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 14px;
}

.controls-title {
  margin: 0;
  font-family: "Clash Display", sans-serif;
  font-size: 1.15rem;
}

.controls-subtitle {
  margin: 4px 0 0;
  color: var(--text-dim);
  font-size: 0.82rem;
}

.filter-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
}

.control {
  display: grid;
  gap: 8px;
}

.control-label {
  color: var(--text-dim);
  font-size: 0.74rem;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

select,
button {
  appearance: none;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--bg-panel);
  color: var(--text);
  font: inherit;
}

select {
  padding: 0.8rem 0.95rem;
}

.toggle-row {
  display: flex;
  gap: 8px;
}

.toggle-button {
  flex: 1;
  padding: 0.8rem 0.95rem;
  cursor: pointer;
}

.toggle-button.active {
  border-color: rgba(255, 91, 61, 0.55);
  background: linear-gradient(180deg, rgba(255, 91, 61, 0.16), rgba(255, 91, 61, 0.06));
  color: var(--accent-soft);
}

.timeline-shell {
  display: grid;
  gap: 18px;
}

.day-group {
  overflow: hidden;
}

.day-header {
  display: flex;
  align-items: end;
  justify-content: space-between;
  gap: 16px;
  padding: 20px 22px;
  border-bottom: 1px solid var(--border);
  background: linear-gradient(180deg, rgba(255, 91, 61, 0.08), rgba(255, 91, 61, 0.02));
}

.day-header-copy {
  display: grid;
  gap: 4px;
}

.day-label {
  color: var(--accent-soft);
  font-size: 0.76rem;
  font-weight: 700;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.day-title {
  margin: 0;
  font-family: "Clash Display", sans-serif;
  font-size: 1.45rem;
  line-height: 1;
}

.day-note {
  color: var(--text-muted);
  font-size: 0.84rem;
}

.day-entry-count {
  color: var(--mint);
  font-size: 0.82rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.day-entries {
  display: grid;
}

.entry-card {
  display: grid;
  grid-template-columns: 120px minmax(0, 1fr);
  gap: 18px;
  padding: 18px 22px;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
}

.entry-card:first-child {
  border-top: 0;
}

.entry-timeblock {
  display: grid;
  align-content: start;
  gap: 10px;
}

.entry-time {
  display: inline-flex;
  align-items: center;
  width: fit-content;
  padding: 0.4rem 0.65rem;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.04);
  color: var(--mint);
  font-family: "JetBrains Mono", monospace;
  font-size: 0.77rem;
}

.entry-index {
  color: var(--text-dim);
  font-size: 0.78rem;
}

.entry-main {
  min-width: 0;
}

.entry-head {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px 12px;
  margin-bottom: 8px;
}

.entry-role {
  color: var(--accent-soft);
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.entry-title {
  margin: 0;
  font-size: 1.05rem;
  line-height: 1.35;
}

.entry-summary {
  margin: 0;
  color: var(--text-muted);
  font-size: 0.95rem;
}

.entry-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 12px;
}

.meta-pill {
  display: inline-flex;
  align-items: center;
  padding: 0.34rem 0.62rem;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 999px;
  color: var(--text-dim);
  font-size: 0.74rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.empty-state {
  padding: 28px;
  text-align: center;
  color: var(--text-muted);
}

.footer {
  margin-top: 22px;
  color: var(--text-dim);
  font-size: 0.82rem;
  text-align: center;
}

@media (max-width: 920px) {
  .hero {
    grid-template-columns: 1fr;
  }

  .filter-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .entry-card {
    grid-template-columns: 1fr;
    gap: 12px;
  }

  .entry-timeblock {
    grid-auto-flow: column;
    justify-content: space-between;
    align-items: center;
  }
}

@media (max-width: 720px) {
  .shell {
    width: min(100vw - 20px, 1080px);
  }

  .topbar {
    position: static;
    flex-direction: column;
    align-items: stretch;
  }

  .nav-links {
    justify-content: flex-start;
  }

  .hero-panel,
  .hero-summary,
  .controls-panel,
  .day-group,
  .empty-state {
    border-radius: 20px;
  }

  .hero-panel {
    padding: 24px;
  }

  .filter-grid {
    grid-template-columns: 1fr;
  }

  .controls-header,
  .day-header {
    flex-direction: column;
    align-items: flex-start;
  }
}
""".strip()
        + "\n",
        encoding="utf-8",
    )


def write_index() -> None:
    header_links = "\n".join(
        f'        <a class="nav-link" href="{href}" target="_blank" rel="noreferrer">{label}</a>'
        for label, href in HEADER_LINKS
    )
    index_html = """<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
  <title>Turnloop Journal</title>
  <link rel=\"icon\" type=\"image/png\" href=\"MillraceIconTransparent.png\">
  <link rel=\"shortcut icon\" type=\"image/png\" href=\"MillraceIconTransparent.png\">
  <link rel=\"apple-touch-icon\" href=\"MillraceIconTransparent.png\">
  <link href=\"https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap\" rel=\"stylesheet\">
  <link href=\"https://api.fontshare.com/v2/css?f[]=clash-display@600,700&display=swap\" rel=\"stylesheet\">
  <link rel=\"stylesheet\" href=\"style.css\" />
</head>
<body>
  <main class=\"shell\">
    <nav class=\"topbar\" aria-label=\"Primary\">
      <a class=\"brand\" href=\"#top\">
        <span class=\"brand-kicker\">MR</span>
        <span class=\"brand-copy\">
          <span class=\"brand-name\">Turnloop Journal</span>
          <span class=\"brand-tag\">lite.millrace.ai</span>
        </span>
      </a>
      <div class=\"nav-links\" aria-label=\"Project links\">
__HEADER_LINKS__
      </div>
    </nav>

    <section class=\"hero\" id=\"top\">
      <div class=\"hero-panel\">
        <p class=\"hero-eyebrow\">Millrace / Turnloop</p>
        <h1 class=\"hero-title\">Clean loops.<br><span class=\"hero-title-accent\">Visible progress.</span></h1>
        <p class=\"hero-copy\">A public journal generated from <code>agents/historylog.md</code>. Entries are grouped by day, sorted chronologically, and trimmed to the essential summary so the timeline stays readable.</p>
      </div>
      <aside class=\"hero-summary\">
        <p class=\"summary-label\">Journal Overview</p>
        <div class=\"summary-grid\">
          <div class=\"summary-stat\">
            <span class=\"summary-stat-value\" id=\"daysCount\">0</span>
            <span class=\"summary-stat-note\">active journal days</span>
          </div>
          <div class=\"summary-stat\">
            <span class=\"summary-stat-value\" id=\"entriesCount\">0</span>
            <span class=\"summary-stat-note\">logged entries</span>
          </div>
          <div class=\"summary-stat\">
            <span class=\"summary-stat-value\" id=\"latestStamp\">None</span>
            <span class=\"summary-stat-note\">latest visible timestamp</span>
          </div>
        </div>
      </aside>
    </section>

    <section class=\"controls-panel\" aria-label=\"Filters\">
      <div class=\"controls-header\">
        <div>
          <h2 class=\"controls-title\">Filter timeline</h2>
          <p class=\"controls-subtitle\">Narrow the view without losing the day-grouped layout.</p>
        </div>
      </div>
      <div class=\"filter-grid\">
        <div class=\"control\">
          <label class=\"control-label\" for=\"loopFilter\">Loop</label>
          <select id=\"loopFilter\">
            <option value=\"all\">All</option>
          </select>
        </div>
        <div class=\"control\">
          <label class=\"control-label\" for=\"roleFilter\">Role</label>
          <select id=\"roleFilter\">
            <option value=\"all\">All</option>
          </select>
        </div>
        <div class=\"control\">
          <label class=\"control-label\" for=\"entrypointFilter\">Entrypoint</label>
          <select id=\"entrypointFilter\">
            <option value=\"all\">All</option>
          </select>
        </div>
        <div class=\"control\">
          <span class=\"control-label\">Ordering</span>
          <div class=\"toggle-row\">
            <button id=\"dayLatest\" class=\"toggle-button active\" type=\"button\">Newest first</button>
            <button id=\"dayOldest\" class=\"toggle-button\" type=\"button\">Oldest first</button>
          </div>
        </div>
      </div>
    </section>

    <section class=\"timeline-shell\" id=\"entries\" aria-live=\"polite\"></section>

    <div class=\"footer\" id=\"footer\"></div>
  </main>

  <script>
  const state = {
    loop: 'all',
    role: 'all',
    entrypoint: 'all',
    dayDirection: 'latest'
  };

  const roleFilter = document.getElementById('roleFilter');
  const entrypointFilter = document.getElementById('entrypointFilter');
  const loopFilter = document.getElementById('loopFilter');
  const entriesEl = document.getElementById('entries');
  const footerEl = document.getElementById('footer');
  const daysCountEl = document.getElementById('daysCount');
  const entriesCountEl = document.getElementById('entriesCount');
  const latestStampEl = document.getElementById('latestStamp');

  const btnLatest = document.getElementById('dayLatest');
  const btnOldest = document.getElementById('dayOldest');

  function uniq(values) {
    return Array.from(new Set(values)).sort();
  }

  function setButtonState() {
    btnLatest.classList.toggle('active', state.dayDirection === 'latest');
    btnOldest.classList.toggle('active', state.dayDirection === 'oldest');
  }

  function buildOptions(select, values) {
    const current = select.value;
    select.innerHTML = '<option value="all">All</option>';
    values.forEach((value) => {
      const option = document.createElement('option');
      option.value = value;
      option.textContent = value;
      select.appendChild(option);
    });
    if (values.includes(current)) {
      select.value = current;
    }
  }

  function buildDayMap(entries) {
    const dayKeys = [];
    entries.forEach((entry) => {
      if (!dayKeys.includes(entry.day_key)) {
        dayKeys.push(entry.day_key);
      }
    });
    const map = new Map();
    dayKeys.forEach((dayKey, index) => {
      map.set(dayKey, index + 1);
    });
    return map;
  }

  function groupEntries(entries) {
    const groups = [];
    entries.forEach((entry) => {
      let group = groups.find((candidate) => candidate.dayKey === entry.day_key);
      if (!group) {
        group = {
          dayKey: entry.day_key,
          date: entry.date,
          entries: []
        };
        groups.push(group);
      }
      group.entries.push(entry);
    });
    return groups;
  }

  function render(entries) {
    const dayMap = buildDayMap(entries);
    const groups = groupEntries(entries);

    entriesEl.innerHTML = '';
    entriesCountEl.textContent = String(entries.length);
    daysCountEl.textContent = String(groups.length);
    latestStampEl.textContent = entries.length ? entries[0].timestamp : 'None';

    if (!entries.length) {
      entriesEl.innerHTML = '<div class=\"empty-state\">No entries match the current filters.</div>';
      footerEl.textContent = '0 entries visible';
      return;
    }

    groups.forEach((group) => {
      const section = document.createElement('section');
      section.className = 'day-group';

      const dayNumber = dayMap.get(group.dayKey) || 1;
      const plural = group.entries.length === 1 ? 'entry' : 'entries';
      const entryMarkup = group.entries.map((entry, index) => `
        <article class=\"entry-card\">
          <div class=\"entry-timeblock\">
            <span class=\"entry-time\">${entry.has_time ? entry.time : 'No time'}</span>
            <span class=\"entry-index\">${entry.loop}</span>
          </div>
          <div class=\"entry-main\">
            <div class=\"entry-head\">
              <span class=\"entry-role\">${entry.role}</span>
              <h3 class=\"entry-title\">${entry.title}</h3>
            </div>
            <p class=\"entry-summary\">${entry.summary || 'No summary provided.'}</p>
            <div class=\"entry-meta\">
              <span class=\"meta-pill\">${entry.entrypoint}</span>
              <span class=\"meta-pill\">${entry.timestamp}</span>
              <span class=\"meta-pill\">#${index + 1}</span>
            </div>
          </div>
        </article>
      `).join('');

      section.innerHTML = `
        <div class=\"day-header\">
          <div class=\"day-header-copy\">
            <span class=\"day-label\">Day ${dayNumber}</span>
            <h2 class=\"day-title\">${group.date}</h2>
            <span class=\"day-note\">Grouped by calendar day from timestamped history entries.</span>
          </div>
          <span class=\"day-entry-count\">${group.entries.length} ${plural}</span>
        </div>
        <div class=\"day-entries\">${entryMarkup}</div>
      `;
      entriesEl.appendChild(section);
    });

    footerEl.textContent = `${entries.length} visible entries across ${groups.length} day groups`;
  }

  function applyFilters(allEntries) {
    let entries = allEntries.slice();
    if (state.loop !== 'all') {
      entries = entries.filter((entry) => entry.loop === state.loop);
    }
    if (state.role !== 'all') {
      entries = entries.filter((entry) => entry.role === state.role);
    }
    if (state.entrypoint !== 'all') {
      entries = entries.filter((entry) => entry.entrypoint === state.entrypoint);
    }
    if (state.dayDirection === 'oldest') {
      entries.reverse();
    }
    render(entries);
  }

  fetch('data.json')
    .then((response) => response.json())
    .then((data) => {
      const entries = data.entries || [];
      buildOptions(loopFilter, uniq(entries.map((entry) => entry.loop)));
      buildOptions(roleFilter, uniq(entries.map((entry) => entry.role)));
      buildOptions(entrypointFilter, uniq(entries.map((entry) => entry.entrypoint)));
      applyFilters(entries);

      loopFilter.addEventListener('change', (event) => {
        state.loop = event.target.value;
        applyFilters(entries);
      });
      roleFilter.addEventListener('change', (event) => {
        state.role = event.target.value;
        applyFilters(entries);
      });
      entrypointFilter.addEventListener('change', (event) => {
        state.entrypoint = event.target.value;
        applyFilters(entries);
      });
      btnLatest.addEventListener('click', () => {
        state.dayDirection = 'latest';
        setButtonState();
        applyFilters(entries);
      });
      btnOldest.addEventListener('click', () => {
        state.dayDirection = 'oldest';
        setButtonState();
        applyFilters(entries);
      });
    });
  </script>
</body>
</html>
"""
    INDEX_HTML.write_text(
        index_html.replace("__HEADER_LINKS__", header_links),
        encoding="utf-8",
    )


def build() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if HISTORYLOG.exists():
        entries = parse_historylog(HISTORYLOG.read_text(encoding="utf-8"))
    else:
        entries = []

    payload = {
        "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "entry_count": len(entries),
        "day_count": len({entry["day_key"] for entry in entries}),
        "entries": entries,
    }
    DATA_JSON.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    write_style()
    write_index()


if __name__ == "__main__":
    build()
