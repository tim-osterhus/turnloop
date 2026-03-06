<prompt id="007-fuel-hud-row-controls-note" task="Fuel HUD Row + Controls Note">
  <objective>
    Add a Fuel HUD row with a value span and add a controls list item noting fuel refills at the surface, without changing any fuel logic or styling beyond existing HUD layout.
  </objective>
  <context>
    - Repo scope is within turnloop/, with game UI in corebound/index.html.
    - Task scope is limited to HUD markup and controls text only.
    - Verification is a manual page load via python3 -m http.server.
  </context>
  <requirements>
    - Add a HUD row labeled Fuel with id="hud-fuel-row" and a value span id="hud-fuel".
    - Add a controls list item indicating fuel refills at the surface.
    - Do not implement fuel logic or other styling changes beyond existing HUD layout.
  </requirements>
  <plan>
    1. Builder: Edit corebound/index.html to add the Fuel HUD row and controls note per requirements.
    2. Refactor: Scan for low-risk improvements; if none, record in history log.
    3. Remediator: If agents/work/quickfix.md has OPEN items, address only those items.
  </plan>
  <commands>
    - python3 -m http.server
  </commands>
  <verification>
    - The HUD shows a Fuel row alongside Depth, Cash, and Inventory.
    - The controls panel lists a line indicating fuel refills at the surface.
  </verification>
  <handoff>
    - Prepend a history log entry with task summary, touched files, commands, decisions, follow-ups, prompt path, and artifacts.
    - Overwrite agents/orchestrate_status.md with the correct completion marker.
  </handoff>
</prompt>
