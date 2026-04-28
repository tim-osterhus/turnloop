import { describe, expect, it, vi } from 'vitest';
import { INITIAL_WORLD } from '../../src/game/content/world';
import { createInitialGameState, disableTrain, startEngine } from '../../src/game/simulation/gameState';
import type { GameState } from '../../src/game/simulation/types';
import { renderHud } from '../../src/ui/hud/renderHud';
import { renderOverlay } from '../../src/ui/overlays/renderOverlay';

function rootElement(): HTMLDivElement {
  const root = document.createElement('div');
  document.body.replaceChildren(root);
  return root;
}

function initialState(): GameState {
  return createInitialGameState(INITIAL_WORLD);
}

describe('renderHud', () => {
  it('renders train durability, scrap, route progress, and current directive for initial state', () => {
    const root = rootElement();

    renderHud(root, initialState(), { onAction: vi.fn() });

    expect(root.textContent).toContain('Rustline Reclaimer');
    expect(root.textContent).toContain('Engine cold');
    expect(root.textContent).toContain('Durability 100/100');
    expect(root.textContent).toContain('Scrap 0');
    expect(root.textContent).toContain('Route 0%');
    expect(root.textContent).toContain('Old Meridian Locomotive');
    expect(root.textContent).toContain('Scrap Tender');
    expect(root.textContent).toContain('Manual Turret Car');
  });

  it("calls onAction('start-engine') when the start engine action button is clicked", () => {
    const root = rootElement();
    const onAction = vi.fn();

    renderHud(root, initialState(), { onAction });
    root.querySelector<HTMLButtonElement>('[data-action="start-engine"]')?.click();

    expect(onAction).toHaveBeenCalledWith('start-engine');
  });

  it('does not crash when encounter threats are empty and renders a stable no-threat label', () => {
    const root = rootElement();
    const state = {
      ...initialState(),
      encounter: {
        ...initialState().encounter,
        threats: []
      }
    };

    expect(() => renderHud(root, state, { onAction: vi.fn() })).not.toThrow();
    expect(root.textContent).toContain('Threat None');
  });
});

describe('renderOverlay', () => {
  it("renders briefing title and start button, then calls onAction('start-engine')", () => {
    const root = rootElement();
    const onAction = vi.fn();

    renderOverlay(root, initialState(), { onAction });
    const button = root.querySelector<HTMLButtonElement>('[data-action="start-engine"]');
    button?.click();

    expect(root.textContent).toContain('Rustline Reclaimer');
    expect(root.textContent).toContain('containment');
    expect(button?.textContent).toContain('Start engine');
    expect(onAction).toHaveBeenCalledWith('start-engine');
  });

  it("renders disabled recovery copy and calls onAction('recover-train')", () => {
    const root = rootElement();
    const onAction = vi.fn();

    renderOverlay(root, disableTrain(initialState()), { onAction });
    const button = root.querySelector<HTMLButtonElement>('[data-action="recover-train"]');
    button?.click();

    expect(root.textContent).toContain('Recovery');
    expect(button?.textContent).toContain('Recover train');
    expect(onAction).toHaveBeenCalledWith('recover-train');
  });

  it('clears the overlay root for non-overlay phases', () => {
    const root = rootElement();
    root.innerHTML = '<p>stale overlay</p>';

    renderOverlay(root, startEngine(initialState()), { onAction: vi.fn() });

    expect(root.innerHTML).toBe('');
  });
});
