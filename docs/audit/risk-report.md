# Audit Risk Report — Pixel Horror Castle

> Scope: full production-quality audit of the GDScript codebase (core, player/lighting/camera,
> inventory/items/loot/merchant, world/generation/monster/doors, UI/menus/audio/save, scenes,
> resources, project config). Generated as the closing deliverable of the multi-phase audit
> (Phase 1 audit → Phase 2 risk report → Phase 3 repair plan → Phase 4 safe fixes → Phase 5 verify).
>
> Status legend: **FIXED** (code corrected), **FALSE POSITIVE** (audited, already correct),
> **RESIDUAL** (intentional or very-low-severity, left as-is).

## Critical — fixed

| # | Area | Issue | Impact | Fix |
|---|------|-------|--------|-----|
| C1 | `settings_manager.gd`, `achievement_manager.gd` | Called non-existent `FileAccess.save_json` / `FileAccess.load_json`. | Settings/achievements never persisted; both functions errored/returned garbage. | Replaced with `FileAccess.open` + `store_string(JSON.stringify(...))` and `get_file_as_string` + `JSON.parse_string`. |
| C2 | `main_menu.gd:79`, `floor_placeholder.gd:43`, `main.gd:730/732` | Referenced `SettingsManager._settings_open`. | Runtime `Nil`-attribute error whenever settings opened/closed. | Repointed to `GameManager._settings_open` (the real autoload owner). |
| C3 | `world_grid.gd` (`world_to_tile`, `tile_to_world_center`) | Applied a spurious `origin` offset to conversions. | Every world↔tile mapping was shifted, breaking A* pathfinding, monster navigation, and door grid-blocking. | Made converters absolute (removed origin offset). |
| C4 | `scenes/Room.tscn` | `Room` node had no script attached. | Room node was inert; room logic (`room.gd`) never ran. | Attached `scripts/room.gd` (uid `bkxcl0j6iw7j3`). |
| C5 | 9 scenes (`Player`, `Monster`, `KeyItem`, `Merchant`, `Chest`, `Door`, `Furniture`, `Wardrobe`, `Bed`) | Used broken `Resource` texture sub-resources instead of `Texture2D` ext-resources. | Sprites failed to load (purple/missing) or scene parse warnings. | Rewrote node sections to proper `Texture2D` `ext_resource` references. |

## High — fixed

| # | Area | Issue | Impact | Fix |
|---|------|-------|--------|-----|
| H1 | `interaction_controller.gd` | No freed-node guard at area registration; stale `BaseInteractable` entries could linger. | Potential stale interactions after floor transition. | Added `is_instance_valid(area)` at registration and a purge of invalid entries in `_refresh_focus`. |
| H2 | `floor_generator.gd`, `door_placer.gd`, `loot_placer.gd`, `furniture_placer.gd` | Used global `Array.shuffle()` for placement. | Placement used the global RNG, breaking the per-seed reproducibility contract. | Added a seeded `_seeded_shuffle(arr, rng)` helper (Fisher–Yates) and replaced every `shuffle()` call. Identical seed → identical floors. |
| H3 | `chest.gd` | Loot artifacts (e.g. `CODEX_BLOOD`) routed through `ItemManager.pickup`, which rejects non-stackables. | **Blood Codex could never be obtained from a chest** — core feature silently lost. | Artifacts now route to `InventoryManager.add_artifact` and emit `blood_mode_toggled`. |
| H4 | `item_manager.gd` (`use`) | `use()` gated solely on `has_item`; artifacts have no stack, so the call always returned `false`. | Blood Mode could never be toggled by *using* the codex. | Added an artifact gate (`is_artifact` → `has_artifact`); the `CODEX_BLOOD` branch emits `blood_mode_toggled`. |
| H5 | `merchant.gd` (`try_buy`) | Buying the codex called `add_artifact` but never emitted `blood_mode_toggled`. | Buying Blood Codex from the merchant did not enable Blood Mode. | Emit `blood_mode_toggled` on codex purchase. |
| H6 | `save_manager.gd` (`load_game`) | Did not re-emit `blood_mode_toggled` after restoring an owned codex. | Blood Mode visually/logically off after loading a save that owns the codex. | Emit `blood_mode_toggled` if `CODEX_BLOOD` is owned on load. |
| H7 | `data/items.json` vs `ItemsData` | `stackable` flags and `category` (ARTIFACT) disagreed with code authority. | Data drift vs constants (M10.T1); misleading metadata for flag-owned items. | Aligned `stackable` to `ItemsData.STACKABLE`; corrected `DANGER_SENSE`/`SLEEP_POTION` categories (owned via `get_flag`, not artifacts). |
| H8a | Save layer (cross-floor IDs) | `chest_id`/`door_id` = `idx + 1` per floor → identical IDs across floors. | Opened-chest/door state from one floor overwrote another on save/load. | IDs now `floor_index * 1000 + n` (globally unique per run). |
| H8b | `main.gd` boot self-test + `game_manager.gd` (`game_over`) | Self-test emitted `player_caught` with `test_mode = false` → overlay spawned + gameplay input disabled permanently. | A leaked `GameOverOverlay` on boot and `InputReader` stuck disabled. | Set `GameManager.test_mode = true` around the boot self-test (reset after `_test_release`); guarded `InputReader.set_gameplay_enabled(false)` behind `test_mode`. |

