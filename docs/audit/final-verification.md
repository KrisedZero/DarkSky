# Audit Final Verification — Pixel Horror Castle

> Closing verification deliverable of the audit. Combines what was verified statically (this
> environment) and what still requires a Godot 4.4+ run (no binary available here).

## 1. Static verification — DONE

| Check | Method | Result |
|-------|--------|--------|
| Parse / compile of all scripts | `gdlint scripts/` (gdtoolkit) | **Clean** — no parse or compile errors in any `.gd` file. (Only style notices remain, consistent with the project's own `coding-style.md` SCREAMING_SNAKE + `_` prefix convention; these are not errors.) |
| `data/items.json` integrity | `JSON.parse_string` round-trip (logic-equivalent to `ItemDatabase.load_from`) | Valid JSON; all 15 item entries parse. |
| No global-RNG placement | Grep for `\.shuffle\(\)` in placement/generation | Only seeded `_seeded_shuffle` calls remain; zero `Array.shuffle()`. |
| No stale autoload refs | Grep `SettingsManager\._settings_open` | Zero matches. |
| Cross-reference integrity | Manual trace of signals, autoloads, item IDs, scene UIDs | Consistent (e.g. `blood_mode_toggled` now emitted from chest/merchant/save; `Room.tscn` → `room.gd` uid matches). |

## 2. Runtime verification — REQUIRED (blocked: no Godot binary)

The environment has **no Godot 4.4+ binary** (`Get-Command godot*` → none), so instance-time,
export, and behavioral validation could not be performed. The fixes are correct by static trace but
must be confirmed in-engine.

### Godot verification checklist

Run the project in **Godot 4.4+** (editor or exported build) and confirm:

- [ ] **Boot self-test passes.** The console prints `Core self-test OK: ...` with no `assert`
      failures and **no `GameOverOverlay` present** after boot (validates H8b / `test_mode` fix).
- [ ] **Gameplay input is enabled after boot.** Player can move immediately (validates the
      `InputReader.set_gameplay_enabled` guard).
- [ ] **Floor generation is deterministic.** Running the game twice with the same `run_seed`
      produces identical layouts for floors 1–7 (validates H2 seeded shuffle).
- [ ] **Blood Codex from chest.** Opening a chest that contains `CODEX_BLOOD` grants it and toggles
      Blood Mode (screen/visuals change; `blood_mode_toggled` consumers react) (validates H3).
- [ ] **Blood Codex from merchant.** Buying `CODEX_BLOOD` enables Blood Mode (validates H5).
- [ ] **Blood Codex after save/reload.** Owning the codex, saving, quitting, and loading restores
      Blood Mode (validates H6).
- [ ] **Doors/chests persist per floor.** Opening a chest/door on floor N, advancing, returning
      (or loading), shows it still opened and does not collide with a different floor's state
      (validates H8a unique IDs).
- [ ] **No leaked overlays / stuck input during a real Game Over.** Dying shows the Game Over
      overlay once; "return to menu" restores input (validates H8b in the non-test path).
- [ ] **Settings open/close.** Opening and closing settings from the main menu and pause menu does
      not error or double-toggle (validates I false-positive confirmation).
- [ ] **20+ minute soak.** No `null`/freed-node errors during normal play, floor transitions, and
      merchant/chest interactions (validates H1 freed-node guards).

## 3. Residual items (not blocking, optional follow-up)

See `risk-report.md` §"Residual". None are known to break gameplay; address only if a specific
runtime symptom appears:
- R1 — explicit `viewport_size_changed` handler (Godot stretch mode currently covers scaling).
- R2 — guard `use()` so flag-only equipment isn't consumed from `_stacks`.
- R3 — wire `unregister_player_area` (mitigated by `area_exited` + purge).

## 4. Sign-off

- Code audit: **complete** — all confirmed defects fixed; false positives documented.
- Static lint: **pass** (`gdlint` clean).
- Runtime sign-off: **pending** — execute the §2 checklist in Godot 4.4+.
