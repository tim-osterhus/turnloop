<prompt id="025-depth-gated-thruster-upgrade-line" task="Depth-Gated Thruster Upgrade Line">
  <objective>
    Align the Corebound surface shop with the active thruster-upgrade task by keeping the third line depth-gated on the Mid Depths milestone, showing its locked state in the shop until that session milestone is reached, and confirming that buying the unlocked line immediately increases movement speed in the running session.
  </objective>
  <context>
    - Repo context comes from `agents/outline.md`; the active gameplay file is `corebound/game.js`.
    - The current upgrade shop already renders from shared `UPGRADE_LINES` data and uses `deepestDepth` plus purchased-tier counts to drive lock and row state.
    - Keep the change minimal and scoped to the task card plus `corebound/game.js`.
    - Do not expand scope into persistence, new strata definitions, or unrelated shop rewrites.
  </context>
  <requirements>
    - Keep the third upgrade line tied to the existing Mid Depths entry row instead of introducing a new hard-coded unlock depth.
    - Ensure the shop presents the line as a thruster upgrade, with locked messaging before the milestone and normal purchase flow after the milestone is reached in the same session.
    - Preserve immediate movement-speed application after purchase and normal tier advancement/maxed behavior.
    - Leave non-thruster upgrade behavior unchanged.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: make the minimal `corebound/game.js` edit needed to align the third speed-upgrade line with the thruster task while preserving the existing unlock and derived-stat flow.
    - 3. Developer: run the required task verification commands plus a focused runtime probe for same-session unlock and immediate speed application.
    - 4. Refactor: perform a brief evidence-based follow-up scan and keep it no-op unless verification exposes a clear low-risk cleanup.
  </plan>
  <commands>
    - `rg -n "mid-depths|deepestDepth|speed|unlock|thrusters" corebound/game.js`
    - `node --check corebound/game.js`
    - `node <<'EOF'
const fs = require("fs");
const vm = require("vm");

function createElement(id = "") {
  return {
    id,
    dataset: {},
    style: {},
    hidden: false,
    disabled: false,
    textContent: "",
    className: "",
    type: "",
    width: 0,
    height: 0,
    children: [],
    listeners: {},
    classList: {
      add() {},
      remove() {},
      toggle() {},
    },
    append(...children) {
      this.children.push(...children);
    },
    addEventListener(type, handler) {
      this.listeners[type] = handler;
    },
    getContext() {
      return {
        fillRect() {},
        strokeRect() {},
        setTransform() {},
      };
    },
  };
}

const elements = new Map();
const document = {
  getElementById(id) {
    if (!elements.has(id)) {
      elements.set(id, createElement(id));
    }
    return elements.get(id);
  },
  createElement(tag) {
    return createElement(tag);
  },
};

const context = {
  console,
  Math,
  Number,
  Object,
  Array,
  Set,
  Map,
  Date,
  document,
  window: {
    devicePixelRatio: 1,
    innerWidth: 1280,
    innerHeight: 720,
    addEventListener() {},
  },
  requestAnimationFrame() {
    return 0;
  },
};
context.globalThis = context;

const source = fs.readFileSync("corebound/game.js", "utf8");
vm.runInNewContext(
  `${source}\n;globalThis.__exports = { state, STRATA, UPGRADE_LINES, TILE_SIZE, STARTING_PLAYER_SPEED, getShopLineState, updateHud, purchaseUpgrade, getMoveSpeed, getDeepestDepth };`,
  context
);

const api = context.__exports;
const thrusterLine = api.UPGRADE_LINES.find((line) => line.id === "thrusters");
if (!thrusterLine) {
  throw new Error("thrusters line missing");
}

api.state.cash = 1000;
api.state.player.y = api.TILE_SIZE * 0.5;
api.updateHud();
let shopState = api.getShopLineState("thrusters", 0);
if (shopState.buttonLabel !== "Locked" || !shopState.statusText.includes("Mid Depths")) {
  throw new Error(`expected locked thrusters at surface before milestone, got ${JSON.stringify(shopState)}`);
}

api.state.player.y = (api.STRATA[1].minRow + 0.5) * api.TILE_SIZE;
api.updateHud();
if (api.getDeepestDepth() < api.STRATA[1].minRow) {
  throw new Error("deepest depth did not update at Mid Depths milestone");
}

api.state.player.y = api.TILE_SIZE * 0.5;
api.updateHud();
shopState = api.getShopLineState("thrusters", 0);
if (shopState.buttonLabel !== "Buy" || shopState.buttonDisabled) {
  throw new Error(`expected unlocked thrusters at surface after milestone, got ${JSON.stringify(shopState)}`);
}

if (!api.purchaseUpgrade("thrusters")) {
  throw new Error("thrusters purchase failed");
}
if (api.getMoveSpeed() <= api.STARTING_PLAYER_SPEED) {
  throw new Error("move speed did not increase after thrusters purchase");
}

shopState = api.getShopLineState("thrusters", 0);
if (!shopState.effectText.includes("+35 speed")) {
  throw new Error(`expected second thruster tier after purchase, got ${JSON.stringify(shopState)}`);
}

console.log("runtime probe ok");
EOF`
  </commands>
  <verification>
    - Before reaching Mid Depths, the thruster line is locked and shows its unlock condition in the shop.
    - Reaching Mid Depths updates session `deepestDepth`, and returning to the surface in the same session unlocks the thruster line if the player can afford it.
    - Buying the thruster line immediately increases movement speed and advances the row to the next tier/maxed state.
    - `node --check corebound/game.js` exits 0.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` when finished.
  </handoff>
</prompt>
