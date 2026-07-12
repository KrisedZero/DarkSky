# Project Analysis — Pixel Horror Castle

> Deliverable 1 of the implementation roadmap. Source of truth: `AGENT.md` + all files in `/docs`.
> This document is analysis only. It does not redesign the game or invent mechanics.

---

## 1. Understanding of the Game

Pixel Horror Castle is a top-down 2D pixel-art horror-survival game built in **Godot 4.x** (GDScript),
at a base resolution of **320×180** with pixel-perfect rendering and a target of **60 FPS**.

The player controls a frightened boy carrying a limited-fuel lantern, exploring a medieval castle at night.
There is **no combat**. Survival depends on light management, resource management, stealth, and hiding.
The player has **one life** — being caught by a monster ends the run (Game Over).

Structure: **7 procedurally generated floors** (floors 1–6 random, floor 7 leads to the roof). The player
navigates rooms and corridors, collects resources, avoids monsters, finds the staircase, and ascends
(auto-checkpoint on each ascent). Reaching the roof triggers a quiet ending scene and credits.
An optional harder "Blood Codex" mode grants an achievement on completion.

---

## 2. Gameplay Loop

Per floor:

1. **Explore** rooms and corridors (top-down WASD movement: walk / run / crouch).
2. **Manage light** — lantern has finite oil (600s / 10 min base); can be toggled off to reduce detection.
3. **Manage resources** — food restores energy; oil refills the lantern; keys open locked doors.
4. **Avoid / hide from monsters** — patrolling monsters detect by vision cone + hearing; hide in furniture
   or flee to balconies (safe zones).
5. **Collect items** — coins from chests, food, oil, keys, and rare artifacts.
6. **Find the staircase** and ascend → screen fade → "Checkpoint saved (Floor N)".

Repeat across 7 floors → Roof ending → Credits → Main Menu.

---

## 3. Technical Architecture

- **Engine / platform:** Godot 4.x, GDScript, export target Windows x86_64.
- **Rendering:** 320×180 base, nearest-neighbor filtering, integer scaling; `Light2D` + `CanvasModulate`
  for dynamic 2D lighting/shadow; cache light shaders and limit light sources for performance.
- **Scene flow:** MainMenu → IntroScene → Floor1…Floor7 → RoofEnding → Credits;
  GameOver returns to MainMenu.
- **Floor node layout:** `Floor` root → TileMap (walls/floors), instanced Room scenes (environment,
  monsters, items), Player (fixed entrance spawn), Camera2D (follows player, clamped to floor bounds),
  CanvasLayer/HUD.
- **Managers (autoloads, cross-cutting):** GameManager (flow, floor advance, achievements, save trigger),
  SaveManager (JSON serialize/deserialize, seed-based regeneration), plus recommended `SignalBus`
  (event decoupling) and `Config` (tunable constants).
- **Persistence:** JSON save, versioned schema; autosave only on floor ascent; floor rebuilt from stored
  seed + list of opened chests/doors for deterministic replay.
- **Conventions (coding-style.md):** snake_case files/functions/vars, PascalCase classes/nodes, `_` for
  private/virtual, signals for callbacks, composition over inheritance, no magic numbers (use
  exported/config constants), placeholder assets marked with TODO.

---

## 4. Gameplay Systems

- Player states (Normal / Hidden) and movement (walk / run / crouch)
- Lantern / light + oil fuel
- Energy / stamina
- Stealth & Hiding (furniture, balconies, lamp-off)
- Monster AI (Patrol / Detect / Chase / Return, vision cone + hearing)
- Interaction (chests, doors, furniture, use items)
- Inventory (coins, keys, food, artifacts)
- Items & Artifacts (consumables, equipment, effects)
- Procedural Generation (floors, rooms, corridors, spawns)
- Room Management (types, furniture, chests, triggers)
- Furniture / Loot / Doors & Keys
- Ghost Merchant (trades coins for artifacts)
- Saving / Checkpoints
- Achievements
- Difficulty / Blood Codex mode
- Audio cues (rain, footsteps, heartbeat, alerts, pickups)
- UI / HUD / Menus (Main Menu, Intro, Pause, Game Over, Roof, Credits)

---

## 5. Technical Systems

- Architecture definition & coding conventions
- Project structure / folder layout / CI (build + lint + script-error checks)
- Core framework: GameManager, SceneLoader, SignalBus, Config/Constants, base entity/interactable classes
- Input layer (InputMap → intents)
- Camera system (follow + bounds/clamp)
- Lighting system (Light2D, CanvasModulate, filters)
- Save system (JSON, versioned schema, seed regeneration)
- Audio manager (Music / Ambient / SFX / UI buses, variable intensity)
- Localization (`tr()` / `tr_n()`, EN first, RU later)
- Optimization (texture atlases, light shader caching, node lifecycle, profiling)
- Balancing (centralized tunable constants / data tables)
- Polishing (animations, VFX, asset replacement)
- Release pipeline (export, smoke tests, docs)

---

## 6. System Dependencies

