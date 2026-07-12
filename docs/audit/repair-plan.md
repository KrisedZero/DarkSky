# Audit Repair Plan — Pixel Horror Castle

> Chronological record of every fix applied during the audit, with `file:line` anchors. All changes
> preserve existing gameplay and the project vision; only defects were corrected.
> Companion docs: `risk-report.md`, `final-verification.md`.

## Phase A — Critical structural fixes (prior session)

1. **C5 — 9 scene textures.** Rewrote the texture node sections in `Player.tscn`, `Monster.tscn`,
   `KeyItem.tscn`, `Merchant.tscn`, `Chest.tscn`, `Door.tscn`, `Furniture.tscn`, `Wardrobe.tscn`,
   `Bed.tscn` to use proper `Texture2D` `ext_resource` references instead of broken `Resource`
   sub-resources.

2. **C1 — Settings/Achievement persistence.** `scripts/settings_manager.gd` and
   `scripts/achievement_manager.gd`: replaced `FileAccess.save_json`/`load_json` (non-existent API)
   with `FileAccess.open` + `store_string(JSON.stringify(data))` and `get_file_as_string` +
   `JSON.parse_string`.

3. **C2 — Settings open flag.** `scripts/main_menu.gd:79`, `scripts/floor_placeholder.gd:43`,
   `scripts/main.gd:730` & `:732`: changed `SettingsManager._settings_open` →
   `GameManager._settings_open`.

4. **C3 — World grid converters.** `scripts/world_grid.gd`: `world_to_tile` and
   `tile_to_world_center` made absolute (removed the spurious `origin` offset). Fixes all A*
   pathfinding, monster navigation, and door grid-blocking.

5. **C4 — Room script attach.** `scenes/Room.tscn`: attached `scripts/room.gd`
   (uid `bkxcl0j6iw7j3`) to the `Room` `Node2D`.

## Phase B — High-severity gameplay / correctness fixes (this session)

6. **H3 — Chest artifact routing.** `scripts/chest.gd:27-36`: loot loop now routes
   `COIN` → `add_coins`, artifacts (`is_artifact`) → `add_artifact` (+ emit `blood_mode_toggled`
   for `CODEX_BLOOD`), else → `ItemManager.pickup`.

7. **H4 — `use()` artifact gate.** `scripts/item_manager.gd:36-39`: `use()` returns early only when
   the artifact is not owned; the `CODEX_BLOOD` branch emits `blood_mode_toggled`.

8. **H5 — Merchant codex activation.** `scripts/merchant.gd:65-68`: `try_buy` emits
   `blood_mode_toggled` when `CODEX_BLOOD` is purchased.

9. **H6 — Save reload blood mode.** `scripts/save_manager.gd` (`load_game`): after `deserialize`,
   emit `blood_mode_toggled` if `CODEX_BLOOD` is owned.

10. **H2 — Deterministic placement.** Added `static func _seeded_shuffle(arr, rng)` (Fisher–Yates)
    to `scripts/floor_generator.gd`, `scripts/door_placer.gd`, `scripts/loot_placer.gd`,
    `scripts/furniture_placer.gd`; replaced every `Array.shuffle()` call:
    - `floor_generator.gd:159` (monster candidate shuffle)
    - `door_placer.gd:26` (`indices`), `:34` (`locked_indices`), `:59` (`key_room_pool`)
    - `loot_placer.gd:84` (`pool`)
    - `furniture_placer.gd:40` (`spots`)

11. **H8a — Globally-unique chest/door IDs.** `scripts/loot_placer.gd:109` (`chest_id`) and
    `scripts/door_placer.gd:42` (`door_id`) / `:63` (`key_id`): now
    `layout.floor_index * 1000 + n`.

12. **H7 — `items.json` alignment.** `data/items.json`: `stackable` flags set to match
    `ItemsData.STACKABLE` (`LIFE_AMULET`, `CLOAK`, `FIRE_MAGIC`, `NIGHT_VISION`, `DANGER_SENSE`,
    `SLEEP_POTION` → `true`); `DANGER_SENSE`/`SLEEP_POTION` `category` corrected from `ARTIFACT` to
    flag-item categories (`EQUIPMENT` / `RARE`). `item_database.gd` only stores entries for lookup,
    so no load breakage.

13. **H8b — Self-test Game-Over leak.** `scripts/main.gd:17` sets `GameManager.test_mode = true`
    at the start of `_run_self_test`; `scripts/main.gd` resets it to `false` after `_test_release`
    (`:55` + trailing `:1002`). `scripts/game_manager.gd:114` guards
    `InputReader.set_gameplay_enabled(false)` behind `if not test_mode`.

14. **H1 — Interaction robustness.** `scripts/interaction_controller.gd:22` validates
    `is_instance_valid(area)` at registration; `:75` purges invalid `BaseInteractable` entries each
    focus refresh.

## Phase C — Verification (this session)

15. Ran `gdlint` over the full `scripts/` tree after each batch of edits; **zero parse/compile
    errors** (only pre-existing, intentional style violations from the project's own `coding-style.md`
    convention, which `gdlint` flags but does not treat as errors).
16. Confirmed no remaining global `Array.shuffle()` in placement/generation scripts.
17. Confirmed no stale `SettingsManager._settings_open` references remain.
18. Confirmed `door.gd` / `hud.gd` / `camera_controller.gd` already handle their suspected issues
    (false positives — no change needed).

## Out of scope (residual — see `risk-report.md`)

- R1 viewport-change handler, R2 `use()` equipment consumption guard, R3
  `unregister_player_area` wiring. Left as-is; low severity and arguably correct as designed.
- No new features were added; no gameplay rebalancing; documentation/roadmap left unchanged.