## Medium / Low — fixed or verified

| # | Area | Issue | Result |
|---|------|-------|--------|
| M2 | `camera_controller.gd` | Suspected smoothing lerp across floor change. | **FALSE POSITIVE** — `snap_to_floor` already disables smoothing and sets `global_position` directly. |
| M6 | `monster.gd` (`_chase`) | Suspected unguarded capture call. | **FALSE POSITIVE** — `_chase` already guards `is_instance_valid(player)` at entry. |
| M7 | Heartbeat | Suspected missing heartbeat wiring. | **FALSE POSITIVE** — wired in `hud.gd` via `heartbeat_triggered` (no separate system needed). |
| H6 | `door.gd` (`interact`) | Suspected room-transition double-trigger. | **FALSE POSITIVE** — `interact()` returns early once `is_open`; `interactable_enabled` becomes `false`. |
| H7 | `hud.gd` (`_refresh`) | Suspected per-frame HUD update spam. | **FALSE POSITIVE** — `_refresh()` is event-driven (signal handlers only), not per-frame. |
| H3* | `game_manager.gd:96`, `main.gd` | Suspected autosave firing mid-frame. | **FALSE POSITIVE** — `save_game()` only fires on checkpoint/advance-floor (event-driven). |
| I | `game_manager.gd` settings | Suspected settings double-trigger. | **FALSE POSITIVE** — `open_settings`/`close_settings` both guard on `_settings_open`. |
| J | Merchant floor-1 skip | Suspected off-by-one. | **FALSE POSITIVE** — `floor_index 0` *is* "Floor 1" (documented); merchant correctly starts at floor 2. |

## Residual (intentional / very-low-severity — left as-is)

| # | Area | Note |
|---|------|------|
| R1 | `main.gd` (H8) | No explicit `viewport_size_changed` handler. Godot's stretch mode covers UI scaling; added only if a true resize bug is observed. |
| R2 | `item_manager.gd` (`use`) | Flag-only equipment lives in `_stacks` (count) and could be consumed by `use()`. Low risk: the HUD only exposes "use" on consumables. |
| R3 | `interaction_controller.gd` (`unregister_player_area`) | Never called. Mitigated by `area_exited` + the new purge; the player node persists across floors so no re-register is required. |

## Verification gate
All of the above is validated **statically** (`gdlint` clean + manual trace). A Godot 4.4+ run is
still required to confirm runtime behavior — see `final-verification.md`.