- Input → Player → (Camera, Lighting, Interaction)
- Interaction → Inventory → Items → Artifacts → Merchant
- Procedural Generation → Rooms → (Furniture, Loot, Doors)
- Monster AI → Stealth (also depends on Lighting, Interaction, Items)
- Saving depends on Player, Generation, Inventory, Loot, Doors
- UI / Menus depend on Inventory, Lighting, Stealth, Save, Audio, Core
- Audio depends on Player, Monster AI, Stealth, UI
- Achievements → Difficulty Modes → Optimization → Balancing → Polishing → Release Candidate

No circular dependencies; each system depends only on earlier systems.

---

## 7. Architectural Risks

- **A1 — Magic numbers:** Many values are "unspecified" across docs; risk of hardcoding, violating the
  coding-style "no magic" rule. Mitigation: a `Config` autoload + `data/` tables (JSON) as the single
  source for all tunable values.
- **A2 — Save determinism:** Seed-based floor regeneration assumes *all* randomness is seeded. Non-seeded
  monster patrol RNG would break reproducible replay. Mitigation: route every RNG stream through the
  stored seed in SaveManager.
- **A3 — Missing Room contract:** `architecture.md` references `docs/world.md` (absent), leaving the Room
  node contract (geometry/furniture/chest/monster/trigger node paths) undefined. Mitigation: author it.
- **A4 — Coupling:** If `PlayerController` calls many systems directly, coupling grows. Mitigation:
  event-driven `SignalBus` (already implied by architecture.md §3 signal usage).
- **A5 — Godot version syntax:** `coding-style.md` uses Godot 3 `export(int) var` syntax while ADR-001 /
  technical-requirements specify Godot 4 (`@export`). Must standardize on Godot 4.

---

## 8. Gameplay Risks

- **G1 — Chase tension:** balancing.md chase speed (140 px/s) is slower than player run speed (180 px/s),
  so the player can always outrun monsters, potentially undermining tension. Needs a design decision.
- **G2 — Stranding:** Energy drain + 10-minute oil + scarce resources could strand the player. Mitigation:
  generation validation rules (guaranteed oil/food, balcony essentials, solvable path).
- **G3 — Health vs instant death:** gameplay.md and monster.md state "no HP bar / caught = death", but the
  save schema stores `player.health`. Contradiction to resolve.
- **G4 — Unspecified values:** detection radius, lamp-off detection factor, cloak/sleep durations, danger
  sense duration, and merchant prices are unspecified or conflicting; must be resolved during balancing.

---

## 9. Missing Documentation

- `README.md` — referenced by `AGENT.md` context-loading, but absent.
- `AGENTS.md` (plural) / `PROJECT.md` at repo root — referenced by the task and architecture.md, but only
  `AGENT.md` and `docs/project.md` exist.
- `docs/world.md` — referenced by architecture.md §5, but absent (Room node contract undefined).
- No dedicated Camera, Audio, Localization, or Difficulty-Modes spec documents.
- No spawn/placement rules for `REP_SPRAY` (Monster Repellent) and `LIFE_AMULET` (Amulet of Survival).
- "Night Vision Potion" appears in generation.md / balancing.md / the save example but has no canonical
  entry in the items.md table.

---

## 10. Suggested Improvements (Vision-Preserving)

- Add a `Config`/Constants autoload so all balancing values live in one place (already implied by
  coding-style "no magic").
- Add a `SignalBus` autoload to decouple Player / Monster / UI communication.
- Author `docs/world.md` defining the Room node contract.
- Add a `data/` folder for item / monster / loot tables as JSON (data-driven per coding-style).
- Keep every unspecified value as a named constant with a `TBD` default + `TODO`, so the balancing phase
  can tune everything centrally without code changes.
- Standardize artifact identifiers (use items.md IDs everywhere, including the save schema).

*(These are structural/process improvements only. No gameplay mechanics are added or changed.)*

---

## Documentation Conflicts to Resolve (carried into Open Questions)

- **C1:** `AGENTS.md`, `README.md`, `docs/world.md` referenced but missing.
- **C2:** coding-style Godot 3 `export(...)` syntax vs Godot 4 (`@export`) per ADR-001.
- **C3:** Monster sight radius — monster.md table "8 tiles" vs text "~5 tiles" vs gameplay "~5 tiles";
  balancing "Detection 8 / Chase 12".
- **C4:** Monster speed — gameplay "slightly faster than player" vs balancing chase 140 < player run 180.
- **C5:** Save `player.health` vs "no HP bar / caught = death".
- **C6:** Artifact naming — save example `["InvisibleCloak","NightVision"]` and generation "Night Vision
  Potion" vs items.md IDs; Night Vision absent from canonical items.md table.
- **C7:** architecture mermaid `RoofEnding →|Game Over| Credits` vs vision/ui Roof→Credits (win).
- **C8:** `REP_SPRAY` and `LIFE_AMULET` defined but have no placement rules.
- **C9:** Danger Sense — gameplay "instantaneous 0.5s" vs items/balancing "60 sec effect".
- **C10:** Achievement name — "Blood Patron" (project.md) vs "Bloodbringer" (gameplay/items).
