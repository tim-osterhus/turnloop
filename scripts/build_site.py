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

HEADER_RE = re.compile(r"^\[(\d{4}-\d{2}-\d{2})\]\s+([^•]+)•\s+(.*)$")
FIELD_RE = re.compile(r"^\s*-?\s*([A-Za-z ][A-Za-z ]+):\s*(.*)$")

ROLE_TO_ENTRYPOINT = {
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


def parse_historylog(text: str) -> list[dict]:
    entries: list[dict] = []
    current = None
    body_lines: list[str] = []

    def flush():
        nonlocal current, body_lines
        if not current:
            return
        summary = ""
        fields = {}
        for line in body_lines:
            m = FIELD_RE.match(line)
            if m:
                key = m.group(1).strip()
                val = m.group(2).strip()
                fields[key] = val
                if key.lower() == "summary" and not summary:
                    summary = val
        current["summary"] = summary
        current["fields"] = fields
        current["details"] = "\n".join(body_lines).strip()
        entries.append(current)
        current = None
        body_lines = []

    for line in text.splitlines():
        m = HEADER_RE.match(line)
        if m:
            flush()
            date_str = m.group(1)
            role = m.group(2).strip()
            title = m.group(3).strip()
            current = {
                "date": date_str,
                "role": role,
                "title": title,
                "entrypoint": ROLE_TO_ENTRYPOINT.get(role, "unknown"),
                "loop": ROLE_TO_LOOP.get(role, "Unknown"),
            }
        else:
            if current is not None:
                body_lines.append(line)
    flush()
    return entries


def write_style():
    STYLE_CSS.write_text(
        """
:root {
  --bg: #0a0a0b;
  --surface: #121214;
  --border: #252528;
  --text: #e8e6ed;
  --text-muted: #807e88;
  --accent: #dc2626;
  --accent-soft: #ef4444;
  --accent-dim: rgba(220,38,38,0.08);
  --accent-glow: rgba(220,38,38,0.12);
  --cream: #f0eef5;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: "DM Sans", sans-serif;
  line-height: 1.6;
}
main {
  max-width: 980px;
  margin: 0 auto;
  padding: 32px 20px 64px;
}
header h1 {
  margin: 0 0 8px;
  font-size: 28px;
  letter-spacing: 0.5px;
  font-family: "Clash Display", sans-serif;
}
header p {
  margin: 0 0 24px;
  color: var(--text-muted);
}
.panel {
  background: var(--surface);
  border: 1px solid var(--border);
  padding: 16px;
  border-radius: 10px;
  margin-bottom: 16px;
}
.controls {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}
.control {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 180px;
}
label {
  color: var(--text-muted);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 1px;
}
select, button {
  background: #0f1013;
  color: var(--text);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 8px 10px;
  font-size: 13px;
}
button {
  cursor: pointer;
}
button.active {
  border-color: var(--accent);
  color: var(--accent-soft);
}
.entry {
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 16px;
  background: var(--surface);
}
.entry h3 {
  margin: 0 0 6px;
  font-size: 16px;
  font-family: "Clash Display", sans-serif;
}
.meta {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  color: var(--text-muted);
  font-size: 12px;
}
.badge {
  padding: 2px 8px;
  border: 1px solid var(--border);
  border-radius: 999px;
  font-size: 11px;
  color: var(--accent-soft);
}
.summary {
  margin-top: 10px;
  color: var(--text);
}
.details {
  margin-top: 12px;
}
.details pre {
  margin: 0;
  background: #0b0c0e;
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 12px;
  white-space: pre-wrap;
  color: var(--text-muted);
  font-family: "JetBrains Mono", monospace;
}
.footer {
  margin-top: 32px;
  color: var(--text-muted);
  font-size: 12px;
}
""".strip()
        + "\n",
        encoding="utf-8",
    )


def write_index():
    INDEX_HTML.write_text(
        """<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
  <title>Turnloop Journal</title>
  <link rel=\"icon\" type=\"image/png\" href=\"MillraceIconTransparent.png\">
  <link rel=\"shortcut icon\" type=\"image/png\" href=\"MillraceIconTransparent.png\">
  <link rel=\"apple-touch-icon\" href=\"MillraceIconTransparent.png\">
  <link href=\"https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap\" rel=\"stylesheet\">
  <link href=\"https://api.fontshare.com/v2/css?f[]=clash-display@600,700&display=swap\" rel=\"stylesheet\">
  <link rel=\"stylesheet\" href=\"style.css\" />
</head>
<body>
  <main>
    <header>
      <h1>Turnloop Journal</h1>
      <p>Automated log of Turnloop progress, rendered from <code>agents/historylog.md</code>.</p>
    </header>

    <section class=\"panel\">
      <div class=\"controls\">
        <div class=\"control\">
          <label for=\"loopFilter\">Loop</label>
          <select id=\"loopFilter\">
            <option value=\"all\">All</option>
            <option value=\"Orchestrate\">Orchestrate</option>
            <option value=\"Research\">Research</option>
            <option value=\"Unknown\">Unknown</option>
          </select>
        </div>
        <div class=\"control\">
          <label for=\"roleFilter\">Role</label>
          <select id=\"roleFilter\">
            <option value=\"all\">All</option>
          </select>
        </div>
        <div class=\"control\">
          <label for=\"entrypointFilter\">Entrypoint</label>
          <select id=\"entrypointFilter\">
            <option value=\"all\">All</option>
          </select>
        </div>
        <div class=\"control\">
          <label>Day Numbering</label>
          <div>
            <button id=\"dayLatest\" class=\"active\" type=\"button\">Latest = Day 1</button>
            <button id=\"dayOldest\" type=\"button\">Oldest = Day 1</button>
          </div>
        </div>
      </div>
    </section>

    <section id=\"entries\"></section>

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

  const btnLatest = document.getElementById('dayLatest');
  const btnOldest = document.getElementById('dayOldest');

  function uniq(values) {
    return Array.from(new Set(values)).sort();
  }

  function setButtonState() {
    if (state.dayDirection === 'latest') {
      btnLatest.classList.add('active');
      btnOldest.classList.remove('active');
    } else {
      btnOldest.classList.add('active');
      btnLatest.classList.remove('active');
    }
  }

  function buildOptions(select, values) {
    const current = select.value;
    select.innerHTML = '<option value="all">All</option>';
    values.forEach((val) => {
      const opt = document.createElement('option');
      opt.value = val;
      opt.textContent = val;
      select.appendChild(opt);
    });
    if (values.includes(current)) select.value = current;
  }

  function buildDayMap(entries) {
    const dates = Array.from(new Set(entries.map(e => e.date)));
    dates.sort();
    if (state.dayDirection === 'latest') {
      dates.reverse();
    }
    const map = new Map();
    dates.forEach((d, idx) => map.set(d, idx + 1));
    return map;
  }

  function render(entries) {
    const total = entries.length;
    const dayMap = buildDayMap(entries);
    entriesEl.innerHTML = '';

    entries.forEach((entry) => {
      const dayNum = dayMap.get(entry.date) || 1;
      const wrapper = document.createElement('div');
      wrapper.className = 'entry';
      wrapper.innerHTML = `
        <h3>Day ${dayNum} — ${entry.date} — ${entry.role} • ${entry.title}</h3>
        <div class="meta">
          <span class="badge">${entry.loop}</span>
          <span class="badge">${entry.entrypoint}</span>
        </div>
        <div class="summary">${entry.summary || 'No summary provided.'}</div>
        <details class="details">
          <summary>Details</summary>
          <pre>${entry.details || ''}</pre>
        </details>
      `;
      entriesEl.appendChild(wrapper);
    });

    footerEl.textContent = `Entries: ${total}`;
  }

  function applyFilters(allEntries) {
    let entries = allEntries.slice();
    if (state.loop !== 'all') {
      entries = entries.filter(e => e.loop === state.loop);
    }
    if (state.role !== 'all') {
      entries = entries.filter(e => e.role === state.role);
    }
    if (state.entrypoint !== 'all') {
      entries = entries.filter(e => e.entrypoint === state.entrypoint);
    }
    if (state.dayDirection === 'oldest') {
      entries = entries.slice().reverse();
    }
    render(entries);
  }

  fetch('data.json')
    .then(r => r.json())
    .then(data => {
      const entries = data.entries || [];
      buildOptions(roleFilter, uniq(entries.map(e => e.role)));
      buildOptions(entrypointFilter, uniq(entries.map(e => e.entrypoint)));
      applyFilters(entries);

      loopFilter.addEventListener('change', (e) => {
        state.loop = e.target.value;
        applyFilters(entries);
      });
      roleFilter.addEventListener('change', (e) => {
        state.role = e.target.value;
        applyFilters(entries);
      });
      entrypointFilter.addEventListener('change', (e) => {
        state.entrypoint = e.target.value;
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
""",
        encoding="utf-8",
    )


def build():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if not HISTORYLOG.exists():
        entries = []
    else:
        entries = parse_historylog(HISTORYLOG.read_text(encoding="utf-8"))

    payload = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "entries": entries,
    }
    DATA_JSON.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    write_style()
    write_index()


if __name__ == "__main__":
    build()
