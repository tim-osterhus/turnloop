# Quickfix

- Status: CLOSED (2026-03-06) — resolved in Builder remediator pass.
- Resolved: Removed the out-of-scope `## The Experiment` section from `README.md` and kept only the requested oldest-only staging queue-contract wording.
- Verification: `git diff -- README.md` — PASS; diff is limited to the README queue-contract wording.
- Verification: `rg -n 'oldest staging spec|one-spec-at-a-time|leave newer staging specs' README.md` — PASS
