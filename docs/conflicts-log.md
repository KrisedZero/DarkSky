# Conflicts Log — Pixel Horror Castle

> All identified documentation conflicts (C1–C10) resolved per `docs/roadmap.md` M1.T1.
> See also `docs/decisions.md` for new ADR entries.

---

## C1 — Missing Reference Documents

**Source:** `AGENT.md` references `README.md` and `PROJECT.md`; `architecture.md` references `docs/world.md`.

**Resolution:** ✅ Closed
- Authored `README.md` (project summary + doc index).
- Authored `docs/world.md` (Room node contract).
- `AGENT.md` (singular) is the canonical name; no `AGENTS.md` (plural) needed.
- `PROJECT.md` → `docs/project.md` is the canonical location; root `PROJECT.md` not required.

**ADR:** ADR-011 added.

---

## C2 — Godot 3 Export Syntax in Coding Style

**Source:** `docs/coding-style.md` uses `export(int) var max_health = 100` (Godot 3) while ADR-001 and `technical-requirements.md` specify Godot 4 (`@export`).

**Resolution:** ✅ Closed
- Updated `coding-style.md` example to Godot 4 `@export` syntax.
- Codebase already uses Godot 4 syntax consistently.

**ADR:** ADR-012 added.

---

## C3 — Monster Sight Radius

**Source:** `docs/monster.md` table says "8 tiles" but body text says "~5 tiles"; `docs/gameplay.md` says "~5 tiles"; `docs/balancing.md` says "Detection 8 tiles".

**Resolution:** ✅ Closed
- Canonical value: **8 tiles** for sight/detection radius.
- Matches `balancing.md`, `monster.md` table, and `Config.MONSTER_DETECTION_TILES = 8.0`.
- Updated `monster.md` body text from "~5 tiles" to "8 tiles".
- `gameplay.md` text updated to reference the canonical balancing values.

**See also:** C4 (speed balance affects chase tension).

---

## C4 — Monster Chase Speed vs Player Run Speed

**Source:** `docs/gameplay.md` says monsters are "slightly faster than player" while `docs/balancing.md` gives chase speed 140 px/s < player run speed 180 px/s.

**Resolution:** ✅ Closed — **Intentional design**
- Canonical values kept as-is: monster chase 140 px/s, player run 180 px/s.
- Rationale: The player *can* outrun a chasing monster, but running drains energy (0.25%/s) and prevents hiding. Chase tension comes from: energy management, multiple monsters cornering the player, and patrol catching the player off-guard before chase begins.
- Updated `gameplay.md` to remove "slightly faster" wording, replacing with the actual balancing values.

**ADR:** ADR-013 (chase-speed design rationale) added.

---

## C5 — Player Health vs Instant Death

**Source:** `docs/save-system.md` save schema includes `player.health` while `docs/gameplay.md`, `docs/monster.md`, and `docs/gameplay-summary.md` all state "no HP bar / caught = death".

**Resolution:** ✅ Closed — **No health system**
- Removed `player.health` from save schema in `save-system.md`.
- `Config.PLAYER_MAX_HEALTH` retained as an unused constant for future extensibility (marked with comment).
- Player code tracks only energy, lamp_oil, state — no health.
- Caught by a monster = instant Game Over (unless Survival Amulet is active).

**ADR:** ADR-014 added.

---

## C6 — Artifact Naming Inconsistency

**Source:** 
- `docs/items.md` table lacks `NIGHT_VISION` entry.
- `docs/save-system.md` save example uses `["InvisibleCloak","NightVision"]`.
- `docs/generation.md` mentions "Night Vision Potion".
- Code uses `CLOAK`, `NIGHT_VISION` (canonical IDs defined in `ItemsData`).

**Resolution:** ✅ Closed
- Added `NIGHT_VISION` (Night Vision Potion) to `docs/items.md` table.
- Updated `save-system.md` save example to use canonical IDs: `["CLOAK", "NIGHT_VISION"]`.
- `data/items.json` already includes `NIGHT_VISION` — correct.

---

## C7 — Roof: Win vs Game Over

**Source:** `docs/architecture.md` mermaid shows `RoofEnding →|Game Over| Credits` while `docs/vision.md` and `docs/ui.md` treat the roof as the win state.

**Resolution:** ✅ Closed — **Roof = win**
- Fixed `architecture.md` mermaid: `RoofEnding → Credits` (win path).
- Game Over is a separate flow (any floor → caught → Game Over → Main Menu).
- This matches the code: `GameManager._win()` sets `State.WON` and emits `game_won`; `game_over()` is separate.

**ADR:** ADR-015 added.

---

## C8 — REP_SPRAY and LIFE_AMULET Placement Rules

**Source:** `docs/items.md` defines `REP_SPRAY` (Monster Repellent) and `LIFE_AMULET` (Amulet of Survival) but `docs/generation.md` §5 has no placement rules for them.

**Resolution:** ✅ Closed
- Added placement rules to `generation.md` §5:
  - `REP_SPRAY`: ~5% of chests contain one (rare).
  - `LIFE_AMULET`: ~2% of chests contain one (very rare).
- Both already work in code via `ItemManager.use` and `InventoryManager.flags`.

---

## C9 — Danger Sense Duration

**Source:** `docs/gameplay.md` says "instantaneous 0.5s" and also "permanent aura indicator"; `docs/balancing.md` says "60 sec effect"; `docs/items.md` describes a red aura on the screen edge.

**Resolution:** ✅ Closed — **Permanent once acquired**
- Canonical behavior: Danger Sense is a **permanent aura indicator** once purchased from the merchant for the remainder of the run.
- Updated `gameplay.md`: replaced references to "instantaneous 0.5s" with "permanent directional indicator".
- Updated `balancing.md`: replaced "60 sec effect" with "permanent (once acquired)".
- Code implements it as a permanent flag (`InventoryManager.set_flag(DANGER_SENSE, true)`) — no timer.
- The "60 sec" in balancing.md was a placeholder before the permanent design was finalized.

**ADR:** ADR-016 added.

---

## C10 — Achievement Name

**Source:** `docs/project.md` uses "Blood Patron" while `docs/gameplay.md` and `docs/items.md` use "Bloodbringer".

**Resolution:** ✅ Closed — **Bloodbringer**
- Canonical achievement name: **Bloodbringer**.
- "Bloodbringer" is more thematic and appears in more documents.
- Updated `project.md`.

**ADR:** ADR-017 added.
