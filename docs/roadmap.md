# Implementation Roadmap — Pixel Horror Castle

> Deliverable 5 of the planning package. Milestones are built in strict dependency order (see
> `docs/dependency-graph.md`). Each milestone lists objective, expected result, systems involved,
> dependencies, estimated complexity, implementation risks, and validation requirements, then breaks
> down into Tasks and Atomic Steps. Complexity scale: S / M / L / XL. Each Atomic Step ≈ one coding session.

---

> All documentation conflicts C1–C10 have been resolved. See `docs/conflicts-log.md`
> for the resolution record and `docs/decisions.md` for the corresponding ADRs (ADR-011–ADR-017).

## Milestone Index

| # | Milestone | Depends On | Complexity |
|---|-----------|------------|------------|
| M1 | Architecture (Finalize & Reconcile) | — | M |
| M2 | Project Structure | M1 | S |
| M3 | Core Framework | M2 | L |
| M4 | Input | M2, M3 | S |
| M5 | Player | M3, M4 | L |
| M6 | Camera | M5 | S |
| M7 | Lighting | M5, M6 | M |
| M8 | Interaction | M5, M7 | M |
| M9 | Inventory | M8 | M |
| M10 | Items | M9 | L |
| M11 | Procedural Generation | M3 | XL |
| M12 | Rooms | M11 | L |
| M13 | Furniture | M12, M8 | M |
| M14 | Loot | M12, M9, M10 | L |
| M15 | Doors | M12, M9, M8 | M |
| M16 | Saving | M5, M9, M10, M11, M14, M15 | L |
| M17 | Monster AI | M5, M6, M11, M16 | XL |
| M18 | Stealth | M17, M7, M8, M10 | L |
| M19 | Merchant | M10, M9, M17 | M |
| M20 | Artifacts (behaviors) | M10, M18, M17, M7 | L |
| M21 | Audio | M17, M18, M9, M3 | M |
| M22 | UI (HUD) | M9, M7, M18, M3 | M |
| M23 | Menus | M22, M21, M16, M3 | L |
| M24 | Achievements | M20, M23, M16 | S |
| M25 | Difficulty Modes | M20, M7, M17, M14, M16 | M |
| M26 | Optimization | all gameplay/rendering | M |
| M27 | Balancing | M25, M26 | L |
| M28 | Polishing | M26, M27 | M |
| M29 | Release Candidate | M28 | L |
| M30 | World Physics & Navigation | M29 | L |

> The rest of this document is authored milestone-by-milestone. Milestones beyond the last authored
> section are pending and will be expanded on approval.

---

## M1 — Architecture (Finalize & Reconcile)

### Overview

- **Objective:** Lock the architecture, resolve every documentation conflict (C1–C10), and establish the
  binding technical contracts (SignalBus signals, Config constants, GameManager/SceneLoader API, Room node
  contract) before any code is written.
- **Expected result:** A consistent, conflict-free documentation set that acts as the single source of
  truth; a written contract for the core framework; an updated ADR log; and authored stubs for the missing
  reference documents (`README.md`, `docs/world.md`).
- **Systems involved:** Architecture, Coding conventions, Decisions/ADR, Core-framework contracts (spec only).
- **Dependencies:** None (this is the foundation milestone).
- **Estimated complexity:** M.
- **Implementation risks:**
  - Unresolved conflicts cascade into rework across every later milestone.
  - Designer sign-off may be required for gameplay-affecting conflicts (C3, C4, C5, C9, C10).
  - Over-specifying contracts too early can cause churn; keep contracts minimal but authoritative.
- **Validation requirements:**
  - All C1–C10 conflicts have a recorded resolution (or a clearly owned open question).
  - No two documents state contradictory canonical values.
  - Core-framework contract reviewed and approved.
  - ADR log updated; missing reference docs exist (at least as authored stubs).

---

### Task M1.T1 — Reconcile Documentation Conflicts

- **Purpose:** Eliminate every contradiction between documents so downstream implementation has one
  unambiguous source of truth.
- **Reason:** AGENT.md mandates "If documentation conflicts: Ask. Never assume." Conflicts C1–C10 were
  identified in Deliverable 1 and must be closed before coding.
- **Prerequisites:** Deliverables 1–4 complete (analysis, architecture summary, gameplay summary,
  dependency graph).
- **Files likely affected:** `docs/decisions.md` (new ADR entries), `docs/monster.md`, `docs/items.md`,
  `docs/gameplay.md`, `docs/save-system.md`, `docs/coding-style.md`, `docs/project.md`, plus a new
  `docs/conflicts-log.md`.
- **Systems affected:** All (values feed Player, Monster AI, Items, Saving, Achievements, Balancing).
- **Possible risks:** Some conflicts (C3/C4/C5/C9/C10) are gameplay decisions requiring the designer; do
  not silently pick values. Record them as owned open questions if unresolved.
- **Testing checklist:**
  - [ ] Each of C1–C10 has a resolution or an explicit "OPEN — owner/date" note.
  - [ ] Grep the docs for the disputed values (sight radius, chase speed, health, danger-sense duration,
        achievement name) and confirm one canonical value each.
  - [ ] No remaining references to non-existent files without a resolution note.
- **Definition of Done:** `docs/conflicts-log.md` lists all conflicts with status; docs updated to the
  agreed canonical values; ADRs added for any design decisions taken.
- **Future extensibility:** The conflicts log becomes the template for future ADR-style dispute tracking.

**Atomic Steps:**
1. Create `docs/conflicts-log.md` enumerating C1–C10 with source citations and proposed resolutions.
2. Resolve structural conflicts (C1 missing files, C2 Godot 4 syntax, C7 roof-as-win) and record ADRs.
3. Escalate/record gameplay-value conflicts (C3, C4, C5, C6, C8, C9, C10) as ADRs or owned open questions.
4. Apply agreed canonical values back into the affected docs; re-grep to verify single-source consistency.

---

### Task M1.T2 — Define Core Framework Contracts

- **Purpose:** Produce the written, binding contract for the shared foundation: `SignalBus` signal list,
  `Config` constant keys, `GameManager`/`SceneLoader` public API, and the Room node contract.
- **Reason:** Every later milestone depends on these interfaces. Defining them once prevents coupling and
  duplicated ad-hoc interfaces, satisfying the "modular / UI separated from logic / no magic" principles.
- **Prerequisites:** M1.T1 (conflicts resolved so contract values are stable).
- **Files likely affected:** `docs/architecture.md` (contract section), new `docs/world.md` (Room node
  contract), `docs/coding-style.md` (confirm Godot 4 conventions).
- **Systems affected:** Core Framework, and by extension every gameplay/rendering/UI system.
- **Possible risks:** Over-specification causing churn; under-specification leaving ambiguity. Keep the
  contract to names, signatures, and responsibilities — not implementations.
- **Testing checklist:**
  - [ ] SignalBus signal list covers all events named in architecture.md §3.
  - [ ] Config key list covers all balancing.md parameters + flagged TBD values.
  - [ ] GameManager/SceneLoader API covers scene flow from Deliverable 2 §5.
  - [ ] Room node contract defines geometry/furniture/chest/monster/trigger node paths.
  - [ ] Contract reviewed and approved (AGENT.md workflow step 5).
- **Definition of Done:** Architecture contract section written; `docs/world.md` authored; contract
  approved; no undefined interface remains for M2/M3 to start against.
- **Future extensibility:** New systems register against the SignalBus/Config contracts without editing
  existing systems.

**Atomic Steps:**
1. Draft the `SignalBus` signal catalog (name, args, emitter, typical consumers) in architecture.md.
2. Draft the `Config` constant catalog keyed to balancing.md + TBD placeholders (with TODO markers).
3. Draft the `GameManager` + `SceneLoader` public API and scene-flow state list.
4. Author `docs/world.md` defining the Room node contract; cross-link from architecture.md §5.

---

### Task M1.T3 — Author Missing Reference Documents

- **Purpose:** Create the documents referenced by AGENT.md / architecture.md but currently absent, so the
  agent's mandated context-loading step does not fail.
- **Reason:** AGENT.md requires reading `README.md` and `PROJECT.md`; architecture.md references
  `docs/world.md`. These must exist (at least as authored stubs) to satisfy the workflow.
- **Prerequisites:** M1.T1, M1.T2 (so the stubs reflect resolved decisions and contracts).
- **Files likely affected:** new `README.md`, alignment note for `PROJECT.md`/`AGENTS.md` naming,
  `docs/world.md` (created in M1.T2).
- **Systems affected:** Documentation / onboarding only.
- **Possible risks:** Duplicating content already in `docs/project.md`; keep README a concise pointer, not
  a copy.
- **Testing checklist:**
  - [ ] `README.md` exists with project summary, run/build/test instructions, and doc index.
  - [ ] Naming mismatch (`AGENT.md` vs `AGENTS.md`, `PROJECT.md` vs `docs/project.md`) resolved or noted.
  - [ ] All AGENT.md context-loading references resolve to real files.
- **Definition of Done:** No dangling documentation references remain; onboarding path is complete.
- **Future extensibility:** README doc index scales as new docs are added.

**Atomic Steps:**
1. Author `README.md` (summary, how to run/build/test, link to `docs/` index).
2. Resolve the `AGENT.md`/`AGENTS.md` and `PROJECT.md`/`docs/project.md` naming mismatch (ADR or rename note).
3. Verify every path referenced in AGENT.md and architecture.md resolves to an existing file.

---

### M1 Exit Criteria

- All C1–C10 conflicts closed or explicitly owned as open questions.
- Core framework + Room node contracts written and approved.
- Missing reference documents authored.
- ADR log updated.
- Ready to begin M2 (Project Structure) with zero undefined foundations.

---

## M2 — Project Structure

### Overview

- **Objective:** Scaffold the Godot 4 project exactly as the architecture prescribes: folder layout,
  `project.godot` configuration (resolution, rendering, physics), the Input Map, and a CI pipeline that
  builds, runs, and lints the project.
- **Expected result:** A buildable, empty Godot 4 project that opens without errors, exports for Windows,
  boots to a placeholder main scene, and passes an automated CI check (build + script-error + lint).
- **Systems involved:** Project structure, Input map (skeleton only), CI / Quality gate, rendering config.
- **Dependencies:** M1 (architecture locked, contracts + conventions defined, conflicts resolved).
- **Estimated complexity:** S.
- **Implementation risks:**
  - Wrong engine version — ADR-001 says Godot 4.7; must not scaffold against Godot 3 (which also affects
    the `@export` syntax fix from C2).
  - Incorrect pixel-perfect / integer-scaling settings would break the 320×180 art pipeline later.
  - CI misconfiguration (headless Godot export) can silently pass with errors; verify it fails on a broken script.
- **Validation requirements:**
  - Project opens in Godot 4 with zero import/script errors.
  - Base viewport is 320×180 with nearest-neighbor filtering and integer scaling enabled.
  - All Input Map actions defined and documented.
  - CI pipeline runs green on a clean checkout and red when a deliberate script error is introduced.
  - A headless/exported build launches to the placeholder main scene.

---

### Task M2.T1 — Project & Folder Scaffold

- **Purpose:** Create the Godot project file and the canonical folder layout so every later system has a
  defined home.
- **Reason:** architecture.md §5 specifies the folder structure; Deliverable 2 §10 adds `data/`. A stable
  layout prevents ad-hoc file placement and satisfies "prefer existing architecture".
- **Prerequisites:** M1 complete (folder layout confirmed, `data/` addition approved).
- **Files likely affected:** `project.godot`, `scenes/`, `scripts/`, `assets/` (`sprites/ audio/ tilesets/
  fonts/`), `data/`, a placeholder `scenes/Main.tscn`, `.gitignore` for Godot.
- **Systems affected:** Project structure (foundation for all).
- **Possible risks:** Creating a Godot 3 project by mistake; empty folders not tracked by git (add
  `.gdkeep`/`.gitkeep`).
- **Testing checklist:**
  - [ ] Project opens in Godot 4.x with no errors.
  - [ ] All folders from architecture.md §5 + `data/` exist.
  - [ ] Placeholder `Main.tscn` is set as the run/main scene and launches.
  - [ ] `.gitignore` excludes `.godot/`, `export/`, and import caches.
- **Definition of Done:** A clean checkout opens, runs to the placeholder scene, and matches the prescribed
  layout.
- **Future extensibility:** New scenes/scripts/assets slot into predefined folders without restructuring.

**Atomic Steps:**
1. Create the Godot 4 project (`project.godot`) with app name, version 0.1, and Windows export preset stub.
2. Create the folder tree (`scenes/`, `scripts/`, `assets/{sprites,audio,tilesets,fonts}/`, `data/`) with keep files.
3. Add a placeholder `scenes/Main.tscn` + minimal script, set as main scene; add Godot `.gitignore`.

---

### Task M2.T2 — Rendering & Display Configuration

- **Purpose:** Configure the project display for the pixel-art pipeline: 320×180 base, integer scaling,
  nearest-neighbor filtering, 60 FPS target.
- **Reason:** ADR-003/004 and technical-requirements.md mandate crisp pixel-perfect rendering; getting this
  wrong later forces reworking every sprite/light.
- **Prerequisites:** M2.T1.
- **Files likely affected:** `project.godot` (display, rendering, physics sections).
- **Systems affected:** Rendering config (feeds Lighting, Camera, UI).
- **Possible risks:** Texture filtering left on (blurry pixels); window stretch mode wrong (non-integer
  scaling artifacts).
- **Testing checklist:**
  - [ ] Base/viewport resolution = 320×180.
  - [ ] Stretch mode = `viewport`, integer scaling enabled.
  - [ ] Default texture filter = nearest.
  - [ ] Physics + render FPS target = 60.
  - [ ] A test sprite scales without blur or shimmer at window resize.
- **Definition of Done:** Display config matches ADR-003/004 and technical-requirements.md; verified with a
  test sprite.
- **Future extensibility:** Resolution/scale constants centralized; future high-DPI or resolution options
  hook here.

**Atomic Steps:**
1. Set display window size, base viewport 320×180, stretch mode `viewport`, integer scaling in `project.godot`.
2. Set default texture filter to nearest and configure 60 FPS physics/render; verify with a temporary test sprite.

---

### Task M2.T3 — Input Map Definition

- **Purpose:** Define all input actions the game needs (skeleton — bindings only, no handling logic yet).
- **Reason:** technical-requirements.md requires a documented input map for keyboard/controller; M4 (Input
  layer) will consume these actions. Defining them now keeps the Input milestone pure logic.
- **Prerequisites:** M2.T1.
- **Files likely affected:** `project.godot` (input map), a `docs/` input bindings note (or append to
  `docs/technical-requirements.md`).
- **Systems affected:** Input (skeleton), consumed later by Player, Interaction, Menus.
- **Possible risks:** Key clashes; forgetting controller bindings; naming drift vs the SignalBus/Config
  contract from M1.
- **Testing checklist:**
  - [ ] Actions defined: `move_up`, `move_down`, `move_left`, `move_right`, `run`, `interact`,
        `lamp_toggle`, `hide`, `pause`, `ui_confirm`, `ui_cancel`.
  - [ ] Each action has a keyboard binding; movement/confirm/cancel also have controller bindings.
  - [ ] No duplicate/conflicting bindings.
  - [ ] Action names match those referenced in the M1 core contract.
- **Definition of Done:** Input map complete, conflict-free, documented; ready for M4 to consume.
- **Future extensibility:** Rebinding UI and controller support build directly on this action list.

**Atomic Steps:**
1. Add all movement/action input map entries with keyboard bindings in `project.godot`.
2. Add controller bindings for movement + UI confirm/cancel; document the full binding list in docs.

---

### Task M2.T4 — CI / Quality Pipeline

- **Purpose:** Set up automated checks that the project builds, runs headless, has no script errors, and
  passes lint/static analysis.
- **Reason:** technical-requirements.md CI/Quality section and coding-style.md require compilation + no
  warnings on every change; catching regressions early is cheapest here.
- **Prerequisites:** M2.T1 (project must exist to build).
- **Files likely affected:** CI config (e.g. `.github/workflows/ci.yml` or equivalent), a lint config, a
  headless-import/export script.
- **Systems affected:** Quality gate (guards all future milestones).
- **Possible risks:** CI passing despite errors (headless import not failing on script errors); toolchain
  version drift vs the local Godot version.
- **Testing checklist:**
  - [ ] CI runs Godot headless import/build on a clean checkout → green.
  - [ ] CI fails when a deliberate script syntax error is introduced (negative test).
  - [ ] Lint/static analysis step runs and reports.
  - [ ] Pinned Godot version matches ADR-001.
- **Definition of Done:** CI pipeline green on clean checkout, red on injected error, lint active, Godot
  version pinned.
- **Future extensibility:** Add unit-test and export-artifact stages as later milestones introduce testable
  logic.

**Atomic Steps:**
1. Add CI workflow that installs the pinned Godot version and runs a headless import/build.
2. Add lint/static-analysis + script-error check; verify with a negative test (deliberate broken script).

---

### M2 Exit Criteria

- Godot 4 project opens with zero errors and matches the prescribed folder layout.
- Display configured for 320×180 pixel-perfect, integer scaling, 60 FPS.
- Input Map complete, conflict-free, and documented.
- CI green on clean checkout and red on injected errors.
- Ready to begin M3 (Core Framework) against a stable, verified project skeleton.

---

## M3 — Core Framework

### Overview

- **Objective:** Implement the shared foundation defined by the M1 contracts: the `SignalBus` and `Config`
  autoloads, the `GameManager` and `SceneLoader` managers, and the base entity/interactable classes — the
  spine every later system plugs into.
- **Expected result:** The game can start, transition between scenes (menu ↔ placeholder floor ↔ ending),
  read tunable constants from a single source, and dispatch decoupled events through a global signal bus.
  A demonstrable test scene proves scene load/unload and a signal round-trip.
- **Systems involved:** GameManager, SceneLoader, SignalBus, Config/Constants, BaseEntity/BaseInteractable.
- **Dependencies:** M2 (project skeleton, folder layout, input map, CI).
- **Estimated complexity:** L.
- **Implementation risks:**
  - Coupling creep — systems bypassing SignalBus with direct references, violating "modular / UI separated
    from logic".
  - Scene leaks — failing to free unloaded scenes (memory budget < 500 MB).
  - Over-abstraction in base classes (AGENT.md: "never introduce unnecessary abstractions").
  - Config becoming a dumping ground; must mirror the M1 constant catalog, not arbitrary values.
- **Validation requirements:**
  - Autoloads register and are reachable from any scene.
  - SceneLoader loads and fully frees scenes (no orphan nodes / leaks).
  - SignalBus round-trip test: emit → connected listener receives.
  - Config exposes all M1-catalogued constants; no magic numbers introduced.
  - CI stays green; no script warnings.

---

### Task M3.T1 — SignalBus & Config Autoloads

- **Purpose:** Provide the global event bus and the single source of tunable constants.
- **Reason:** architecture.md §3 is signal-driven; coding-style.md forbids magic numbers. These two
  autoloads are prerequisites for decoupled, data-driven implementation of every later system.
- **Prerequisites:** M1.T2 (signal catalog + constant catalog defined), M2 (project + autoload support).
- **Files likely affected:** `scripts/signal_bus.gd`, `scripts/config.gd`, `project.godot` (autoload
  registration), `data/config.json` (optional data-backed constants).
- **Systems affected:** Core (consumed by all).
- **Possible risks:** Signal list drifting from the M1 contract; Config duplicating values that belong in
  data tables; circular autoload references.
- **Testing checklist:**
  - [ ] SignalBus registered as autoload; declares all signals from the M1 catalog.
  - [ ] Config registered as autoload; exposes all M1-catalogued constants with `@export`/const.
  - [ ] Unit/test scene reads a constant and connects to a signal successfully.
  - [ ] No magic numbers introduced elsewhere to bypass Config.
  - [ ] CI green, no warnings.
- **Definition of Done:** Both autoloads exist, match the M1 contract, and are proven by a test scene.
- **Future extensibility:** New systems add signals/constants centrally without touching existing code.

**Atomic Steps:**
1. Implement `scripts/signal_bus.gd` declaring the M1 signal catalog; register as autoload.
2. Implement `scripts/config.gd` exposing the M1 constant catalog (Godot 4 `@export`/const, TODO for TBDs).
3. Write a temporary test scene that reads a Config constant and performs a SignalBus emit→receive round-trip.

---

### Task M3.T2 — GameManager & SceneLoader

- **Purpose:** Implement top-level flow control (start game, advance floors, handle game over, trigger
  saves) and robust scene loading/unloading/transitions.
- **Reason:** architecture.md §2/§3 designate GameManager as overall control and SceneLoader as the scene
  transition mechanism; Deliverable 2 §5 defines the scene flow they must realize.
- **Prerequisites:** M3.T1 (SignalBus/Config available), M2 (main scene + placeholders).
- **Files likely affected:** `scripts/game_manager.gd`, `scripts/scene_loader.gd`, `project.godot`
  (autoload), placeholder scenes for menu/floor/ending.
- **Systems affected:** GameManager, SceneLoader (feed Saving, Menus, Monster AI floor context).
- **Possible risks:** Memory leaks from unfreed scenes; race conditions during transition fades; state kept
  in GameManager that should live in Save/Config.
- **Testing checklist:**
  - [ ] GameManager exposes the M1 API (start_game, advance_floor, game_over, etc.).
  - [ ] SceneLoader loads a scene and frees the previous one (verify no orphan nodes).
  - [ ] Placeholder flow works: Main → placeholder Floor → placeholder Ending.
  - [ ] Transition emits the expected SignalBus events.
  - [ ] Memory does not grow across repeated transitions (leak check).
- **Definition of Done:** Scene flow is drivable end-to-end through GameManager/SceneLoader with no leaks
  and correct signals.
- **Future extensibility:** Adding real floor/menu/ending scenes requires no changes to the flow engine.

**Atomic Steps:**
1. Implement `scripts/scene_loader.gd` (load, unload/free, transition with fade hook); register as autoload.
2. Implement `scripts/game_manager.gd` per the M1 API, driving flow via SceneLoader + SignalBus.
3. Wire placeholder Main→Floor→Ending flow; verify transitions, signals, and a repeated-transition leak check.

---

### Task M3.T3 — Base Entity & Interactable Classes

- **Purpose:** Provide minimal shared base classes/interfaces (`BaseEntity`, `BaseInteractable`) using
  composition, to standardize how entities and interactables are built without deep inheritance.
- **Reason:** coding-style.md mandates composition over inheritance and single responsibility; a thin base
  contract avoids duplicated boilerplate across Player, Monster, Chest, Door, Furniture.
- **Prerequisites:** M3.T1 (SignalBus/Config), M1.T2 (Room node contract informs interactable interface).
- **Files likely affected:** `scripts/base_entity.gd`, `scripts/base_interactable.gd`, `scenes/` stubs.
- **Systems affected:** Player, Monster AI, Interaction, Furniture, Loot, Doors (all build on these).
- **Possible risks:** Over-abstraction / speculative generality; base classes acquiring responsibilities
  that belong to concrete systems.
- **Testing checklist:**
  - [ ] `BaseEntity` and `BaseInteractable` define only shared contract (no gameplay specifics).
  - [ ] A stub subclass compiles and can register an interaction via the contract.
  - [ ] Interfaces align with the M1 Room node contract (`docs/world.md`).
  - [ ] No unused abstraction; CI green, no warnings.
- **Definition of Done:** Thin, documented base classes exist and are validated by a compiling stub
  subclass; nothing speculative added.
- **Future extensibility:** New entity/interactable types subclass these without altering existing systems.

**Atomic Steps:**
1. Implement `scripts/base_entity.gd` (identity, lifecycle hooks, SignalBus access) — minimal surface.
2. Implement `scripts/base_interactable.gd` (interact contract aligned to `docs/world.md`); validate with a stub subclass.

---

### M3 Exit Criteria

- SignalBus and Config autoloads live, matching the M1 contracts, proven by a test scene.
- GameManager + SceneLoader drive the placeholder scene flow with no leaks and correct signals.
- BaseEntity/BaseInteractable provide a thin, validated foundation.
- No magic numbers, no coupling bypasses, CI green.
- Ready to begin M4 (Input) against a working core framework.

---

## M4 — Input

### Overview

- **Objective:** Provide a single input layer (`InputReader`) that translates InputMap actions into
  high-level game intents (move vector, run, interact, lamp toggle, hide, pause, UI confirm/cancel), so no
  other system reads raw `Input.*`.
- **Expected result:** An `InputReader` autoload exposing intent queries; all existing scripts consume it;
  a pure, unit-testable move-vector mapping; an enable/suppress flag for cutscenes/menus.
- **Systems involved:** Input.
- **Dependencies:** M2 (input map), M3 (autoload pattern).
- **Estimated complexity:** S.
- **Implementation risks:** Systems bypassing the layer with direct `Input.*` calls; action-name drift
  vs `project.godot`; pause/UI intents being wrongly suppressed by the gameplay flag.
- **Validation requirements:** Move-vector mapping unit-verified; action names match `project.godot`;
  gameplay suppression does not block pause/UI; lint/format/parse clean.

### Task M4.T1 — InputReader

- **Purpose:** Centralize input reading into intent queries.
- **Reason:** Enforces "one input source"; enables future rebinding and input suppression without touching
  gameplay code.
- **Prerequisites:** M2 input map, M3 autoloads.
- **Files likely affected:** `scripts/input_reader.gd`, `project.godot` (autoload), placeholder scripts
  refactored to use it.
- **Systems affected:** Input (consumed later by Player, Interaction, Menus).
- **Possible risks:** Drift between action-name constants and the input map.
- **Testing checklist:**
  - [x] Action-name constants match `project.godot` `[input]` (11 actions).
  - [x] `compute_move_vector` unit assertions (right/left/up/idle/clamped).
  - [x] Pause + UI intents available while `gameplay_enabled = false`.
  - [x] No raw `Input.*` / `is_action_pressed` outside `InputReader`.
  - [x] gdparse / gdlint / gdformat clean.
- **Definition of Done:** InputReader autoload live, consumed by all scripts, verified.
- **Future extensibility:** Rebinding UI and controller profiles hook into the constants/enable flag.

**Atomic Steps:**
1. Implement `scripts/input_reader.gd` (move vector, run, one-shot intents, enable flag, pure helper); register autoload.
2. Refactor placeholder scripts to consume InputReader; add move-map unit assertions to the boot self-test.

### M4 Exit Criteria

- All input flows through InputReader; move mapping unit-verified; checks clean.
- Ready for M5 (Player) to consume intents.

---

## M5 — Player

### Overview

- **Objective:** Implement `PlayerController` (extends `BaseEntity`): top-down movement (walk/run), energy
  drain/regen, Normal/Hidden state, and the lantern (on/off toggle + oil burn), all intent-driven and
  signal-broadcasting.
- **Expected result:** A `Player.tscn` that moves with WASD, sprints with Shift (spending energy), toggles
  the lamp with F (burning oil), enters/exits a Hidden state via API, and emits state/energy/lamp signals.
- **Systems involved:** Player.
- **Dependencies:** M3 (Config/SignalBus/BaseEntity), M4 (InputReader).
- **Estimated complexity:** L.
- **Implementation risks:** Energy-vs-health conflict (C5) — implemented energy only, no HP, per
  gameplay/monster docs; crouch speed ambiguous (docs tie it to hiding) so not wired as a separate move
  mode yet; hiding trigger belongs to Interaction (M8), so `set_hidden()` is exposed as API for now.
- **Validation requirements:** Speeds match Config; energy clamps [0,100] and blocks running at 0; lamp
  burns oil and auto-offs at 0; signals emit on change; lint/format/parse clean; self-test asserts pass.

### Task M5.T1 — Movement & Energy

- **Purpose:** WASD walk (120) / run (180) / with crouch speed reserved; energy drain (walk 0.1%/s, run
  0.25%/s) and idle regen (1%/min).
- **Reason:** Core control loop and resource pressure.
- **Prerequisites:** M3, M4.
- **Files likely affected:** `scripts/player_controller.gd`, `scenes/Player.tscn`.
- **Systems affected:** Player (feeds Camera, Lighting, Stealth, Save later).
- **Possible risks:** Frame-rate-dependent energy; wrong speed constants.
- **Testing checklist:**
  - [x] Speeds read from Config; run only when energy > 0.
  - [x] Energy clamps to [0, 100]; emits `energy_changed` on change.
  - [x] `move_and_slide` used; delta-scaled energy.
- **Definition of Done:** Player moves at correct speeds and manages energy.
- **Future extensibility:** Status effects (blood mode fatigue, sleep buff) adjust the same constants.

**Atomic Steps:**
1. Implement movement (intent → velocity → move_and_slide) and speed selection.
2. Implement energy drain/regen with clamping and change signals.

### Task M5.T2 — States & Lantern

- **Purpose:** Normal/Hidden state API + lantern on/off toggle with oil burn and auto-off at 0.
- **Reason:** Stealth and lighting hooks depend on these.
- **Prerequisites:** M5.T1.
- **Files likely affected:** `scripts/player_controller.gd`.
- **Systems affected:** Player, Lighting (M7), Stealth (M18), Items (M10 add_oil/add_energy).
- **Possible risks:** State leaks; toggling lamp with zero oil.
- **Testing checklist:**
  - [x] Hidden zeroes movement; emits `player_state_changed`.
  - [x] Lamp toggle emits `lamp_toggled`; oil burns while on; auto-off at 0.
  - [x] `add_oil` / `add_energy` helpers emit updates.
- **Definition of Done:** States and lantern behave per docs; validated by self-test.
- **Future extensibility:** Fire Magic (infinite light) and night-vision hook the lamp state.

**Atomic Steps:**
1. Implement Normal/Hidden state with `set_hidden`/`is_hidden` + signal.
2. Implement lantern toggle, oil burn, auto-off, and item-refill helpers.

### M5 Exit Criteria

- Player moves, spends/regens energy, hides, and manages the lantern; all signals fire; checks clean.
- Ready for M6 (Camera) to follow the player.

---

## M6 — Camera

### Overview

- **Objective:** A `GameCamera` (Camera2D) that follows the player and stays locked inside the floor bounds.
- **Expected result:** `Camera.tscn`/node follows the player smoothly; the view never shows outside the
  floor; bounds are configurable via `set_bounds()`; a pure `clamp_center()` helper is unit-tested.
- **Systems involved:** Camera.
- **Dependencies:** M5 (Player to follow).
- **Estimated complexity:** S.
- **Implementation risks:** Jitter from smoothing vs physics update; floors smaller than the viewport;
  bounds not updated on floor change.
- **Validation requirements:** Camera clamps at edges; centers on floors smaller than the view; follows the
  player; lint/format/parse clean; clamp self-test passes.

### Task M6.T1 — Camera Follow & Bounds

- **Purpose:** Track the player and clamp the view to the floor rectangle.
- **Reason:** Readability and preventing out-of-bounds reveals.
- **Prerequisites:** M5.
- **Files likely affected:** `scripts/game_camera.gd`, `scenes/FloorPlaceholder.tscn`,
  `scripts/floor_placeholder.gd`.
- **Systems affected:** Camera (used later by Monster AI proximity, Stealth heartbeat shake).
- **Possible risks:** Limits int-cast rounding; target freed mid-frame.
- **Testing checklist:**
  - [x] Follows target each physics frame; `is_instance_valid` guarded.
  - [x] `set_bounds` maps to Camera2D limits.
  - [x] `clamp_center` unit-tested (inside / min edge / max edge).
  - [x] Handles floor smaller than view (centers).
- **Definition of Done:** Camera follows and clamps; bounds settable; checks clean.
- **Future extensibility:** Screen shake (heartbeat, M18) and zoom hooks build on this camera.

**Atomic Steps:**
1. Implement `GameCamera` (follow target, `set_bounds` → limits, pure `clamp_center` helper).
2. Add the camera to the floor scene targeting the player; set demo bounds; add clamp self-test.

### M6 Exit Criteria

- Camera follows the player and stays within floor bounds; clamp math verified; checks clean.
- Ready for M7 (Lighting).

---

## M7 — Lighting

### Overview

- **Objective:** Implement the lantern light (radial glow that fades over a few tiles, toggled with the
  lamp state) plus ambient darkness and the Blood Codex red-filter hook.
- **Expected result:** A `LanternLight` (PointLight2D) attached to the player switches on/off with the lamp
  and sizes to `LANTERN_RADIUS_TILES`; a `LightingSystem` (CanvasModulate) darkens the floor and tints red
  when Blood Mode is toggled.
- **Systems involved:** Lighting.
- **Dependencies:** M5 (Player/lamp state), M6 (Camera).
- **Estimated complexity:** M.
- **Implementation risks:** Performance with many lights (cache/limit per technical-requirements); GL
  Compatibility 2D lighting quirks; max radius unspecified in docs (TBD in Config); lamp-toggle emit order
  at spawn.
- **Validation requirements:** Light enables/disables with the lamp; radius derives from Config; darkness
  applied; blood tint reddens ambient; lint/format/parse clean; lighting self-test passes.

### Task M7.T1 — Lantern Light

- **Purpose:** Radial player light with distance falloff, driven by the lamp on/off state.
- **Reason:** Core atmosphere and the basis for stealth detection (M18).
- **Prerequisites:** M5.
- **Files likely affected:** `scripts/lantern_light.gd`, `scenes/Player.tscn`, `scripts/config.gd`.
- **Systems affected:** Lighting (feeds Stealth, Difficulty).
- **Possible risks:** Missing light texture; radius/scale mismatch.
- **Testing checklist:**
  - [x] Light toggles via `lamp_toggled`.
  - [x] Radius derived from `LANTERN_RADIUS_TILES` via `radius_to_scale` (unit-tested).
  - [x] Falloff baked into a generated radial gradient texture (no external asset needed).
- **Definition of Done:** Lantern lights the area, fades with distance, switches with the lamp.
- **Future extensibility:** Fire Magic (permanent light) and night-vision adjust the same light.

**Atomic Steps:**
1. Implement `LanternLight` (radial texture, warm color, radius from Config, toggle on `lamp_toggled`).
2. Attach it under the player's LanternMarker; add the radius/scale unit test.

### Task M7.T2 — Ambient Darkness & Filters

- **Purpose:** Floor-wide darkness via CanvasModulate + a Blood Mode red tint hook.
- **Reason:** Horror mood and the Blood Codex visual (docs).
- **Prerequisites:** M7.T1.
- **Files likely affected:** `scripts/lighting_system.gd`, `scenes/FloorPlaceholder.tscn`,
  `scripts/config.gd`.
- **Systems affected:** Lighting, Difficulty (M25).
- **Possible risks:** Tint hiding gameplay readability; filter cost.
- **Testing checklist:**
  - [x] Ambient darkness from Config applied on ready.
  - [x] `blood_mode_toggled` reddens the tint; pure `apply_blood_tint` unit-tested.
- **Definition of Done:** Dark ambience with lantern brightening; blood tint switchable.
- **Future extensibility:** Sleep-potion "dawn" brighter ambience and other modes reuse the same node.

**Atomic Steps:**
1. Implement `LightingSystem` (CanvasModulate) with ambient darkness + blood-tint helper.
2. Add it to the floor scene; wire to `blood_mode_toggled`; add the tint unit test.

### M7 Exit Criteria

- Lantern lights/fades/toggles; ambient darkness applied; blood tint switchable; checks clean.
- Ready for M8 (Interaction).

> **Next:** M8 — Interaction. Awaiting confirmation to author the next milestone section.

---

## M8 — Interaction

### Overview

- **Objective:** Implement the interaction system: proximity detection of interactables, focus selection
  of the closest valid one, dispatch on the interact input, and a prompt for the HUD. Ship a concrete
  hiding Furniture so the contract is exercised end-to-end.
- **Expected result:** An `InteractionController` (autoload) tracks nearby `BaseInteractable` nodes via the
  player's `InteractionArea`, emits `interaction_focus_changed` for the prompt, and calls `interact()` on
  press. `Furniture` hides the player. The `InteractionPrompt` label reacts to focus.
- **Systems involved:** Interaction, UI (prompt only).
- **Dependencies:** M5 (Player + hidden state), M7 (done), M1–M4 framework.
- **Estimated complexity:** M.
- **Implementation risks:** Area overlap timing at spawn; `just_interact` edge polled in `_process` (fine for
  an autoload); selecting the right target among several overlapping interactables.
- **Validation requirements:** Focus follows the nearest enabled interactable; pressing interact calls its
  `interact()`; prompt shows/hides; lint/format/parse clean; interaction self-test passes.

### Task M8.T1 — Interaction Controller

- **Purpose:** Discover, focus, and dispatch interactions without coupling interactables to the player.
- **Reason:** Centralizes the "press E near thing" rule; the HUD and later chests/doors reuse it.
- **Prerequisites:** M5 (player area / hidden state), M3 (autoloads/signals).
- **Files likely affected:** `scripts/interaction_controller.gd` (new), `scripts/signal_bus.gd`,
  `project.godot` (autoload), `scripts/player_controller.gd`, `scenes/Player.tscn`.
- **Systems affected:** Interaction (feeds Stealth M18, Items M10).
- **Possible risks:** Registering the area before the player exists; stale `_nearby` entries after free.
- **Testing checklist:**
  - [x] Player registers its `InteractionArea` on spawn; signals wired for enter/exit.
  - [x] `select_closest` (pure, unit-tested) picks the nearest enabled interactable.
  - [x] `interaction_focus_changed` / `interaction_performed` emitted (HUD + analytics).
- **Definition of Done:** Nearby interactables are tracked and the closest valid one is focused and dispatchable.
- **Future extensibility:** Doors (open/lock), chests (loot), merchant (trade) subclass `BaseInteractable`.

**Atomic Steps:**
1. Add `interaction_focus_changed` / `interaction_performed` to `SignalBus`.
2. Implement `InteractionController` (register area, track nearby, focus, dispatch); add autoload.
3. Add `InteractionArea` to Player and register it in `PlayerController._on_spawn`.
4. Add the pure `select_closest` helper and its self-test.

### Task M8.T2 — Furniture & Prompt

- **Purpose:** A concrete interactable (hiding furniture) plus the on-screen prompt.
- **Reason:** Validates the contract with real gameplay (stealth toggle) and gives the HUD something to show.
- **Prerequisites:** M8.T1.
- **Files likely affected:** `scripts/furniture.gd` (new), `scenes/Furniture.tscn`,
  `scripts/interaction_prompt.gd` (new), `scenes/Main.tscn`, `scenes/FloorPlaceholder.tscn`.
- **Systems affected:** Interaction, UI.
- **Possible risks:** Prompt not resetting when focus is lost; furniture overlapping other interactables.
- **Testing checklist:**
  - [x] `Furniture.interact(player)` toggles `PlayerController.set_hidden`.
  - [x] `InteractionPrompt` shows `[E] <prompt_text>` on focus, hides on none.
  - [x] A `Wardrobe` instance placed in the floor scene for runtime testing.
- **Definition of Done:** Walking to furniture shows the prompt; pressing E hides the player.
- **Future extensibility:** Beds (rest), chests (loot), doors (locked) subclass or reuse `Furniture`.

### M8 Exit Criteria

- Interactions focus/dispatch correctly; Furniture hides; prompt reacts; checks clean.
- Ready for M9 (pending authoring) — next likely HUD/inventory scaffolding or world generation.

> **Next:** M9 — (to be authored). Awaiting confirmation to author the next milestone section.

---

## M9 — Inventory

### Overview

- **Objective:** Implement the inventory data model and manager: coins, stackable items (keys, food, fuel,
  rare), and unique artifacts — with add/remove/query API and signals. Centralize item IDs so loot, merchant
  and saves agree.
- **Expected result:** An `InventoryManager` autoload holds run state and emits `inventory_changed` /
  `coins_changed` / `artifact_acquired`; `ItemsData` provides canonical item IDs and stackable/artifact sets.
- **Systems involved:** Inventory, Items (definitions land in M10), Saving (M16 consumes this state).
- **Dependencies:** M8 (Interaction emits `interact_requested`; pickups wire in M10).
- **Estimated complexity:** M.
- **Implementation risks:** String drift across systems (mitigated by `ItemsData` IDs); signal recursion
  (`inventory_changed` ↔ `coins_changed`) — guarded by idempotent sync; artifacts must be unique.
- **Validation requirements:** add/remove/spend behave and are bounded; artifacts unique; pure
  `apply_delta`/`can_afford` unit-tested; lint/format/parse clean; inventory self-test passes.

### Task M9.T1 — Item IDs & Inventory Manager

- **Purpose:** Single source of truth for what items exist and what the player carries.
- **Reason:** Every downstream system (loot, merchant, save, HUD) keys off these IDs; one place avoids drift.
- **Prerequisites:** M3 (autoloads/signals), M8.
- **Files likely affected:** `scripts/items_data.gd` (new), `scripts/inventory_manager.gd` (new),
  `scripts/signal_bus.gd`, `project.godot` (autoload).
- **Systems affected:** Inventory (feeds Items M10, Loot M14, Doors M15, Saving M16, Merchant M19, UI M22).
- **Possible risks:** Coins tracked both as a stack and a dedicated field (kept in sync via the signal).
- **Testing checklist:**
  - [x] `ItemsData` IDs + `is_stackable` / `is_artifact` helpers.
  - [x] `add_coins` / `spend_coins` (bounded), `add_item` / `remove_item` / `count` / `has_item`.
  - [x] `add_artifact` enforces uniqueness; `remove_artifact`; `clear` for new game.
  - [x] `apply_delta` / `can_afford` pure helpers (unit-tested).
- **Definition of Done:** Items are stored/queried via stable IDs; artifacts unique; signals emitted.
- **Future extensibility:** M10 maps IDs to effects; M16 serializes `coins`/`_stacks`/`artifacts` to JSON.

**Atomic Steps:**
1. Add `inventory_changed` / `coins_changed` / `artifact_acquired` to `SignalBus` (already present — reuse).
2. Implement `ItemsData` (canonical IDs + category enum + stackable/artifact sets).
3. Implement `InventoryManager` (coins, stacks, artifacts, API, lifecycle, pure helpers); register autoload.

### Task M9.T2 — Wiring & Self-Test

- **Purpose:** Validate behavior headlessly and document the contract.
- **Reason:** No engine runtime; self-tests gate CI alongside lint/format.
- **Prerequisites:** M9.T1.
- **Files likely affected:** `scripts/main.gd` (`_test_inventory`), `docs/roadmap.md`.
- **Systems affected:** Core (self-test), Inventory.
- **Possible risks:** `InventoryManager.clear()` reset between tests if shared state leaks — tests are independent.
- **Testing checklist:**
  - [x] `_test_inventory` covers pure helpers + autoload add/remove/spend/artifact behavior.
  - [x] Roadmap M9 section authored.
- **Definition of Done:** CI gates pass; contract documented for M10/M14/M16/M19/M22.

### M9 Exit Criteria

- Inventory model complete and self-tested; IDs centralized; checks clean.
- Ready for M10 (Items — effects/definitions).

> **Next:** M10 — Items. Awaiting confirmation to author the next milestone section.

---

## M10 — Items

### Overview

- **Objective:** Define all items data-driven (effects, categories, rarity, spawn rules) and implement
  acquisition + consumption: `pickup()` adds to inventory, `use()` applies the effect and consumes one.
- **Expected result:** `data/items.json` holds every item from `docs/items.md`; `ItemDatabase` loads it;
  `ItemManager` (autoload) routes food→energy, oil→lantern, Blood Codex→Blood Mode, equipment/rare→
  ownership flags in `InventoryManager`.
- **Systems involved:** Items, Inventory (M9), Player (effects), Lighting (M7, blood tint).
- **Dependencies:** M9 (Inventory, item IDs).
- **Estimated complexity:** L.
- **Implementation risks:** JSON schema drift from `docs/items.md`; effect application needs a live player
  (HUD/M22 calls `use`); equipment/rare *behaviors* deferred to M17/M18/M20 (M10 only records ownership).
- **Validation requirements:** DB loads; pickup/use mutate inventory + player correctly; blood codex sets
  artifact + flag; pure `resolve_effect` unit-tested; lint/format/parse clean; items self-test passes.

### Task M10.T1 — Item Data & Database

- **Purpose:** One canonical, data-driven table for all items (matches the `data/` recommendation).
- **Reason:** Balancing/loot/merchant/save all read the same source; designers edit JSON, not code.
- **Prerequisites:** M9 (`ItemsData` IDs).
- **Files likely affected:** `data/items.json` (new), `scripts/item_database.gd` (new).
- **Systems affected:** Items (feeds Loot M14, Merchant M19, Saving M16).
- **Possible risks:** Missing ids vs `ItemsData`; bad JSON fails the loader (guarded with push_error).
- **Testing checklist:**
  - [x] 14 items covering every `ItemsData` id.
  - [x] `ItemDatabase` loads JSON, `get_def`/`has`/`all_ids`/`effect_type`/`effect_value`.
  - [x] JSON validated (14 entries, ids match constants).
- **Definition of Done:** Item definitions externalized; loaded at runtime.
- **Future extensibility:** Loot (M14) and Merchant (M19) read spawn/rarity from this table.

**Atomic Steps:**
1. Author `data/items.json` with effect `{type, value}` per item.
2. Implement `ItemDatabase` (load + lookups); validate JSON.

### Task M10.T2 — Item Manager & Effects

- **Purpose:** Acquire and consume items, applying their effects.
- **Reason:** Centralizes "what using an item does"; HUD/M22 and chests/M14 call `use`.
- **Prerequisites:** M10.T1, M9.
- **Files likely affected:** `scripts/item_manager.gd` (new), `scripts/inventory_manager.gd` (flags),
  `project.godot` (autoload), `scripts/item_database.gd`.
- **Systems affected:** Items, Player (energy/oil), Lighting (blood tint), Inventory.
- **Possible risks:** Using a non-owned item; consuming equipment that should persist (consumed but flagged).
- **Testing checklist:**
  - [x] `pickup(id, amount)` adds to inventory; rejects unknown ids.
  - [x] `use(id, player)` applies energy/oil/blood_mode/equipment effects and consumes one.
  - [x] `InventoryManager.flags` stores equipment/rare ownership; cleared on `clear()`.
  - [x] `resolve_effect` pure helper (unit-tested).
- **Definition of Done:** Items acquirable/usable; effects wired to player + inventory.
- **Future extensibility:** M17/M18 give `repel`/`shield`/`cloak`/`light`/`night_vision` real behaviors.

**Atomic Steps:**
1. Add `flags` store + `set_flag`/`get_flag`/`has_flag` to `InventoryManager` (reset in `clear`).
2. Implement `ItemManager` (`pickup`, `use`, pure `resolve_effect`); register autoload.
3. Add `_test_items` self-test (effects on a live player + pure helper).

### M10 Exit Criteria

- Items data-driven and usable; effects apply; flags recorded; checks clean.
- Ready for M11 (Procedural Generation) — or M12/M13/M14 which consume items.

> **Next:** M11 — Procedural Generation. Awaiting confirmation to author the next milestone section.

---

## M11 — Procedural Generation

### Overview

- **Objective:** Build a deterministic, seedable floor generator that produces a `FloorLayout`
  (rooms as a connected tree, corridors, Entrance/Stairs, required Balcony/Bedroom types, monster spawns)
  as pure data — no scene nodes yet.
- **Expected result:** `FloorGenerator.generate(seed, floor_index)` returns a `FloorLayout` that is
  reproducible, always connects Entrance→Stairs, satisfies type rules, and scales with floor index.
- **Systems involved:** Generation (core data); feeds Rooms (M12), Loot (M14), Doors (M15), Monster AI (M17), Saving (M16).
- **Dependencies:** M3 (core framework; no scene/entity deps yet).
- **Estimated complexity:** XL.
- **Implementation risks:** Guaranteeing connectivity + no isolated rooms; determinism across Godot versions;
  rooms overflowing the grid; monster spawns landing on the entrance.
- **Validation requirements:** Same seed→identical layout; stairs reachable (BFS); ≥1 balcony & ≥1 bedroom;
  monster count 3–8 and not on entrance; save round-trip; lint/format/parse clean; generation self-test passes.

### Task M11.T1 — FloorLayout Data Model

- **Purpose:** A node-free container for generated floors (tile coordinates + metadata).
- **Reason:** Keeps generation testable and lets Saving (M16) serialize/rebuild; Rooms (M12) instantiate it.
- **Prerequisites:** M3.
- **Files likely affected:** `scripts/floor_layout.gd` (new).
- **Systems affected:** Generation, Saving.
- **Possible risks:** Mixing tile vs pixel units (kept tile-only here; M12 multiplies by tile size).
- **Testing checklist:**
  - [x] `RoomData` (id/rect/type/center) + `FloorLayout` (rooms, connections, corridors, types).
  - [x] `bounds()`, `room_distance()` (BFS), `entrance_pos()`/`stairs_pos()`.
  - [x] `to_dict()`/`from_dict()` for Saving (M16).
- **Definition of Done:** Layout data is complete and serializable.
- **Future extensibility:** M12 builds TileMap/Room scenes from this; M16 saves `seed`+`floor_index`.

**Atomic Steps:**
1. Implement `FloorLayout` + nested `RoomData` with geometry, queries, and save dict.

### Task M11.T2 — Floor Generator

- **Purpose:** Produce valid, varied, reproducible floors per `docs/generation.md` §1, §4.
- **Reason:** The single source of floor topology for every downstream system.
- **Prerequisites:** M11.T1.
- **Files likely affected:** `scripts/floor_generator.gd` (new).
- **Systems affected:** Generation, Monster AI (spawn points), Loot/Doors (room typing).
- **Possible risks:** Loops/isolated rooms (avoided via tree growth); floor-scaling beyond grid (clamped).
- **Testing checklist:**
  - [x] Seeded grid + random spanning tree (each room connects to a prior one).
  - [x] L-shaped corridors carved between connected centers.
  - [x] Types: Entrance=first, Stairs=farthest (BFS), 1–2 Balconies, ≥1 Bedroom, rest from pool.
  - [x] Monster spawns 3–8 (scale with floor), excluded from entrance/balcony.
- **Definition of Done:** `generate()` yields valid, reproducible, connected floors.
- **Future extensibility:** M14 places chests/loot in bedroom/rooms; M15 adds doors on corridors; M17 spawns monsters at `monster_spawns`.

**Atomic Steps:**
1. Implement `FloorGenerator` (room placement, tree edges, corridors, type assignment, monster spawns).
2. Add `_test_generation` (determinism, connectivity, type rules, monster rules, save round-trip).

### M11 Exit Criteria

- Generation is deterministic, connected, rule-compliant, and serializable; checks clean.
- Ready for M12 (Rooms) to instantiate `FloorLayout` into scenes.

> **Next:** M12 — Rooms. Awaiting confirmation to author the next milestone section.

---

## M12 — Rooms

### Overview

- **Objective:** Turn the generated `FloorLayout` (M11) into actual scene nodes: one `Room` per `RoomData`
  plus corridor floor strips, assembled by `FloorBuilder` into a floor container with correct pixel placement.
- **Expected result:** `FloorPlaceholder` now generates and builds a real (placeholder-art) floor on entry,
  positions the player at the entrance, and sets camera bounds from the layout. Rooms are type-tinted.
- **Systems involved:** Generation (M11), Rooms, Camera (M6), Lighting (M7).
- **Dependencies:** M11 (FloorLayout/FloorGenerator), M6 (camera bounds), M5 (Player).
- **Estimated complexity:** L.
- **Implementation risks:** Tile vs pixel units (layout is tiles; builder multiplies by `TILE_SIZE`);
  room/player positioning when the floor is rebuilt on transition; placeholder art swapped later (M26/M28).
- **Validation requirements:** room instances == layout rooms; corridor visuals == corridors; entrance spawn
  and bounds in pixels match layout; room tints deterministic; lint/format/parse clean; rooms self-test passes.

### Task M12.T1 — Room Scene

- **Purpose:** A reusable, data-driven room node with a per-type floor tint and a center anchor.
- **Reason:** Every floor is composed of these; later milestones attach furniture/chests/monsters to them.
- **Prerequisites:** M11 (RoomData).
- **Files likely affected:** `scripts/room.gd` (new), `scenes/Room.tscn` (new).
- **Systems affected:** Rooms (feeds Furniture M13, Loot M14, Doors M15, Monster AI M17).
- **Possible risks:** Polygon sizing off by a tile; tint map missing a type (defaults handled).
- **Testing checklist:**
  - [x] `Room.setup(data)` draws a `TILE_SIZE`-scaled floor rect and places a Center marker.
  - [x] `Room.color_for(type)` returns a stable tint per type; balcony bright (safe zone).
- **Definition of Done:** Rooms render with correct size + tint from layout data.
- **Future extensibility:** M13 adds furniture anchors; M14 adds chest spawn points; M17 adds monster anchors.

**Atomic Steps:**
1. Implement `Room` (setup from RoomData, center anchor, type tint) + `Room.tscn`.

### Task M12.T2 — Floor Builder & Wiring

- **Purpose:** Instantiate the layout into a live floor and place the player/camera.
- **Reason:** Closes the loop from generation data to a playable (if placeholder) floor.
- **Prerequisites:** M12.T1, M6.
- **Files likely affected:** `scripts/floor_builder.gd` (new), `scripts/floor_placeholder.gd`,
  `scenes/FloorPlaceholder.tscn`, `scripts/game_manager.gd` (run seed).
- **Systems affected:** Rooms, Camera, Generation, Game flow.
- **Possible risks:** Rebuilding on `floor_changed` without clearing old rooms (handled via `queue_free`).
- **Testing checklist:**
  - [x] `FloorBuilder.build(layout, container)` creates one Room per room + one polygon per corridor.
  - [x] Returns `bounds_px` / `entrance_px`; caller sets camera bounds + player spawn.
  - [x] `GameManager.run_seed` + `floor_seed(floor)` make floors reproducible per run.
  - [x] `FloorPlaceholder._build_floor()` generates + builds + positions player/camera; rebuilds on floor change.
  - [x] `_test_rooms` self-test (counts, spawn, bounds, tint).
- **Definition of Done:** Entering a floor yields a generated, navigable (placeholder) layout.
- **Future extensibility:** M26/M28 replace placeholder polygons with tilesets/art; M13–M17 populate rooms.

### M12 Exit Criteria

- Floors are generated and instantiated; player spawns at entrance; camera bounds correct; checks clean.
- Ready for M13 (Furniture), which adds hide spots to rooms.

> **Next:** M13 — Furniture. Awaiting confirmation to author the next milestone section.

---

## M13 — Furniture

### Overview

- **Objective:** Populate generated floors with hiding furniture per `docs/generation.md` §3: one Bed per
  Bedroom, and 0–2 Wardrobes in corridors/bedroom closets. Reuses the M8 `Furniture` interactable (hides player).
- **Expected result:** `FurniturePlacer.place(layout, container, seed)` spawns Beds (in bedrooms) and Wardrobes
  (in corridors) as `Furniture` instances that the player can hide in via the Interaction system (M8).
- **Systems involved:** Furniture, Rooms (M12), Interaction (M8), Stealth (M18 consumes the hide state).
- **Dependencies:** M12 (rooms/layout), M8 (Furniture + InteractionController).
- **Estimated complexity:** M.
- **Implementation risks:** Furniture landing outside a room (mitigated: placed at room/corridor centers in px);
  beds exceeding 1 per bedroom (enforced per-room loop); determinism across seeds.
- **Validation requirements:** one bed per bedroom; 0–2 wardrobes; all are interactable; placement deterministic;
  lint/format/parse clean; furniture self-test passes.

### Task M13.T1 — Furniture Placer

- **Purpose:** Turn layout room types into actual hiding spots.
- **Reason:** Beds (bedrooms) and wardrobes (corridors) are the stealth hide locations from gameplay §5.
- **Prerequisites:** M12, M8 (`Furniture`).
- **Files likely affected:** `scripts/furniture_placer.gd` (new).
- **Systems affected:** Furniture (feeds Stealth M18, Loot M14 for chests later).
- **Possible risks:** Wardrobes with no corridors (falls back to bedroom closets — handled).
- **Testing checklist:**
  - [x] One `Furniture` (is_bed=true, "Rest") per Bedroom room.
  - [x] 0–2 `Furniture` (is_bed=false, "Hide") in corridor centers (or bedroom closets).
  - [x] Deterministic for a given seed; `bedroom_count` pure helper.
- **Definition of Done:** Floors spawn the right furniture in the right places.
- **Future extensibility:** M14 adds chests (loot) to bedrooms; M18 makes hiding actually evade monsters.

**Atomic Steps:**
1. Implement `FurniturePlacer` (beds per bedroom, wardrobes in corridors, deterministic seed).
2. Add `_test_furniture` (counts, interactable group, determinism).

### Task M13.T2 — Wiring

- **Purpose:** Spawn furniture when a floor is built.
- **Reason:** Closes the loop so generated floors contain hide spots.
- **Prerequisites:** M13.T1.
- **Files likely affected:** `scripts/floor_placeholder.gd`, `scenes/FloorPlaceholder.tscn`.
- **Systems affected:** Rooms, Furniture.
- **Possible risks:** Furniture not cleared on floor rebuild (placed in `_rooms`, which FloorBuilder clears).
- **Testing checklist:**
  - [x] `FloorPlaceholder._build_floor` calls `FurniturePlacer` after `FloorBuilder`.
  - [x] Removed the old fixed Wardrobe fixture (now generated from layout).
- **Definition of Done:** Entering a floor yields generated beds/wardrobes.
- **Future extensibility:** M14/M17 add chests/monster anchors to the same rooms.

### M13 Exit Criteria

- Furniture placed per spec and deterministic; checks clean.
- Ready for M14 (Loot) — chests spawn in bedrooms/rooms with items.

> **Next:** M14 — Loot. Awaiting confirmation to author the next milestone section.

---

## M14 — Loot

### Overview

- **Objective:** Place loot chests into generated floors and implement opening them into the inventory.
  Chests roll coins (distribution), 40% food, 20% oil, and ~10% one Blood Codex artifact per floor.
- **Expected result:** `LootPlacer.place(layout, container, seed)` spawns 3–6 `Chest` instances (≥1 in a
  bedroom) with rolled loot; interacting opens them once, depositing contents via InventoryManager/ItemManager.
- **Systems involved:** Loot, Rooms (M12), Inventory (M9), Items (M10), Interaction (M8).
- **Dependencies:** M12 (rooms/layout), M9 (inventory), M10 (items), M8 (InteractionController).
- **Estimated complexity:** L.
- **Implementation risks:** Exactly-one-artifact-per-floor rule; chests overlapping furniture; loot balance
  values ambiguous in docs (oil split, artifact list) — flagged TODO(BALANCE).
- **Validation requirements:** 3–6 chests, ≥1 in a bedroom; opening deposits loot exactly once; deterministic;
  lint/format/parse clean; loot self-test passes.

### Task M14.T1 — Chest Interactable

- **Purpose:** A loot container the player opens once.
- **Reason:** Chests are the primary loot delivery; reuse the interactable contract (M8).
- **Prerequisites:** M8 (BaseInteractable), M9/M10 (inventory/item APIs).
- **Files likely affected:** `scripts/chest.gd` (new), `scenes/Chest.tscn` (new).
- **Systems affected:** Loot, Interaction, Inventory, Items.
- **Possible risks:** Re-opening after loot taken (locked via `is_opened` + `interactable_enabled`).
- **Testing checklist:**
  - [x] `chest.interact` deposits coins (add_coins) + items (ItemManager.pickup) and locks.
  - [x] `chest_opened` signal emitted; snapshot() for save (M16).
- **Definition of Done:** Chests open into the inventory exactly once.
- **Future extensibility:** M16 tracks opened chest ids in the save (no respawn of loot).

**Atomic Steps:**
1. Implement `Chest` (loot dict, one-time open, signal) + `Chest.tscn`.

### Task M14.T2 — Loot Placer & Wiring

- **Purpose:** Spawn chests with rolled loot per `docs/generation.md` §5.
- **Reason:** Closes the loot loop from generation data to obtainable items.
- **Prerequisites:** M14.T1, M12.
- **Files likely affected:** `scripts/loot_placer.gd` (new), `scripts/floor_placeholder.gd`.
- **Systems affected:** Loot, Rooms, Inventory, Items.
- **Possible risks:** Multiple artifacts per floor (gated to one via `artifact_index`); no bedroom (generation
  guarantees ≥1, so the ≥1-chest-in-bedroom rule is satisfiable).
- **Testing checklist:**
  - [x] `roll_loot` (coins distribution, 40% food weighted, 20% oil, one artifact/floor).
  - [x] `place` → 3–6 chests, ≥1 in a bedroom, deterministic for seed.
  - [x] `FloorPlaceholder._build_floor` calls `LootPlacer` after furniture.
  - [x] `_test_loot` (count, bedroom, determinism, open-once).
- **Definition of Done:** Floors contain rolled, openable loot.
- **Future extensibility:** M19 merchant + M25 difficulty adjust drop rates; M16 save opened ids.

### M14 Exit Criteria

- Loot placed per spec, opens into inventory once, deterministic; checks clean.
- Ready for M15 (Doors) — which also consume room/corridor geometry.

> **Next:** M15 — Doors. Awaiting confirmation to author the next milestone section.

---

## M15 — Doors

### Overview

- **Objective:** Place doors on corridors and matching keys per `docs/generation.md` §2: some doors locked
  (require a KEY), locked doors ≤3 per floor, each locked door's key on the entrance side for completability.
- **Expected result:** `DoorPlacer.place(layout, container, seed)` spawns `Door` instances (some locked) and
  `KeyItem` pickups; interacting opens unlocked doors or consumes a key for locked ones.
- **Systems involved:** Doors, Rooms (M12), Inventory (M9), Interaction (M8).
- **Dependencies:** M12 (corridors/connections), M9 (KEY), M8 (InteractionController).
- **Estimated complexity:** M.
- **Implementation risks:** Key reachability (solved by placing keys on the entrance side via tree split);
  physical passage blocking deferred until tile collision (M26) — door is a logical lock for now.
- **Validation requirements:** locked ≤3, keys == locked count, entrance side contains entrance; door
  open/lock consumes a key; lint/format/parse clean; doors self-test passes.

### Task M15.T1 — Door & Key Interactables

- **Purpose:** Lockable door + a key the player can pick up.
- **Reason:** Gates progression; matches the locked-door/key rule from generation §2.
- **Prerequisites:** M8 (BaseInteractable), M9 (KEY).
- **Files likely affected:** `scripts/door.gd` (new), `scenes/Door.tscn` (new),
  `scripts/key_item.gd` (new), `scenes/KeyItem.tscn` (new).
- **Systems affected:** Doors, Interaction, Inventory.
- **Possible risks:** Locked door with no key (guarded by placement rule + `would_open` pure check).
- **Testing checklist:**
  - [x] `Door.interact` opens unlocked; locked needs KEY (consumes one) else stays shut.
  - [x] `KeyItem.interact` grants a KEY; `Door.would_open` pure helper.
- **Definition of Done:** Doors lock/unlock correctly; keys grant access.
- **Future extensibility:** M26 adds tile collision so closed doors actually block movement.

**Atomic Steps:**
1. Implement `Door` (lock/open, key consume, signal) + `KeyItem` (grant key) and their scenes.

### Task M15.T2 — Door Placer & Wiring

- **Purpose:** Scatter doors on corridors with matching keys.
- **Reason:** Closes the locked-door loop from generation data.
- **Prerequisites:** M15.T1, M12.
- **Files likely affected:** `scripts/door_placer.gd` (new), `scripts/floor_placeholder.gd`.
- **Systems affected:** Doors, Rooms, Inventory, Interaction.
- **Possible risks:** Keys behind the locked door (avoided: placed on entrance side via `entrance_side_rooms`).
- **Testing checklist:**
  - [x] `place` → doors on corridors, ≤3 locked, keys == locked count, deterministic.
  - [x] `entrance_side_rooms` (tree split) always includes the entrance room.
  - [x] `FloorPlaceholder._build_floor` calls `DoorPlacer` after loot.
  - [x] `_test_doors` (caps, key count, side, open/lock, key pickup).
- **Definition of Done:** Floors contain doors + reachable keys.
- **Future extensibility:** M16 saves opened-door state; M25 difficulty tweaks lock rates.

### M15 Exit Criteria

- Doors placed per spec with completable key placement; checks clean.
- Ready for M16 (Saving) — which serializes floor seed + opened chest/door ids.

> **Next:** M16 — Saving. Awaiting confirmation to author the next milestone section.

## M16 — Saving

### Overview

- **Objective:** Persist run progress so the player can quit and resume. Per `docs/save-system.md`, the
  save is a single JSON file (`user://save.json`) holding: `version`, `random_seed`, `current_floor`,
  `player` stats, `inventory` (coins/stacks/artifacts/flags), `opened_chests`, `opened_doors` and
  `blood_codex_mode`. Autosave fires on floor ascent (checkpoint).
- **Expected result:** `SaveManager` (autoload) serializes the live run into a versioned dict; `save_game()`
  writes JSON; `load_game()` rebuilds the floor from the seed and marks saved chest/door IDs opened so
  loot/locks are skipped. A "Continue" later (M23) reads this file.
- **Systems involved:** Save system, GameManager (run seed/floor + ascent), Inventory (M9), Items (M10),
  Chests (M14), Doors (M15), Player (M5).
- **Dependencies:** M9 (inventory truth), M11/M12 (deterministic seed → floor), M14/M15 (opened IDs).
- **Estimated complexity:** M.
- **Implementation risks:** Restore must not double-apply loot/locks — solved by regenerating the floor
  from the seed, then re-marking only saved IDs opened (idempotent). Live `chest_opened`/`door_opened`
  signals are ignored while `_restoring` is true so they can't clobber loaded state.
- **Validation requirements:** JSON round-trip (serialize→deserialize) preserves seed/floor/inventory/
  opened IDs/player stats; file round-trip via `save_game`/`load_game`; `gdparse`/`gdlint`/`gdformat`
  clean; `_test_save` passes.

### Task M16.T1 — SaveManager Autoload

- **Purpose:** Single serializer/deserializer for the whole run.
- **Reason:** One source of truth for persistence (matches InventoryManager as the inventory truth).
- **Prerequisites:** M9, M11, M14, M15.
- **Files likely affected:** `scripts/save_manager.gd` (new), `project.godot` (autoload `SaveManager`).
- **Systems affected:** Save, GameManager, Inventory, Player.
- **Possible risks:** Cross-script private access — avoided by `InventoryManager.get_save_data()`/
  `load_save_data()` accessors; player restore deferred to next `player_spawned`.
- **Testing checklist:**
  - [x] `serialize()` snapshots seed/floor/inventory/opened IDs/blood mode/player.
  - [x] `deserialize()` reconstructs GameManager + InventoryManager state; sets `_restoring`.
  - [x] `apply_opened_to_scene()` marks saved Chest/Door IDs opened, then ends restore mode.
  - [x] `has_save`/`delete_save` lifecycle.
- **Definition of Done:** Deterministic save format, single owner of persistence.
- **Future extensibility:** M23 "Continue" button; M25 difficulty could add `difficulty` to the save.

**Atomic Steps:**
1. Implement `SaveManager` with `serialize`/`deserialize`/`apply_opened_to_scene`/`has_save`/`delete_save`
   plus the `InventoryManager.get_save_data()`/`load_save_data()` accessors. Register the autoload.

### Task M16.T2 — Autosave & Restore Wiring

- **Purpose:** Persist on ascent; restore on load.
- **Reason:** The design calls for autosave at each floor checkpoint.
- **Prerequisites:** M16.T1, M3 (GameManager), M2 (FloorPlaceholder).
- **Files likely affected:** `scripts/game_manager.gd` (autosave in `advance_floor`; clear save in
  `start_game`), `scripts/floor_placeholder.gd` (`apply_opened_to_scene` after build).
- **Systems affected:** Save, GameManager, Rooms.
- **Possible risks:** `load_game` leaves `_restoring` true until the floor rebuild applies opened IDs;
  FloorPlaceholder's `_build_floor` calls `apply_opened_to_scene(self)` so the flag clears.
- **Testing checklist:**
  - [x] `advance_floor` → `SaveManager.save_game()` after `checkpoint_saved`.
  - [x] `start_game` → `SaveManager.delete_save()` (new run overwrites stale save).
  - [x] `FloorPlaceholder._build_floor` applies restored opened IDs.
  - [x] `_test_save` covers serialize/deserialize + file round-trip.
- **Definition of Done:** Ascending a floor creates a resumable save; loading rebuilds + restores.
- **Future extensibility:** M23 exposes Continue; settings (M24) may change save path.

### M16 Exit Criteria

- `SaveManager` autosaves on each ascent; `load_game` resumes seed, floor, inventory, opened IDs and
  player stats. Checks clean; `_test_save` passes.
- Ready for M17 (Monsters) — which adds roaming threats whose positions are regenerated from the seed
  (not saved), keeping saves compact.

> **Next:** M17 — Monsters. Awaiting confirmation to author the next milestone section.

## M17 — Monsters

### Overview

- **Objective:** Roaming threats that patrol, detect (vision + hearing), chase, search and return, and
  kill the player on contact (instant Game Over). Per `docs/monster.md` / `docs/gameplay-summary.md` §4,
  monsters spawn 3–8 per floor from `FloorLayout.monster_spawns` (deterministic, not saved).
- **Expected result:** `MonsterPlacer.place(layout, container, seed)` instantiates `Monster` entities at
  spawn tiles; each runs a `PATROL/CHASE/SEARCH/RETURN` state machine using the pure `would_detect`
  helper. Spotting emits `monster_spotted_player`; catching emits `player_caught` → `GameManager.game_over`.
- **Systems involved:** Monster AI, Generation (M11), Player (M5), SignalBus, GameManager (M3), Save (M16).
- **Dependencies:** M11 (monster_spawns), M5 (Player state/lamp), M3 (GameManager.game_over), M16 (seed).
- **Estimated complexity:** M.
- **Implementation risks:** No TileMap yet → `A*` pathfinding deferred to M26, so chase uses straight-line
  movement (acceptable placeholder). Detection conflicts (C3 sight 5 vs 8, C4 chase < run, C9 durations)
  are set as `TODO(BALANCE)` in `Config` and noted on the class.
- **Validation requirements:** `would_detect` covers hidden/lamp-on/lamp-off cases; placement count range,
  no spawn at entrance, deterministic; state transitions PATROL→CHASE→SEARCH→RETURN→PATROL; lint/format/
  parse clean; `_test_monsters` passes.

### Task M17.T1 — Monster Entity & Detection

- **Purpose:** One Monster class with a state machine and a pure, testable detection rule.
- **Reason:** The core threat; must be deterministic-save-friendly (positions from seed, not state).
- **Prerequisites:** M5 (Player), M11 (monster_spawns), `Config` constants.
- **Files likely affected:** `scripts/monster.gd` (new), `scenes/Monster.tscn` (new), `scripts/config.gd`.
- **Systems affected:** Monster AI, Player, SignalBus, Inventory (blood mode speed).
- **Possible risks:** C3/C4/C9 resolved in conflicts-log.md — fixed values in Config match resolutions.
- **Testing checklist:**
  - [x] `Monster.would_detect` — hidden always safe; lamp on = vision cone + hearing; lamp off = hearing only.
  - [x] State machine transitions via `_apply_detection` (CHASE on detect, SEARCH→RETURN→PATROL on loss).
  - [x] Blood Codex raises chase speed (`BLOOD_MODE_MONSTER_SPEED`).
- **Definition of Done:** Monsters detect/patrol/chase without engine-only logic in the pure path.
- **Future extensibility:** M26 adds `A*` so `_move_toward` follows corridors; M22 adds alert vignette (UI).

**Atomic Steps:**
1. Implement `Monster` (`Patrol/Chase/Search/Return`, `would_detect` static, `player_caught` on contact)
   and its `Monster.tscn`. Add `BLOOD_MODE_MONSTER_SPEED` to `Config`.

### Task M17.T2 — Placement & Game-Over Wiring

- **Purpose:** Spawn monsters on the floor and end the run when caught.
- **Reason:** Closes the threat loop from generation data to a loss condition.
- **Prerequisites:** M17.T1, M3 (GameManager), M2 (FloorPlaceholder).
- **Files likely affected:** `scripts/monster_placer.gd` (new), `scripts/floor_placeholder.gd`,
  `scripts/game_manager.gd`, `scenes/Player.tscn` (add `player` group).
- **Systems affected:** Monster placement, Game flow, Player.
- **Possible risks:** Monster must find the player reliably — added the `player` group to `Player.tscn`;
  `GameManager` connects `player_caught` → `game_over` in `_ready`.
- **Testing checklist:**
  - [x] `MonsterPlacer.place` deterministic; counts in 3–8; none at entrance.
  - [x] `FloorPlaceholder._build_floor` places monsters after doors.
  - [x] `player_caught` → `GameManager.game_over` sets `State.GAME_OVER` and emits `game_over`.
  - [x] `_test_monsters` (detection, placement, state machine).
- **Definition of Done:** Floors contain roaming monsters; being caught ends the run.
- **Future extensibility:** M23 Main Menu "Continue" restores seed so monsters re-spawn identically.

### M17 Exit Criteria

- `Monster` + `MonsterPlacer` place 3–8 deterministic, seed-derived monsters per floor; detection and
  chase work via pure/tested logic; `player_caught` triggers Game Over. Checks clean; `_test_monsters`
  passes.
- Ready for M18 (Merchant) — which adds the ghost merchant whose appearance is independent of monsters.

> **Next:** M18 — Ghost Merchant. Awaiting confirmation to author the next milestone section.

## M18 — Ghost Merchant

### Overview

- **Objective:** A ghost merchant that appears with 50% chance on floors ≥ 2, in a room that is neither
  entrance nor stairs, selling rare items (merchant-tagged entries in `data/items.json`). Buying spends
  coins and grants the item (or unique artifact). Interaction emits `merchant_trade_opened` for the UI
  (M23/M24) and records the `merchant_visited` flag so the save can track it.
- **Expected result:** `Merchant` (BaseInteractable) holds a deterministic per-floor stock derived from
  items whose `"spawns"` include `"merchant"`. `MerchantPlacer.place()` places at most one merchant per
  floor with 50% chance; `try_buy(id)` is a pure-ish trade API (cheques coins, deducts, grants, returns
  true/false). Three new items added to items.json + ItemsData to match `docs/items.md`: DANGER_SENSE,
  SLEEP_POTION (both with prices). All merchant items gained a `"price"` field.
- **Systems involved:** Merchant, Items (items.json + prices), Inventory (coins/flags), Interaction (M8),
  Save (merchant_visited flag), Placement (M14+ style).
- **Dependencies:** M8 (BaseInteractable), M9/M10 (Inventory, items.json, ItemDatabase), M12 (rooms for
  candidate placement), M16 (merchant_visited flag saved generically).
- **Estimated complexity:** M.
- **Implementation risks:** Prices are provisional (items.md loose ranges vs generation.md "5-10"). The
  Blood Codex is unique — removed from stock after purchase. 50% deterministic chance uses a seeded RNG.
- **Validation requirements:** `try_buy` rejects poor players, deducts coins on success, grants items
  (stackable via add_item, artifact via add_artifact). Blood Codex unique. `interact` emits signal +
  sets flag. Floor 1 never has merchant; floor 2+ sometimes has merchant (not entrance/stairs).
  `_test_merchant` covers all. Lint/format/parse clean.

### Task M18.T1 — Merchant Entity & Trade API

- **Purpose:** One Merchant interactable with a deterministic stock list and a buy method.
- **Reason:** Central point for rare-item acquisition; the only source of artifacts (Blood Codex) and
  high-tier equipment per `docs/items.md`.
- **Prerequisites:** M8 (BaseInteractable), M9 (Inventory coins + flags), items.json (prices added).
- **Files likely affected:** `scripts/merchant.gd` (new), `scenes/Merchant.tscn` (new),
  `data/items.json` (add prices + DANGER_SENSE, SLEEP_POTION), `scripts/items_data.gd` (add new IDs),
  `scripts/item_manager.gd` (add danger_sense/sleep effect cases), `scripts/signal_bus.gd` (add
  merchant_trade_opened signal).
- **Systems affected:** Merchant, Items, Inventory, SignalBus.
- **Possible risks:** Stock uses ItemManager._db entries filtered by `spawns` containing "merchant".
  Seeded shuffle ensures determinism across floor transitions. Blood Codex removed from stock if owned.
- **Testing checklist:**
  - [x] `price_of` returns correct values for merchant items, -1 for non-merchant.
  - [x] `try_buy` fails when poor, succeeds with sufficient coins, deducts, grants item/artifact.
  - [x] Blood Codex unique — second purchase fails.
  - [x] `interact` emits `merchant_trade_opened` + sets `merchant_visited` flag.
- **Definition of Done:** An interactable merchant that can sell its items to a player with enough coins.
- **Future extensibility:** M23/M24 connect the signal to a trade UI panel.

**Atomic Steps:**
1. Implement `Merchant` + `Merchant.tscn`; extend items.json with prices and two missing merchant
   artifacts; add new IDs to ItemsData and effect cases to ItemManager; add signal to SignalBus.

### Task M18.T2 — Placement & Wiring

- **Purpose:** Spawn the merchant on eligible floors with 50% deterministic chance.
- **Reason:** Closes the placement loop from generation data.
- **Prerequisites:** M18.T1, M12 (rooms for candidate selection), M2 (FloorPlaceholder).
- **Files likely affected:** `scripts/merchant_placer.gd` (new), `scripts/floor_placeholder.gd`.
- **Systems affected:** Merchant placement, Room placement.
- **Possible risks:** Merchant placed in a non-entrance/non-exit room; 50% chance uses seeded RNG
  (deterministic). Floor 1 (floor_index 0) excluded.
- **Testing checklist:**
  - [x] No merchant on floor 1.
  - [x] At some seed on floor 2+ the merchant appears.
  - [x] The placed merchant's room is not entrance or stairs.
  - [x] `FloorPlaceholder._build_floor` calls `MerchantPlacer.place` after monsters.
  - [x] `_test_merchant` (stock, buy, interaction, placement).
- **Definition of Done:** Floors ≥ 2 sometimes contain a ghost merchant in a valid room.
- **Future extensibility:** M23 adds trade UI opening on interaction; M24 adds player inventory overlay.

### M18 Exit Criteria

- `Merchant` + `MerchantPlacer` place a deterministic interactable merchant on floors ≥ 2 (50% chance);
  `try_buy` grants items/artifacts in exchange for coins; `interact` records the visit and emits the
  trade signal. Checks clean; `_test_merchant` passes.
- Ready for M19 (Monster Repellent) — which implements the REP_SPRAY and LIFE_AMULET usage effects that
  the merchant and chests can already supply.

> **Next:** M19 — Monster Repellent & Survival Amulet. Awaiting confirmation to author the next milestone section.

## M19 — Monster Repellent & Survival Amulet

### Overview

- **Objective:** Make the two rare survival items functional. `REP_SPRAY` (Monster Repellent) makes the
  player undetectable to monsters while its flag is set; `LIFE_AMULET` (Survival Amulet) is a one-time
  death shield — on being caught it is consumed instead of triggering Game Over. Both are already granted
  by `ItemManager.use` (M10) which only sets the owning flag; M19 wires those flags into real behavior.
- **Expected result:** `Monster._physics_process` skips detection when `InventoryManager.has_flag(REP_SPRAY)`
  is set (monster reverts to Patrol). `GameManager._on_player_caught` consumes `LIFE_AMULET` (emits
  `player_shield_consumed`) and returns without dying; otherwise `game_over()` runs as before.
- **Systems involved:** Monster AI (M17), Game flow (M3), Inventory (M9), Items (M10), SignalBus.
- **Dependencies:** M10 (REP_SPRAY/LIFE_AMULET effect flags), M17 (Monster detection + player_caught),
  M3 (GameManager.game_over). The items are already obtainable from chests (M14) and the merchant (M18).
- **Estimated complexity:** S (behavior wiring only; no new scenes or data tables).
- **Implementation risks:** REP_SPRAY duration is unspecified in docs ("temporarily repels") — modeled as
  a per-run flag active until cleared (TODO(BALANCE)); LIFE_AMULET is strictly one-time by design.
- **Validation requirements:** With REP_SPRAY set, a monster that would chase stays in Patrol; without it,
  the same setup chases. With LIFE_AMULET set, `player_caught` leaves the game PLAYING and clears the flag;
  without it, `player_caught` triggers Game Over. Lint/format/parse clean; `_test_survival` passes.

### Task M19.T1 — Repellent Behavior

- **Purpose:** Repel monsters while the repellent flag is active.
- **Reason:** Honors the REP_SPRAY effect described in docs/items.md ("temporarily repels monsters").
- **Prerequisites:** M17 (Monster detection), M9 (Inventory flag), M10 (REP_SPRAY flag set on use).
- **Files likely affected:** `scripts/monster.gd`.
- **Systems affected:** Monster AI, Inventory.
- **Possible risks:** Must not change the pure `would_detect` helper; repel is an integration-layer AND.
- **Testing checklist:**
  - [x] Monster chases a close, lit, unhidden player when REP_SPRAY is clear.
  - [x] Same setup stays in Patrol when REP_SPRAY is set.
- **Definition of Done:** The repellent flag suppresses monster detection.
- **Future extensibility:** M25 tuning can make the repellent time-limited / charge-based.

**Atomic Steps:**
1. In `Monster._physics_process`, set `detected = detected and not InventoryManager.has_flag(REP_SPRAY)`.

### Task M19.T2 — Survival Shield

- **Purpose:** A one-time death shield consumed on capture.
- **Reason:** Honors the LIFE_AMULET effect in docs/items.md ("prevents death once").
- **Prerequisites:** M3 (GameManager), M17 (player_caught signal).
- **Files likely affected:** `scripts/game_manager.gd`, `scripts/signal_bus.gd`.
- **Systems affected:** Game flow, SignalBus.
- **Possible risks:** `game_over` must still fire when the amulet is absent; the shield must not re-trigger
  once consumed. Implemented by intercepting `player_caught` before `game_over`.
- **Testing checklist:**
  - [x] `player_caught` with no amulet → `GameManager.state == GAME_OVER`.
  - [x] `player_caught` with LIFE_AMULET → state stays PLAYING, flag cleared, `player_shield_consumed` emitted.
  - [x] `SignalBus.player_shield_consumed` added.
- **Definition of Done:** Capture is survivable exactly once per amulet.
- **Future extensibility:** M22 UI shows the active shield; M16 save persists the flag across floors.

### M19 Exit Criteria

- REP_SPRAY suppresses monster detection and LIFE_AMULET absorbs one capture (consumed, signals UI).
  Checks clean; `_test_survival` passes.
- Ready for M20 (Stealth & Hiding polish) — which refines furniture hiding and balcony safe zones already
  implied by the detection rules.

> **Next:** M20 — Stealth & Hiding. Awaiting confirmation to author the next milestone section.

## M20 — Stealth & Hiding

### Overview

- **Objective:** Make the stealth rules from `docs/gameplay-summary.md` §5 fully functional. Two parts:
  (1) **Furniture hiding** — already toggles the player's hidden state on interact (M8); this milestone
  confirms it suppresses monster detection and documents the contract. (2) **Balcony safe zones** — the
  player standing on a balcony room is never detected or chased (monsters "never follow", per §5).
- **Expected result:** `Furniture.interact` toggles `PlayerController.set_hidden`; `Monster._physics_process`
  skips detection when the player is hidden **or** on a balcony (`player.on_balcony`). `FloorPlaceholder`
  updates `player.on_balcony` each frame from `FloorLayout.is_balcony_at(tile)`. A safe zone also makes a
  chasing monster give up (SEARCH→RETURN→PATROL).
- **Systems involved:** Stealth (M8), Player (M5), Monster AI (M17), Generation/Layout (M11), Rooms (M12),
  FloorPlaceholder (M2).
- **Dependencies:** M8 (Furniture hidden toggle), M17 (would_detect respects player_hidden), M11/M12
  (balcony rooms in layout), M5 (Player.on_balcony flag).
- **Estimated complexity:** S (wiring + one layout query; no new scenes).
- **Implementation risks:** Balcony membership is computed per-frame from tile position vs balcony rects —
  cheap (≤30 rooms). A chasing monster on a balcony boundary gives up within one search cycle (acceptable).
- **Validation requirements:** Hidden player is not detected; balcony player is not detected; furniture
  toggles hidden on/off; lint/format/parse clean; `_test_stealth` passes.
- **Note:** Balconies as a one-way out-of-bounds exit (§5) is deferred — out-of-bounds travel needs the
  real TileMap (M26) and is not part of this milestone.

### Task M20.T1 — Furniture Hiding Contract

- **Purpose:** Lock in that hiding in furniture makes the player undetectable.
- **Reason:** §5 states monsters lose line-of-sight on a hidden player; the toggle exists (M8) but the
  detection contract is only implicitly covered by M17's `would_detect(player_hidden)`.
- **Prerequisites:** M8 (Furniture), M17 (detection), M5 (Player.set_hidden).
- **Files likely affected:** `scripts/furniture.gd` (no change expected; verified), `scripts/main.gd` (test).
- **Systems affected:** Stealth, Monster AI, Interaction.
- **Possible risks:** None — pure verification + test; `would_detect` already returns false when hidden.
- **Testing checklist:**
  - [x] `Furniture.interact(player)` toggles `player.is_hidden()` true then false.
  - [x] A close, lit, hidden player is not detected (monster stays PATROL).
- **Definition of Done:** Furniture hiding is a verified stealth mechanic.
- **Future extensibility:** M22 adds the hide/exit prompt + vignette; M24 shows "hidden" indicator.

**Atomic Steps:**
1. Add `_test_stealth` covering furniture toggle + hidden-detection; no source change required.

### Task M20.T2 — Balcony Safe Zone

- **Purpose:** Monsters never detect/chase a player standing on a balcony.
- **Reason:** §5 makes balconies bright, safe monster-free zones with guaranteed loot.
- **Prerequisites:** M11/M12 (balcony rooms), M17 (Monster detection), M2 (FloorPlaceholder loop).
- **Files likely affected:** `scripts/floor_layout.gd` (add `is_balcony_at`), `scripts/player_controller.gd`
  (add `on_balcony`), `scripts/monster.gd` (skip detection on balcony), `scripts/floor_placeholder.gd`
  (update `on_balcony` each frame).
- **Systems affected:** Generation, Player, Monster AI, Floor flow.
- **Possible risks:** Per-frame rect test is O(rooms); negligible. Boundary case: a chasing monster that
  steps onto a balcony gives up (desired).
- **Testing checklist:**
  - [x] `FloorLayout.is_balcony_at` true inside a balcony rect, false elsewhere.
  - [x] A close, lit, balcony player is not detected (monster stays PATROL).
  - [x] `FloorPlaceholder._process` sets `player.on_balcony` from layout.
- **Definition of Done:** Balconies are monster-safe.
- **Future extensibility:** M26 ties safe zones to real tile collision; M22 adds moonlight/fX feedback.

### M20 Exit Criteria

- Hiding in furniture and standing on a balcony both suppress monster detection (verified by
  `_test_stealth`); `on_balcony` is tracked per frame. Checks clean.
- Ready for M21 (Lighting & Danger Sense) — which adds the red aura/feedback and ties lamp-off stealth
  (already in `would_detect`) to the HUD.

> **Next:** M21 — Lighting & Danger Sense. Awaiting confirmation to author the next milestone section.

## M21 — Lighting & Danger Sense

### Overview

- **Objective:** Two player-facing threat cues. (1) **Danger Sense** — when the player owns the Danger
  Sense item, a per-frame signal reports the direction toward the nearest monster so the HUD can draw the
  red edge aura (docs/gameplay-summary.md §7, docs/items.md). (2) **Lighting cues** — the existing
  LightingSystem already modulates ambient darkness + Blood Mode tint (M7); lamp-off stealth already
  lives in `Monster.would_detect` (M17). M21 adds the monster-direction signal and documents that the
  red flash / vignette / aura *rendering* is the HUD's job (M22).
- **Expected result:** `DangerSense` (autoload) scans the `monster` group each frame; if the player owns
  DANGER_SENSE it emits `SignalBus.danger_sense_updated(direction)` (unit vector toward nearest monster,
  `Vector2.ZERO` when inactive/none). `Monster` joins the `monster` group on spawn. A pure helper
  `DangerSense.nearest_monster_direction` is unit-testable.
- **Systems involved:** Danger Sense (new), Monster (M17), Inventory (M9), SignalBus, Lighting (M7),
  Generation (M11).
- **Dependencies:** M17 (monsters + detection), M9 (DANGER_SENSE flag set by ItemManager.use), M7
  (lighting already in place). The DANGER_SENSE item is sold by the merchant (M18) and granted via
  `ItemManager.use` (M10).
- **Estimated complexity:** S (one autoload + group + signal; logic only, no new scenes).
- **Implementation risks:** None material; the scan is O(monsters) per frame. Visual rendering deferred.
- **Validation requirements:** `nearest_monster_direction` picks the closest; the autoload emits only when
  owned and points at the monster; lint/format/parse clean; `_test_danger_sense` passes.
- **Note:** Danger Sense *duration* conflict (C9: 0.5s vs 60s) is irrelevant here — ownership is a flag
  set on use and persists; M24/M22 may later gate the aura by a timer if balancing requires it.

### Task M21.T1 — Danger Sense Signal

- **Purpose:** Publish the nearest-monster direction for the HUD.
- **Reason:** §7 lists Danger Sense as a red aura toward the nearest monster; the direction must come
  from a system, not the HUD guessing.
- **Prerequisites:** M17 (monsters), M9 (DANGER_SENSE flag), M10 (use sets the flag).
- **Files likely affected:** `scripts/danger_sense.gd` (new autoload), `scripts/signal_bus.gd` (signal),
  `scripts/monster.gd` (join `monster` group), `project.godot` (autoload).
- **Systems affected:** Danger Sense, Monster, SignalBus.
- **Possible risks:** Autoload must find both player (`player` group) and monsters (`monster` group);
  both groups now exist (player since M17, monster added here).
- **Testing checklist:**
  - [x] `nearest_monster_direction` returns the unit vector to the closest monster, `ZERO` if none.
  - [x] Autoload emits `ZERO` when DANGER_SENSE not owned; emits toward monster when owned.
  - [x] `DangerSense` registered as autoload; `Monster` in the `monster` group.
- **Definition of Done:** HUD has a reliable direction source for the Danger Sense aura.
- **Future extensibility:** M22 renders the red edge aura from `danger_sense_updated`; M24 can fade it.

**Atomic Steps:**
1. Implement `DangerSense` autoload + pure helper; add `danger_sense_updated` to SignalBus; add monsters
   to the `monster` group; register the autoload in `project.godot`.

### Task M21.T2 — Lighting Cue Contract

- **Purpose:** Confirm the lighting/stealth basis the aura sits on.
- **Reason:** The "Lighting" half of the milestone — lamp-off reduces detection (M17) and the CanvasModulate
  ambient (M7) already drive the mood; M21 just records the contract and defers the visual flash to M22.
- **Prerequisites:** M7 (LightingSystem), M17 (would_detect lamp-off branch).
- **Files likely affected:** `docs/roadmap.md` (contract note), `scripts/main.gd` (test).
- **Systems affected:** Lighting, Monster AI.
- **Possible risks:** None — documentation + the already-passing detection tests cover lamp-off stealth.
- **Testing checklist:**
  - [x] (Covered by M17 `_test_monsters`: lamp-off hearing-only detection.)
- **Definition of Done:** Lighting/stealth contract is explicit; aura source ready.
- **Future extensibility:** M22 adds red border flash on `monster_spotted_player` and vignette pulse.

### M21 Exit Criteria

- `DangerSense` emits the nearest-monster direction only when DANGER_SENSE is owned; `Monster` is in the
  `monster` group. Lamp-off stealth and Blood Mode tint already exist. Checks clean; `_test_danger_sense`
  passes.
- Ready for M22 (HUD & Feedback) — which renders the Danger Sense aura, red flash on spot, heartbeat and
  lamp-oil/coin readouts from these signals.

> **Next:** M22 — HUD & Feedback. Awaiting confirmation to author the next milestone section.

## M22 — HUD & Feedback

### Overview

- **Objective:** A heads-up display that renders the run state and the threat cues emitted by earlier
  milestones. Per `docs/gameplay-summary.md` §11 and `docs/ui.md`: coin counter (top-right), lamp-oil +
  energy (top-left), active artifacts, the Danger Sense edge aura (`danger_sense_updated`), a red flash
  on `monster_spotted_player`, and a heartbeat pulse. The HUD listens to `SignalBus` only — UI is
  separated from game logic (docs/architecture.md §7).
- **Expected result:** `HUD` (`CanvasLayer`, autoload-free scene node) wired into `FloorPlaceholder`,
  replacing the old single debug `Label`. It subscribes to `coins_changed`, `lamp_oil_changed`,
  `energy_changed`, `lamp_toggled`, `danger_sense_updated`, `monster_spotted_player`,
  `monster_lost_player`, `heartbeat_triggered`, `player_state_changed` and `artifact_acquired`, and
  updates placeholder Labels/ColorRects. A `_sync_initial` pulls current state on spawn so values are
  correct even if the player emitted before the HUD connected.
- **Systems involved:** HUD (new), SignalBus, Inventory (M9), Player (M5), Danger Sense (M21), Monster
  (M17), FloorPlaceholder (M2).
- **Dependencies:** M21 (danger_sense_updated), M17 (spot/lost + heartbeat signals), M9 (coins/artifacts),
  M5 (energy/oil/state), M2 (FloorPlaceholder host scene).
- **Estimated complexity:** M.
- **Implementation risks:** Children `_ready` before the parent in Godot, so the player can emit spawn
  signals before the HUD connects — solved by `_sync_initial()` reading autoloads + the player group.
  Rendering is intentionally placeholder (Labels/ColorRects); real art is M28.
- **Validation requirements:** HUD reflects coins/oil/energy/floor/artifacts; danger aura + flash toggle
  with their signals; `_sync_initial` shows correct starting values. Lint/format/parse clean;
  `_test_hud` passes.
- **Note:** `ui.md` may specify an explicit artifact-icon layout; this milestone lists artifact names as
  text (icon layout deferred to M28).

### Task M22.T1 — HUD Scene & Bindings

- **Purpose:** A reusable HUD node bound to the gameplay signals.
- **Reason:** Closes the loop from "systems emit state" to "player can see state".
- **Prerequisites:** M21 (danger_sense_updated), M17 (spot/lost/heartbeat), M9 (coins/artifacts).
- **Files likely affected:** `scripts/hud.gd` (new), `scenes/HUD.tscn` (new), `scripts/floor_placeholder.gd`
  (host the HUD, drop the debug Label), `scenes/FloorPlaceholder.tscn` (instance HUD.tscn).
- **Systems affected:** HUD, Floor flow.
- **Possible risks:** `FloorPlaceholder._refresh` previously built a debug string; now it just calls
  `hud.set_floor`. HUD owns all other readouts via signals.
- **Testing checklist:**
  - [x] `HUD` subcribes to the documented signals and updates internal state + child nodes.
  - [x] `danger_sense_updated` toggles the aura visibility; `monster_spotted/lost` toggles the flash.
  - [x] `_sync_initial` reads coins/artifacts/energy/oil from autoloads + player on spawn.
  - [x] `FloorPlaceholder` instances `HUD.tscn` and no longer tracks stats itself.
- **Definition of Done:** The floor shows a live HUD.
- **Future extensibility:** M28 swaps Labels/ColorRects for real art; M23 Main Menu reuses HUD bits.

**Atomic Steps:**
1. Implement `HUD` + `HUD.tscn`; replace the debug Label in `FloorPlaceholder`/`FloorPlaceholder.tscn`
   with the HUD; add `_test_hud`.

### Task M22.T2 — Feedback Cues

- **Purpose:** Render the threat feedback the design calls for.
- **Reason:** §11 lists monster alert (red vignette/flash), directional Danger Sense aura, heartbeat.
- **Prerequisites:** M21 (danger direction), M17 (spot/lost/heartbeat signals).
- **Files likely affected:** `scripts/hud.gd` (aura/flash handling), `scenes/HUD.tscn` (overlay nodes).
- **Systems affected:** HUD, Monster, Danger Sense.
- **Possible risks:** Placeholder overlays are simple ColorRects; the directional aura is shown as a
  visible indicator rather than a true edge gradient (M28 art). Acceptable for the placeholder.
- **Testing checklist:**
  - [x] Spotting shows the flash overlay; losing the player hides it.
  - [x] Danger Sense direction drives the aura indicator; zero direction hides it.
  - [x] `_test_hud` (coins/oil/energy/floor/artifacts/aura/flash).
- **Definition of Done:** Threat feedback is visible from the emitted signals.
- **Future extensibility:** M28 adds the real red border flash + vignette pulse + audible heartbeat.

### M22 Exit Criteria

- `HUD` + `HUD.tscn` render coins, oil, energy, floor, artifacts, the Danger Sense aura and the spot
  flash from signals; `FloorPlaceholder` hosts it. Checks clean; `_test_hud` passes.
- Ready for M23 (Main Menu & Flow) — which adds the menu/intro/ending scenes around the floor flow and
  the "Continue" button that loads `SaveManager`.

> **Next:** M23 — Main Menu & Flow. Awaiting confirmation to author the next milestone section.

## M23 — Main Menu & Flow

### Overview

- **Objective:** A real main menu that drives the run: **New Game** (always), **Continue** (only when a
  save exists, via `SaveManager`), and **Exit**. The boot scene runs the self-tests and then hands off to
  this menu. Game Over returns to the menu. The ending (roof) scene already exists (`EndingPlaceholder`)
  and is reached by beating floor 7; it returns to the menu on confirm.
- **Expected result:** `MainMenu` (`Control` + buttons) calls `GameManager.start_game()` / `continue_game()`.
  `GameManager.continue_game()` restores the run via `SaveManager.load_game()` then loads the floor.
  `FloorPlaceholder` connects `SignalBus.game_over` → `GameManager.return_to_menu`, closing the loop.
  `Config.SCENE_MAIN_MENU` now points at `MainMenu.tscn`; the boot `Main.tscn` transitions into it after
  the self-tests (`SceneLoader.change_scene`).
- **Systems involved:** Main Menu (new), Scene flow (M3), Save (M16), GameManager (M3), SceneLoader (M3),
  Ending (M3 placeholder).
- **Dependencies:** M16 (SaveManager.load_game/has_save), M3 (GameManager/SceneLoader), M22 (HUD shown on
  floors, not the menu).
- **Estimated complexity:** M.
- **Implementation risks:** `change_scene` frees the current scene — the boot scene intentionally defers
  its own free (queue_free is end-of-frame) so self-tests complete first. `game_over` scene-swap is owned
  by `FloorPlaceholder` (alive only during play), so the boot self-tests that emit `player_caught` never
  trigger a swap. Continue restores seed/floor + opened IDs (covered by M16).
- **Validation requirements:** Continue disabled without a save, enabled with one; buttons wired to
  start/continue/exit; `continue_game` restores the run; Game Over → menu. Lint/format/parse clean;
  `_test_menu` passes.
- **Note:** Intro cutscene (boy walks to castle) and the rainy-forest art are deferred to M28; the menu is
  a functional placeholder. Ending is `EndingPlaceholder` (M3) and already returns to menu.

### Task M23.T1 — Main Menu Scene

- **Purpose:** A menu that starts a new run or resumes a saved one.
- **Reason:** Replaces the boot-time "press Enter to start" hack with a proper entry point (docs/ui.md,
  docs/architecture.md §5 scene flow).
- **Prerequisites:** M16 (SaveManager), M3 (GameManager/SceneLoader).
- **Files likely affected:** `scripts/main_menu.gd` (new), `scenes/MainMenu.tscn` (new),
  `scripts/config.gd` (`SCENE_MAIN_MENU` → MainMenu.tscn), `scripts/main.gd` (boot → menu handoff),
  `scripts/game_manager.gd` (`continue_game`).
- **Systems affected:** Main Menu, Game flow, Save.
- **Possible risks:** Continue must reflect save presence live (disabled when none). Handled in `_refresh`.
- **Testing checklist:**
  - [x] `MainMenu` Continue disabled with no save, enabled with a save.
  - [x] Play/Continue/Exit buttons are wired (pressed connections present).
  - [x] `GameManager.continue_game` resumes via `SaveManager.load_game`.
  - [x] `Config.SCENE_MAIN_MENU` points at `MainMenu.tscn`; boot hands off after self-tests.
- **Definition of Done:** The game has a proper menu with New Game / Continue / Exit.
- **Future extensibility:** M28 adds forest/rain art + intro cutscene; M24 adds settings from the menu.

**Atomic Steps:**
1. Implement `MainMenu` + `MainMenu.tscn`; add `GameManager.continue_game`; point `SCENE_MAIN_MENU` at it;
   make the boot scene transition into it after self-tests; add `_test_menu`.

### Task M23.T2 — Flow Closure

- **Purpose:** Close the scene-flow loop (menu ↔ floor ↔ ending ↔ menu, and Game Over → menu).
- **Reason:** docs/architecture.md §5 flow: any floor → Game Over → Main Menu; Ending → Menu.
- **Prerequisites:** M23.T1, M3 (return_to_menu), M16 (save).
- **Files likely affected:** `scripts/floor_placeholder.gd` (`game_over` → `return_to_menu`),
  `scripts/ending_placeholder.gd` (already returns to menu on confirm).
- **Systems affected:** Game flow, SceneLoader.
- **Possible risks:** `game_over` swap is owned by `FloorPlaceholder` so it never fires during boot tests.
- **Testing checklist:**
  - [x] `FloorPlaceholder` connects `game_over` → `GameManager.return_to_menu`.
  - [x] Ending already returns to menu; win flow (M3 `_win`) reaches `EndingPlaceholder`.
- **Definition of Done:** Full menu-driven loop; Game Over returns to the menu.
- **Future extensibility:** M28 adds a Game Over overlay (red screen) before the menu.

### M23 Exit Criteria

- `MainMenu` offers New Game / Continue (save-gated) / Exit; `continue_game` resumes runs; Game Over and
  the ending both return to the menu; the boot scene runs self-tests then shows the menu. Checks clean;
  `_test_menu` passes.
- Ready for M24 (Settings & Pause) — which adds a pause menu (Esc) with resume/settings/quit and the
  options exposed by Config.

> **Next:** M24 — Settings & Pause. Awaiting confirmation to author the next milestone section.

---

## M24 — Settings & Pause

### Overview

- **Objective:** Add an Esc-driven pause overlay during play and a settings overlay (reachable
  from both the pause menu and the main menu) that controls audio bus volumes. Pausing freezes
  the scene tree and disables gameplay input; the overlays stay live via `PROCESS_MODE_WHEN_PAUSED`.
  Volume choices persist to `user://settings.json` through `SettingsManager`.
- **Expected result:** Pressing `pause` during `State.PLAYING` sets `State.PAUSED`, pauses
  `SceneTree`, disables gameplay input, and shows `PauseMenu` (Resume / Settings / Quit to Menu).
  Resume restores play. `SettingsMenu` sliders (Music / Ambient / SFX / UI) drive
  `SettingsManager`, which applies values through `AudioManager` and saves them. Reopening
  the game restores the saved volumes.
- **Systems involved:** Game flow (M3), Input (M4), Audio (M21 infra), UI (M22/Menu M23).
- **Dependencies:** M3 (GameManager/SceneLoader, state machine), M4 (InputReader `pause` +
  `gameplay_enabled`), M21 (AudioManager + bus constants), M23 (MainMenu host).
- **Estimated complexity:** M.

### Task M24.T1 — Pause Flow

- **Purpose:** Freeze gameplay and surface a pause overlay without coupling menus to entities.
- **Reason:** Horror pacing needs a reliable pause; `get_tree().paused` is the engine-native freeze.
- **Prerequisites:** M3 (GameManager, `State`), M4 (`just_paused`, `gameplay_enabled`),
  SignalBus already has `game_paused` / `game_resumed`.
- **Files likely affected:** `scripts/game_manager.gd` (add `PAUSED`, `pause`/`resume`/
  `open_settings`/`close_settings`), `scripts/input_reader.gd` (unchanged — `just_paused`
  is already ungated), `scripts/floor_placeholder.gd` (detect pause input),
  `scenes/FloorPlaceholder.tscn` (host `PauseMenu`/`SettingsMenu`),
  `scripts/pause_menu.gd` (new) + `scenes/PauseMenu.tscn` (new),
  `scripts/signal_bus.gd` (`settings_opened`/`settings_closed`).
- **Systems affected:** Game flow, Input, UI.
- **Possible risks:** Pause overlay frozen by the same `paused` flag — avoided with
  `process_mode = PROCESS_MODE_WHEN_PAUSED` on the overlay node. `return_to_menu` /
  `game_over` must unfreeze the tree (handled in `return_to_menu`). Settings opened
  from the pause menu must not double-pause (tracked via `_settings_open`).
- **Testing checklist:**
  - [x] `GameManager.pause()` only works from `PLAYING`; sets `PAUSED`, pauses tree,
        disables gameplay input, emits `game_paused`.
  - [x] `GameManager.resume()` restores `PLAYING`, unpauses, re-enables input, emits `game_resumed`.
  - [x] `PauseMenu` shows on `game_paused`, hides on `game_resumed`; Resume/Quit wired.
  - [x] `pause()` is a no-op outside `PLAYING` (menu/over states ignored).
  - [x] `_test_pause` covers the round-trip + signals.
- **Definition of Done:** Esc pauses and resumes play deterministically.
- **Future extensibility:** M25 difficulty could add a pause-time "abandon run" variant.

**Atomic Steps:**
1. Add `PAUSED` to `GameManager.State`; implement `pause()`/`resume()` (tree pause +
   `gameplay_enabled` toggle + signal emit); add `open_settings`/`close_settings` with
   `_settings_open` guard.
2. Implement `PauseMenu` (+`scenes/PauseMenu.tscn`) with `PROCESS_MODE_WHEN_PAUSED`;
   connect to `game_paused`/`game_resumed`; wire Resume/Settings/Quit.
3. In `FloorPlaceholder._process`, call `GameManager.pause()` on `just_paused()` (ignored
   while settings are open); host `PauseMenu` + `SettingsMenu` in the scene.

### Task M24.T2 — Settings & Persistence

- **Purpose:** Let the player tune audio and persist it across sessions.
- **Reason:** M21 built the buses + `AudioManager.set_bus_volume`; M24 exposes them to the UI.
- **Prerequisites:** M21 (`AudioManager` bus constants + `set_bus_volume`), autoload support.
- **Files likely affected:** `scripts/settings_manager.gd` (new) + autoload, `scripts/settings_menu.gd`
  (new) + `scenes/SettingsMenu.tscn` (new), `project.godot` (autoload), `scripts/main_menu.gd`
  (Settings button), `scenes/MainMenu.tscn` (host SettingsMenu), `scripts/signal_bus.gd`
  (`settings_opened`/`settings_closed`).
- **Systems affected:** Settings, Audio, UI.
- **Possible risks:** Slider spam writing the file every frame — acceptable for a placeholder
  (saved on each `value_changed`); real debounce is M28 polish.
- **Testing checklist:**
  - [x] `SettingsManager.set_volume` updates the cached value + applies via `AudioManager` + saves JSON.
  - [x] `load_settings` restores volumes on restart (round-trip via `save_settings`/`load_settings`).
  - [x] `SettingsMenu` sliders sync from `SettingsManager` on open; edits persist.
  - [x] Settings reachable from pause menu AND main menu; Back returns to the beneath menu.
  - [x] `_test_pause` covers volume persistence.
- **Definition of Done:** Volumes are tunable and survive a quit/relaunch.
- **Future extensibility:** Video settings (fullscreen, scale) and key-rebinding hook into the same
  overlay pattern; M28 adds real slider art.

**Atomic Steps:**
1. Implement `SettingsManager` (cached volumes, `set_volume`/`load_settings`/`save_settings`,
   `_apply_all`); register as autoload.
2. Implement `SettingsMenu` (+`scenes/SettingsMenu.tscn`) with four sliders bound to
   `SettingsManager`; add `settings_opened`/`settings_closed` signals; wire `GameManager.open_settings`/
   `close_settings` from Pause and MainMenu.
3. Add `_test_pause` (pause/resume round-trip + volume persistence) to the boot self-test.

### M24 Exit Criteria

- Esc pauses/resumes play (tree freeze + gameplay input off) with a Resume/Settings/Quit overlay;
  `pause()` is a no-op outside `PLAYING`.
- Settings overlay (Music/Ambient/SFX/UI) reachable from pause and main menu; volumes persist
  to `user://settings.json` and restore on launch.
- `AudioManager` bus constants consumed by `SettingsManager`; checks/self-test clean.
- Ready for M25 (Difficulty Modes) — which can reuse the pause/settings overlay for mode selection.

---

## M25 — Difficulty Modes

### Overview

- **Objective:** Implement the Blood Codex hard mode (docs call it the only "difficulty variant",
  ADR-009). Using the `CODEX_BLOOD` artifact (M10) activates Blood Mode for the rest of
  the run; M25 wires every documented effect: red texture tint (M7), faster/trickier monster
  detection, faster player fatigue (energy drain), ~40% rarer resources, and the **Bloodbringer**
  achievement on a win in this mode.
- **Expected result:** `Monster.would_detect` widens both detection and hearing radii by
  `BLOOD_MODE_DETECT_FACTOR` when Blood Mode is active; `PlayerController._update_energy`
  multiplies the drain by `BLOOD_MODE_ENERGY_FACTOR`; `LootPlacer.roll_loot` scales
  coins/food/oil down by `BLOOD_MODE_RESOURCE_FACTOR` (0.6 ≈ 40% rarer); `GameManager._win`
  calls `AchievementManager.unlock(BLOODBRINGER)` when `CODEX_BLOOD` is owned; `AchievementManager`
  persists unlocked ids to `user://achievements.json`.
- **Systems involved:** Monster AI (M17), Player (M5), Loot (M14), Save (M16),
  Lighting (M7), Inventory (M9), Items (M10), Game flow (M3).
- **Dependencies:** M20 (hide/balcony), M7 (tint), M17 (detection + blood speed), M14 (loot),
  M16 (save), M10 (CODEX_BLOOD use). M24 (Achievements) is the formal owner of the
  achievement UI; M25 introduces the minimal `AchievementManager` autoload it needs.
- **Estimated complexity:** M.
- **Implementation risks:** `would_detect` is a pure helper used by self-tests — adding a
  defaulted `blood_mode` parameter keeps the existing call sites valid. Resource scaling must
  not drop a chest to zero coins (floored at 1). The Bloodbringer award lives in `_win`
  which also swaps scenes — guarded so the unlock is idempotent.
- **Validation requirements:** Blood Mode widens detection; energy drains faster; loot scales down
  by the factor; win in Blood Mode unlocks Bloodbringer (persisted); lint/format/parse clean;
  `_test_difficulty` passes.
- **Note:** Difficulty here is the opt-in Blood Codex variant (per ADR-009), not a
  start-menu Easy/Normal/Hard selector. The pause/settings overlay (M24) is the natural
  home for a future explicit mode picker.

### Task M25.T1 — Blood Mode Effects

- **Purpose:** Make the Blood Codex artifact's documented effects real.
- **Reason:** Closes the gap between "you can buy the Codex" (M18) and "it actually changes
  the game" (gameplay.md §10). Detection + fatigue + scarcity were stubbed (TODO/BALANCE)
  but never wired.
- **Prerequisites:** M10 (CODEX_BLOOD flag + `blood_mode_toggled`), M7 (tint), M17
  (detection, `BLOOD_MODE_MONSTER_SPEED`), M14 (loot), Config constants.
- **Files likely affected:** `scripts/config.gd` (add `BLOOD_MODE_DETECT_FACTOR`,
  `BLOOD_MODE_ENERGY_FACTOR`), `scripts/monster.gd` (`would_detect` blood param + call
  site), `scripts/player_controller.gd` (`_update_energy` drain boost), `scripts/loot_placer.gd`
  (`roll_loot` blood param + `place` call site), `scripts/achievement_manager.gd` (new autoload).
- **Systems affected:** Monster AI, Player, Loot, Achievements.
- **Possible risks:** Detection boost phrasing ("detect quicker") ambiguous — modeled as a 1.5×
  radius multiplier (`TODO(BALANCE)`). Energy boost similarly 1.5× (`TODO(BALANCE)`).
- **Testing checklist:**
  - [x] `Monster.would_detect(..., blood_mode=true)` detects beyond the normal radius.
  - [x] `PlayerController._update_energy` drains ~1.5× faster with `CODEX_BLOOD` owned.
  - [x] `LootPlacer.roll_loot(..., blood_mode=true)` scales coins by `BLOOD_MODE_RESOURCE_FACTOR`.
  - [x] Monster still uses `BLOOD_MODE_MONSTER_SPEED` (done in M17).
- **Definition of Done:** Blood Mode is a measurable difficulty shift across detection/fatigue/loot.
- **Future extensibility:** M27 (Balancing) tunes the three factors; a start-menu mode picker
  (if ever desired) would set `CODEX_BLOOD` at run start.

**Atomic Steps:**
1. Add `BLOOD_MODE_DETECT_FACTOR` / `BLOOD_MODE_ENERGY_FACTOR` to `Config`; widen
   `Monster.would_detect` radii by the detect factor (defaulted `blood_mode` param); pass
   `InventoryManager.has_artifact(CODEX_BLOOD)` from `_physics_process`.
2. Multiply `PlayerController._update_energy` drain by the energy factor when `CODEX_BLOOD` owned.
3. Scale `LootPlacer.roll_loot` coins/food/oil by `BLOOD_MODE_RESOURCE_FACTOR`;
   thread `blood_mode` from `place`.

### Task M25.T2 — Bloodbringer Achievement

- **Purpose:** Award + persist the Bloodbringer achievement on a Blood-Mode win.
- **Reason:** gameplay.md §10 + project.md name it; without M24's full achievement UI, M25 ships
  the minimal `AchievementManager` (unlock/has/persist) the later UI builds on.
- **Prerequisites:** M10 (CODEX_BLOOD), M3 (`_win`), SignalBus.
- **Files likely affected:** `scripts/achievement_manager.gd` (new), `scripts/signal_bus.gd`
  (`achievement_unlocked`), `scripts/game_manager.gd` (`_win` unlock), `project.godot` (autoload).
- **Systems affected:** Achievements, Game flow.
- **Possible risks:** `_win` also swaps to the ending scene — the unlock must fire before/independent
  of the swap and be idempotent (re-completing does not re-emit).
- **Testing checklist:**
  - [x] `AchievementManager.unlock(BLOODBRINGER)` sets `has` + emits `achievement_unlocked`
        + persists to `user://achievements.json`; re-unlock is a no-op.
  - [x] `_win` with `CODEX_BLOOD` owned unlocks Bloodbringer (verified via the manager + signal).
- **Definition of Done:** A Blood-Mode completion is recorded and survives restart.
- **Future extensibility:** M24 renders the unlock as a toast/badge from `achievement_unlocked`.

**Atomic Steps:**
1. Implement `AchievementManager` (cached dict, `unlock`/`has`/`get_all`, JSON persist) +
   `achievement_unlocked` signal; register autoload.
2. In `GameManager._win`, `AchievementManager.unlock(BLOODBRINGER)` when `CODEX_BLOOD` owned.
3. Add `_test_difficulty` (detection / fatigue / loot / Bloodbringer) to the boot self-test.

### M25 Exit Criteria

- Blood Mode widens monster detection, speeds player fatigue, and thins loot by the documented
  factors; all driven by `Config` constants. `CODEX_BLOOD` use (M10) is the activation path.
- A win while `CODEX_BLOOD` is owned unlocks **Bloodbringer** (persisted via `AchievementManager`);
  the unlock is idempotent. Checks/self-test clean.
- Ready for M26 (Optimization) — which can short-circuit per-mode work using the same flags.

---

## M26 — Optimization

### Overview

- **Objective:** Reduce per-frame cost on large procedural floors without changing gameplay.
  Two targeted, testable optimizations: (1) **monster AI proximity gate** — idle
  (PATROL/RETURN) monsters beyond `MONSTER_AI_RANGE_TILES` skip the vision-cone detection
  math (detection radius 8 + hearing 4 are both < 12, so correctness is preserved); chasing
  monsters always run. (2) **room/corridor visibility culling** — `FloorPlaceholder` toggles
  `CanvasItem.visible` on rooms/corridors outside the camera's grown visible rect, cutting
  draw + visibility work. Atlased tilesets (M12/M28), single-light budget, and `queue_free`
  node lifecycle are already satisfied from earlier milestones.
- **Expected result:** `_physics_process` on a 30-room, 8-monster floor does meaningfully less
  detection + draw work for off-screen/off-range entities. A pure `Optimizer.rect_visible`
  helper and `Monster.is_far_idle` gate make the gains unit-testable without the engine profiler.
- **Systems involved:** Monster AI (M17), Rooms (M12), Floor flow (M2), Config.
- **Dependencies:** all gameplay/rendering (the milestone explicitly aggregates them).
- **Estimated complexity:** M.
- **Implementation risks:** The gate must never skip a CHASE/SEARCH monster (it doesn't —
  only PATROL/RETURN are gated). Culling is purely visual (`.visible`) and never hides the
  player/HUD/lighting (they live outside `_rooms`). The camera-rect query is cheap
  (`Camera2D.get_viewport_rect` + `Rect2.intersects`).
- **Validation requirements:** `is_far_idle` returns true only for idle-and-far; far idle
  monsters stay PATROL across `_physics_process`; near monsters chase as before;
  `Optimizer.rect_visible` is correct for overlapping/far/margin cases; lint/format/parse clean;
  `_test_optimization` passes.

### Task M26.T1 — Monster AI Proximity Gate

- **Purpose:** Skip the expensive `would_detect` cone math for monsters that cannot detect anyway.
- **Reason:** On a floor with 8 monsters, only those near the player need vision checks; the rest
  idle-roam and can't detect (detection radius < AI range). This is the single biggest per-tick
  saving on large floors.
- **Prerequisites:** M17 (detection + state machine), Config.
- **Files likely affected:** `scripts/config.gd` (`MONSTER_AI_RANGE_TILES`), `scripts/monster.gd`
  (gate in `_physics_process`, pure `is_far_idle` helper).
- **Systems affected:** Monster AI.
- **Testing checklist:**
  - [x] `Monster.is_far_idle` true for PATROL/RETURN beyond range; false for CHASE/SEARCH at any distance.
  - [x] A far idle monster stays PATROL across `_physics_process` (no detection run).
  - [x] A near monster still chases as before.
- **Definition of Done:** Idle monsters far from the player skip detection without changing behavior.
- **Future extensibility:** M27 (Balancing) can tune `MONSTER_AI_RANGE_TILES` per difficulty.

**Atomic Steps:**
1. Add `Config.MONSTER_AI_RANGE_TILES` (> detection + hearing). Gate `_physics_process` so idle
   monsters beyond it skip `would_detect`; add the pure `is_far_idle` helper.

### Task M26.T2 — Room/Corridor Visibility Culling

- **Purpose:** Don't draw or visibility-process rooms/corridors the camera can't see.
- **Reason:** `CanvasItem.visible = false` short-circuits draw + `_draw` traversal for off-screen
  floor nodes on large generated layouts.
- **Prerequisites:** M12 (rooms/corridors as children of `_rooms`), M2 (FloorPlaceholder loop).
- **Files likely affected:** `scripts/optimizer.gd` (new pure helper), `scripts/floor_placeholder.gd`
  (`_cull_rooms` in `_process`).
- **Systems affected:** Rooms, Rendering.
- **Possible risks:** Culling is purely visual; player/HUD/lighting live outside `_rooms` so are
  never hidden. The camera-rect query is O(1); the per-room `get_global_rect` + `intersects` is
  O(rooms) per frame (~30), negligible.
- **Testing checklist:**
  - [x] `Optimizer.rect_visible` true for overlapping rects, false for far rects, true within margin.
- **Definition of Done:** Off-screen rooms/corridors are not drawn.
- **Future extensibility:** A spatial hash / y-sort cull could replace the O(rooms) scan for very
  large floors; the current scan is sufficient for 30-room placeholders.

**Atomic Steps:**
1. Implement `Optimizer.rect_visible(world_rect, cam_rect, margin)` (pure, `Rect2.grow` + `intersects`).
2. In `FloorPlaceholder._process`, call `_cull_rooms` which toggles each `_rooms` child's `.visible`
   via `Optimizer.rect_visible(child.get_global_rect(), cam.get_viewport_rect())`.

### Task M26.T3 — Self-Test

- **Purpose:** Gate the gains without a profiler.
- **Reason:** No engine runtime in CI; pure helpers + behavior assertions catch regressions.
- **Prerequisites:** M26.T1, M26.T2.
- **Files likely affected:** `scripts/main.gd` (`_test_optimization`).
- **Testing checklist:**
  - [x] `is_far_idle` pure cases; far idle stays PATROL; near chases; `rect_visible` cases.
- **Definition of Done:** `_test_optimization` passes; CI green.

**Atomic Steps:**
1. Add `_test_optimization` to the boot self-test (gate helper, behavior, visibility helper).

### M26 Exit Criteria

- Idle monsters beyond the AI range skip detection (correctness preserved); chasing monsters
  always run. Off-screen rooms/corridors are not drawn. Pure helpers + behavior are self-tested.
  Atlased tilesets, single-light budget, and `queue_free` lifecycle already satisfied.
- Ready for M27 (Balancing) — which tunes the factors M25/M26 introduced.

---

## M27 — Balancing

### Overview

- **Objective:** Make all gameplay tunables data-driven and resolve the provisional
  `TODO(BALANCE)` values that have accumulated since M1. Introduce a `BalancingConfig`
  Godot `Resource` (`scripts/balancing_config.gd`) as the single editable source of truth,
  with a default instance at `res://config/balancing.tres`. The `Config` autoload loads it in
  `_init()` and mirrors the values into its static fields, so gameplay code keeps calling
  `Config.X` unchanged — rebalancing edits the `.tres`, never the code (per the chosen
  data-driven approach; see `docs/decisions.md` ADR-018).
- **Expected result:** Every numeric gameplay value is editable in one place without touching
  gameplay scripts; the previously unresolved conflict values are now deliberate, documented
  decisions; no `TODO(BALANCE)` markers remain; the boot self-test asserts the invariants.
- **Systems involved:** Config (all readers), Loot (oil ratio), Monster (detection factors),
  Player (energy), Generation. Blood Mode remains the only difficulty (ADR-009).
- **Dependencies:** M25 (Blood Mode factors), M26 (AI range). No new gameplay behavior.
- **Estimated complexity:** L.
- **Implementation risks:** Converting `Config` `const`s to `static var` must not break call
  sites (e.g. instance-var initializers in `player_controller.gd` that read `Config.X` — valid
  because `Config` is an autoload ready before instance construction). The `.tres` must be
  parseable and its `script_class` must match `BalancingConfig`. Fallback literals keep the game
  runnable if the `.tres` is missing.
- **Validation requirements:** `Config.balancing` loads and mirrors; invariants hold
  (`MONSTER_AI_RANGE_TILES > detection + hearing`, lamp-off factor ∈ (0,1), blood multipliers ≥ 1
  and resource factor ∈ (0,1), loot ratio ∈ [0,1]); zero `TODO(BALANCE)` in code; `_test_balancing`
  passes.

### Task M27.T1 — BalancingConfig Resource

- **Purpose:** Externalize all tunables into an editable `.tres`.
- **Reason:** Designers/balancers must tune the game without editing `.gd` files; a single
  Resource is the Godot-idiomatic store and supports future balancing passes with no refactor.
- **Prerequisites:** M1 (Config), the conflict resolutions in `docs/decisions.md`.
- **Files likely affected:** `scripts/balancing_config.gd` (new), `config/balancing.tres` (new),
  `scripts/config.gd` (load + mirror).
- **Systems affected:** Config (all consumers).
- **Possible risks:** If a `.gd` used a balancing `const` as a default *parameter* value, moving
  it to a `static var` would break (default args must be constant). Verified: no such usage
  exists — only instance-var initializers and runtime reads, both safe.
- **Testing checklist:**
  - [x] `Config.balancing` is a loaded `BalancingConfig` (not null).
  - [x] `Config.PLAYER_MOVE_SPEED` etc. equal the resource's values (mirrored).
  - [x] Missing `.tres` falls back to literal defaults without error.
- **Definition of Done:** All tunables live in `balancing.tres`; gameplay is unchanged at runtime.
- **Future extensibility:** A debug toggle could hot-swap `Config.balancing` at runtime; the
  resource is already structured for per-difficulty variants if ever desired.

**Atomic Steps:**
1. Create `scripts/balancing_config.gd` (`class_name BalancingConfig extends Resource`) with
   `@export` properties for every tunable (player, lantern, monster AI, food, artifacts,
   generation, loot ratio), each with the current value as its default.
2. Create `res://config/balancing.tres` with `script_class="BalancingConfig"` populated with the
   current values (behavior unchanged on first load).
3. In `scripts/config.gd`, replace the balancing `const`s with `static var`s (literal = fallback),
   add `static var balancing: BalancingConfig` + `const BALANCING_PATH`, and add `_init()` →
   `_load_balancing()` that `load`s the `.tres` (or `BalancingConfig.new()` on failure) and mirrors
   every property into the matching `static var`.

### Task M27.T2 — Resolve TODO(BALANCE) Values

- **Purpose:** Turn provisional conflict values into deliberate, documented decisions.
- **Reason:** Ambiguous values (lamp-off factor, lantern radius, cloak uses, Blood Mode factors,
  loot oil ratio, Danger Sense duration) were stubbed with `TODO(BALANCE)`; the docs
  (`balancing.md`, ADR-016) now supply the answers.
- **Prerequisites:** M27.T1, ADR-016 (Danger Sense permanent).
- **Files likely affected:** `scripts/config.gd` (remove `DANGER_SENSE_DURATION` + strip TODO
  markers), `scripts/monster.gd` (update header comment), `scripts/loot_placer.gd` (read
  `Config.LOOT_OIL_SMALL_RATIO`), `docs/decisions.md` (ADR-018).
- **Systems affected:** Config, Loot, Monster, Player.
- **Possible risks:** `DANGER_SENSE_DURATION` was already dead (Danger Sense is a permanent flag
  per ADR-016); removing it is safe. All other chosen values match `balancing.md` / `monster.md`.
- **Testing checklist:**
  - [x] No `TODO(BALANCE)` string remains in `config.gd`, `monster.gd`, `loot_placer.gd`.
  - [x] `loot_placer` uses `Config.LOOT_OIL_SMALL_RATIO` (4:1 small:large).
  - [x] ADR-018 records every resolved value.
- **Definition of Done:** Zero unresolved balancing TODOs; decisions recorded.
- **Future extensibility:** Tuning passes edit only `balancing.tres`.

**Atomic Steps:**
1. Strip every `TODO(BALANCE)` comment; remove the dead `DANGER_SENSE_DURATION` constant.
2. In `loot_placer.gd`, replace the hardcoded `0.8` oil ratio with `Config.LOOT_OIL_SMALL_RATIO`
   and update the comment.
3. Add ADR-018 to `docs/decisions.md` listing each resolved value and its rationale.

### Task M27.T3 — Self-Test

- **Purpose:** Lock the invariant contract of the balancing layer.
- **Reason:** No engine runtime in CI; assertions catch a broken `.tres` or a regressed mirror.
- **Prerequisites:** M27.T1, M27.T2.
- **Files likely affected:** `scripts/main.gd` (`_test_balancing`).
- **Testing checklist:**
  - [x] Resource loads; values mirrored; invariants hold; no `TODO(BALANCE)` remain.
- **Definition of Done:** `_test_balancing` passes; CI green.

**Atomic Steps:**
1. Add `_test_balancing` to the boot self-test: assert `Config.balancing` is a loaded
   `BalancingConfig`; mirrored values match; `MONSTER_AI_RANGE_TILES > detection + hearing`;
   `LAMP_OFF_DETECTION_FACTOR ∈ (0,1)`; Blood Mode multipliers ≥ 1 and resource factor ∈ (0,1);
   `LOOT_OIL_SMALL_RATIO ∈ [0,1]`; and `config.gd`/`monster.gd`/`loot_placer.gd` contain no
   `TODO(BALANCE)`.

### M27 Exit Criteria

- All gameplay tunables are data-driven via `BalancingConfig` (`res://config/balancing.tres`);
  `Config` mirrors them and gameplay code is unchanged. The provisional `TODO(BALANCE)` values are
  resolved and recorded in ADR-018 (lamp-off 0.5, lantern radius 5, cloak 1 use, Blood Mode
  detect 1.5× / energy 1.5× / speed 1.2×, loot oil 4:1, Danger Sense permanent). No `TODO(BALANCE)`
  markers remain; `_test_balancing` passes. Ready for M28 (Polishing).

---

## M28 — Polishing

### Overview

- **Objective:** A code-only "juice" pass (no external art assets). Wire the already-generated SFX
  into real feedback and add the deferred visual/UX polish: Danger Sense heartbeat audio + pulsing
  directional aura, detection flash with screen shake, a Game Over overlay, settings slider
  debounce, UI hover/confirm SFX, a menu intro/ambient animation, lantern flicker, and a dark
  Theme. Gameplay values and behavior are unchanged.
- **Expected result:** The game *feels* alive — the player hears the heartbeat when threatened,
  sees a red flash + shake when spotted, gets a proper Game Over screen, sliders no longer thrash
  disk, and menus have hover sounds and a cohesive dark look. Real final art remains a later pass.
- **Systems involved:** HUD (M22), Danger Sense (M21), GameManager flow, Settings (M24), Main Menu
  (M23), Pause Menu (M24), Lantern (M7), AudioManager, autoload ScreenShake (new).
- **Dependencies:** M26, M27. No new gameplay behavior.
- **Estimated complexity:** M.
- **Implementation risks:** The Game Over overlay must own the return-to-menu (the old
  `game_over → return_to_menu` connection in `floor_placeholder.gd` was removed so the floor isn't
  swapped before the player sees the feedback). Lantern flicker must be visual-only (detection uses
  `Config.LANTERN_RADIUS_TILES` independently, so flickering `texture_scale` is safe). Screen shake
  resets the camera offset to zero when trauma ends so the camera returns to its authored position.
- **Validation requirements:** `_test_polish` passes (overlay/HUD handlers run, ScreenShake callable,
  settings debounce API present); no new `TODO` stubs; (Godot editor) heartbeat audio, flash/shake
  on spot, Game Over overlay + sting, slider debounce, menu SFX/intro, lantern flicker.

### Task M28.T1 — Danger Sense Feedback

- **Purpose:** Make the Danger Sense aura and heartbeat real.
- **Reason:** The HUD had the nodes and signal handlers (M22) but the aura only toggled visibility
  and the heartbeat handler stored a value without playing audio or pulsing.
- **Prerequisites:** M21, M22, AudioManager (HEARTBEAT sfx generated).
- **Files likely affected:** `scripts/hud.gd`.
- **Systems affected:** HUD, AudioManager.
- **Possible risks:** Rotating the `ColorRect` aura around its top-left would orbit it; fix with
  `pivot_offset = size / 2`. Heartbeat can fire every frame when close — throttle with a cooldown.
- **Testing checklist:**
  - [x] `_on_heartbeat` plays `sfx_heartbeat` (throttled) and pulses the aura alpha.
  - [x] `_on_danger` rotates the aura toward `dir`.
- **Definition of Done:** Danger Sense gives audible + visual feedback toward the threat.
- **Future extensibility:** A dedicated vignette/node could deepen the pulse; art pass replaces the bar.

**Atomic Steps:**
1. In `hud.gd`, set `_danger.pivot_offset = size/2` in `_ready`; rotate `_danger` to `dir.angle()` in
   `_on_danger`. In `_on_heartbeat`, throttle `AudioManager.play_sfx(Sfx.HEARTBEAT)` via a cooldown
   and store a pulse value decayed each `_process` into `_danger.modulate.a`.

### Task M28.T2 — Detection Flash + Screen Shake

- **Purpose:** React to being spotted with a flash and shake.
- **Reason:** `_on_spotted` only toggled `$Flash.visible`; no feedback. Screen shake is reusable for
  Game Over.
- **Prerequisites:** M22, new ScreenShake autoload.
- **Files likely affected:** `scripts/hud.gd`, `scripts/screen_shake.gd` (new, autoload).
- **Systems affected:** HUD, rendering.
- **Possible risks:** Stacked tweens on repeated spots — kill the prior tween before starting a new
  one. Camera offset must reset when trauma ends.
- **Testing checklist:**
  - [x] `_on_spotted` tweens `$Flash` alpha and calls `ScreenShake.add_trauma`.
  - [x] ScreenShake decays and resets camera offset to zero.
- **Definition of Done:** Spotting is clearly felt, not just a label flip.

**Atomic Steps:**
1. Create `scripts/screen_shake.gd` (trauma-based camera offset) and register it as the `ScreenShake`
   autoload in `project.godot`.
2. In `hud.gd`, tween `$Flash` alpha `0→0.5→0` on spot (killing any prior tween) and call
   `ScreenShake.add_trauma(0.5)`; hide cleanly on `_on_lost`.

### Task M28.T3 — Game Over Overlay

- **Purpose:** A proper death screen instead of an instant menu swap.
- **Reason:** `GameManager.game_over()` emitted a signal but played no sting and showed nothing;
  `floor_placeholder.gd` returned to menu immediately.
- **Prerequisites:** M3, M19, AudioManager (GAME_OVER sfx generated).
- **Files likely affected:** `scripts/game_over_overlay.gd` + `scenes/GameOverOverlay.tscn` (new),
  `scripts/game_manager.gd`, `scripts/floor_placeholder.gd`.
- **Systems affected:** Game flow, UI, Audio.
- **Possible risks:** The overlay must own the return so the floor isn't freed before the feedback
  shows — remove the `game_over → return_to_menu` connection.
- **Testing checklist:**
  - [x] `game_over()` plays `sfx_game_over`, shakes, shows the overlay (which returns to menu).
  - [x] `floor_placeholder.gd` no longer returns to menu on `game_over`.
- **Definition of Done:** Death has a clear, skippable beat before the menu.

**Atomic Steps:**
1. Create `GameOverOverlay` (`CanvasLayer`, red fade-in + "YOU WERE CAUGHT", returns to menu after a
   delay or on input) and its scene.
2. In `GameManager.game_over`, disable gameplay input, play the sting, shake, emit, and show the
   overlay. Remove the `game_over → return_to_menu` connection in `floor_placeholder.gd`.

### Task M28.T4 — Settings Debounce

- **Purpose:** Stop sliders from writing JSON on every tick.
- **Reason:** `SettingsManager.set_volume` saved on every `value_changed` (roadmap flagged debounce
  as M28 polish).
- **Prerequisites:** M24, SettingsManager.
- **Files likely affected:** `scripts/settings_menu.gd`, `scripts/settings_manager.gd`.
- **Systems affected:** Settings persistence.
- **Possible risks:** Live audio must stay immediate; only the disk write is debounced.
- **Testing checklist:**
  - [x] Slider drag applies volume live via `set_volume_live`; JSON saved only after a short idle.
- **Definition of Done:** Dragging a slider no longer thrashes disk.

**Atomic Steps:**
1. Add `SettingsManager.set_volume_live` (apply + memorize, no save). In `settings_menu.gd`, call it
   on `value_changed` and debounce `save_settings()` via a one-shot `Timer` (~0.3s).

### Task M28.T5 — Menu UI Feedback + Intro

- **Purpose:** Menus feel responsive and atmospheric.
- **Reason:** Buttons had no SFX; the main menu had no intro/ambience (forest/rain art deferred).
- **Prerequisites:** M23, M24, AudioManager (UI_HOVER/UI_CONFIRM).
- **Files likely affected:** `scripts/main_menu.gd`, `scripts/pause_menu.gd`, `scripts/ui_sfx.gd` (new).
- **Systems affected:** UI, Audio.
- **Possible risks:** `focus_entered` fires on the initially-focused button — playing a hover on open
  is acceptable. The intro backdrop `ColorRect` must not block button input (`mouse_filter = IGNORE`).
- **Testing checklist:**
  - [x] Every menu button plays hover + confirm SFX.
  - [x] Main menu fades the title in over an animated dark backdrop.
- **Definition of Done:** Menus have sound and a simple intro without needing art assets.

**Atomic Steps:**
1. Add `scripts/ui_sfx.gd` with `bind_button` (hover/confirm SFX) and `apply_dark_theme`. Wire it in
   `main_menu.gd` and `pause_menu.gd`. In `main_menu.gd`, add an animated backdrop `ColorRect` and a
   title fade/slide-in tween.

### Task M28.T6 — Lantern Flicker

- **Purpose:** The lantern glow feels alive.
- **Reason:** `LanternLight` was a static radial light.
- **Prerequisites:** M7, Config.
- **Files likely affected:** `scripts/lantern_light.gd`.
- **Systems affected:** Lighting (visual only).
- **Possible risks:** Flicker must not change gameplay detection (which reads `Config` radius), so it
  only modulates the visual `texture_scale`/`color`.
- **Testing checklist:**
  - [x] `texture_scale`/`color` jitter while the lamp is on; detection unaffected.
- **Definition of Done:** Lantern flickers subtly without changing difficulty.

**Atomic Steps:**
1. In `lantern_light.gd`, store `_base_scale` in `_apply_radius` and add `_process` that jitters
   `texture_scale`/`color` by a small sine-based amount while `enabled`.

### Task M28.T7 — Theme Polish

- **Purpose:** Placeholder menus look less raw.
- **Reason:** Buttons/sliders used default engine styling.
- **Prerequisites:** M23, M24.
- **Files likely affected:** `scripts/ui_sfx.gd` (`apply_dark_theme`), menus.
- **Systems affected:** UI.
- **Possible risks:** Built at runtime (no `.tres` art) so it stays code-only and swappable.
- **Testing checklist:**
  - [x] Menus assign the dark Theme via `apply_dark_theme`.
- **Definition of Done:** A cohesive dark look across menus.

**Atomic Steps:**
1. In `ui_sfx.gd.apply_dark_theme`, build a `Theme` with `StyleBoxFlat` for `Button`/`HSlider` and
   assign it in `main_menu.gd` + `pause_menu.gd` + `settings_menu.gd`.

### Task M28.T8 — Self-Test + Docs

- **Purpose:** Lock the polish contract without a runtime profiler.
- **Reason:** No engine runtime in CI; smoke assertions catch broken scenes/handlers.
- **Prerequisites:** M28.T1–T7.
- **Files likely affected:** `scripts/main.gd` (`_test_polish`), `docs/roadmap.md`.
- **Testing checklist:**
  - [x] `_test_polish` passes; no new `TODO` stubs.
- **Definition of Done:** `main.gd` boots green including polish; M28 documented.

**Atomic Steps:**
1. Add `_test_polish`: GameOverOverlay loads (CanvasLayer), `ScreenShake.add_trauma` callable, HUD
   `_on_heartbeat`/`_on_spotted`/`_on_lost` run without error, settings debounce API present. Author
   this M28 section in `roadmap.md` (replacing the "Next" note).

### M28 Exit Criteria

- Danger Sense gives audible heartbeat + a pulsing, threat-pointing aura; spotting triggers a red
  flash + screen shake; death shows a Game Over overlay with a sting before returning to menu;
  settings sliders apply live and persist debounced; menus have hover/confirm SFX, a title intro
  over an animated backdrop, and a dark Theme; the lantern flickers visually without affecting
  detection. `_test_polish` passes; no new `TODO` stubs. Ready for M29 (Release Candidate).

---

## M29 — Release Candidate

### Overview

- **Objective:** Make the game shippable. Lock in a green full-run self-test, fix the last
  correctness gap (floor advance required reaching the stairs, ADR-015), add a release export
  preset, and finalize docs/versioning. No new gameplay features.
- **Expected result:** A boot self-test that drives a complete run to the win (and the Blood Codex
  variant), Game Over, and the Survival Amulet path; a Windows export preset; `v1.0.0-rc1`;
  README + roadmap reflecting RC.
- **Systems involved:** GameManager flow, FloorLayout/FloorPlaceholder, generation + all placers,
  AchievementManager, export/packaging, docs.
- **Dependencies:** M1–M28.
- **Estimated complexity:** L.
- **Implementation risks:** Driving the real flow inside the boot self-test would `SceneLoader`
  swap (and free) the boot node mid-`_ready`. Solved with a `GameManager.test_mode` seam that skips
  swaps but still updates state/signals/unlocks, so the automated test can run safely.
- **Validation requirements:** `_test_release` passes (pipeline for all floors + full state machine
  to win / Bloodbringer / Game Over / Amulet); floor advance requires the stairs tile; export
  preset present; no new `TODO` stubs; boot self-test fully green.

### Task M29.T1 — End-to-End Release Self-Test

- **Purpose:** Prove the whole game is completable and the flow is wired, automatically.
- **Reason:** Prior self-tests were unit-level; nothing exercised a full run through all 7 floors
  to the win, nor the Blood Codex unlock, Game Over, or Amulet paths together.
- **Prerequisites:** M3, M11–M18, M25.
- **Files likely affected:** `scripts/game_manager.gd` (`test_mode` seam), `scripts/main.gd` (`_test_release`).
- **Systems affected:** Game flow, generation, achievements.
- **Possible risks:** Scene swaps during the boot self-test free the boot node; `test_mode` avoids
  them. The pipeline test instantiates real entity scenes into a throwaway container (no swap).
- **Testing checklist:**
  - [x] Generation + build + all placers run for every floor without error.
  - [x] Normal run reaches `State.WON` after `FLOOR_COUNT` floors.
  - [x] Blood Codex win unlocks `Bloodbringer`.
  - [x] Catch without amulet → `GAME_OVER` → menu; amulet absorbs one hit.
- **Definition of Done:** A single boot self-test covers the entire game loop end to end.
- **Future extensibility:** `test_mode` is reusable for CI/headless playtests.

**Atomic Steps:**
1. Add `GameManager.test_mode`; guard the `SceneLoader.change_scene` calls in `_load_floor`,
   `_win`, `return_to_menu`, and the Game Over overlay so they skip swaps when `test_mode` is set.
2. Add `_test_release` to `main.gd`: run the full generation/population pipeline for all floors,
   then drive `start_game → advance_floor` to `WON`, a Blood Codex win asserting `Bloodbringer`,
   a Game Over → menu path, and the Survival Amulet absorb.

### Task M29.T2 — Stairs-Gated Floor Advance

- **Purpose:** Floors end only on the stairs (ADR-015 "Roof is Win State"), not on any confirm.
- **Reason:** `floor_placeholder.gd` advanced on a bare `ui_confirmed()`, letting the player "win"
  from anywhere — a placeholder that conflicts with the documented win condition.
- **Prerequisites:** M11, FloorLayout.
- **Files likely affected:** `scripts/floor_layout.gd` (`is_stairs_at`), `scripts/floor_placeholder.gd`.
- **Systems affected:** Floor flow.
- **Possible risks:** `is_stairs_at` must use the stairs room rect; the player tile is computed from
  `global_position / TILE_SIZE` (already used for balcony checks), so the same tile works.
- **Testing checklist:**
  - [x] `FloorLayout.is_stairs_at` true only on the stairs room; `_process` advances only there.
- **Definition of Done:** Reaching the stairs (confirm) is the sole floor-exit trigger.

**Atomic Steps:**
1. Add `FloorLayout.is_stairs_at(tile)` (stairs-room rect test). In `floor_placeholder.gd._process`,
   gate `GameManager.advance_floor()` behind `is_stairs_at(tile)`.

### Task M29.T3 — Export Preset + Versioning

- **Purpose:** Make the project buildable as a release.
- **Reason:** No export preset existed; `config/version` was still `0.1` (prototype).
- **Prerequisites:** `icon.svg`, `default_bus_layout.tres`, `config/name` set.
- **Files likely affected:** `export_presets.cfg` (new), `project.godot` (`config/version`).
- **Systems affected:** Packaging.
- **Possible risks:** The preset references `res://icon.svg`; export templates must be installed to
  actually build (documented in README). Unknown preset keys are ignored by Godot.
- **Testing checklist:**
  - [x] `export_presets.cfg` present with a Windows Desktop preset + icon.
  - [x] `config/version` bumped to `1.0.0-rc1`.
- **Definition of Done:** `godot --export-release "Windows Desktop" …` is the documented path.

**Atomic Steps:**
1. Add `export_presets.cfg` (Windows Desktop, icon `res://icon.svg`, `build/windows/...exe`).
2. Bump `config/version` to `1.0.0-rc1`.

### Task M29.T4 — Release Docs

- **Purpose:** Reader-facing RC docs.
- **Reason:** README was still marked "Prototype (v0.1)" with no build instructions.
- **Prerequisites:** M29.T3.
- **Files likely affected:** `README.md`.
- **Systems affected:** Docs.
- **Possible risks:** None (docs only).
- **Testing checklist:**
  - [x] README phase = Release Candidate; Build/Export section added.
- **Definition of Done:** A new player/developer can run and export from the README.

**Atomic Steps:**
1. Update README phase to Release Candidate and add a Build/Export section referencing
   `export_presets.cfg` + headless export command.

### M29 Exit Criteria

- `_test_release` passes: the generation/population pipeline runs for all 7 floors, a normal run
  reaches `WON`, a Blood Codex win unlocks `Bloodbringer`, a catch without the amulet goes to
  `GAME_OVER` and back to menu, and the Survival Amulet absorbs one hit. Floor advance is gated on
  the stairs tile (ADR-015). A Windows export preset exists, version is `1.0.0-rc1`, and the README
  documents run + export. No new `TODO` stubs; boot self-test fully green. **The game is a Release
  Candidate.**

---

## M30 - World Physics & Navigation

### Overview

- **Objective:** Make the castle a real space. M1-M29 built the full game loop, but two foundational
  subsystems were explicitly deferred and never landed: **world collision** (`FloorTileset` carried no
  collision; `FloorBuilder` painted floors as pure visuals) and **monster pathfinding** (monsters moved in
  a straight line "until A* pathfinding", per `monster.gd`). Without these, the player and monsters walk
  through walls and the core stealth fantasy does not function. M30 closes that gap.
- **Expected result:** The player and monsters collide with walls; monsters navigate corridors via A*
  instead of clipping through stone; locked/unopened doors physically block movement and route monsters
  around them. The game is genuinely playable as a stealth survival game.
- **Systems affected:** `FloorBuilder` (M12), `Monster` (M17), `Door` (M15), `DoorPlacer` (M15),
  `MonsterPlacer` (M17), `FloorPlaceholder`, plus new `WorldGrid`, `WallTileset`, `Pathfinder`.
- **Dependencies:** M29 (the rest of the game must already work).
- **Complexity:** L.
- **Implementation risks:** (1) Collision must not be disabled by room culling — verified that Godot 4
  keeps `visible = false` colliders active (only `disabled` toggles collision). (2) A* must avoid wall
  corner-cutting so monsters stay in corridors. (3) Door blockers must span the 2-wide corridor.

### Task M30.T1 - World collision

- Add `WorldGrid` (walkable grid rasterized from `FloorLayout` room/corridor rects, with a dynamic
  `blocked` set for closed doors) and `WallTileset` (visual wall tiles, no physics).
- `FloorBuilder.build()` now paints a visible wall `TileMapLayer` for every wall cell bordering the
  walkable area (the "shell") **and** adds a static collision `StaticBody2D` built from horizontally
  merged wall-shell rectangles (one body, many `CollisionShape2D`) so movement is blocked. Returns
  `world_grid` in the build dict.

### Task M30.T2 - Monster A* pathfinding

- Add `Pathfinder.find_path(grid, start, goal)` (8-directional A*, octile heuristic, no corner cutting,
  respects `blocked` tiles).
- `Monster` gains a `world_grid` reference; `_chase` and `_roam` follow the A* path (recomputed on a
  cooldown) instead of moving in a straight line. Straight-line fallback is kept when `world_grid == null`
  (e.g. unit tests) for safety.

### Task M30.T3 - Door blocking

- `Door` gains a `StaticBody2D` blocker (~64x64 to span the 2-wide corridor) enabled while closed, plus a
  `world_grid` reference. While closed it marks its corridor tiles `blocked` so monsters route around /
  wait; opening clears the block. The interaction `Area2D` was widened so the player can still open a door
  from the adjacent tile. `DoorPlacer` / `MonsterPlacer` thread `world_grid` from `FloorBuilder`.

### Task M30.T4 - Validation

- Add `_test_world_physics` to the boot self-test: every room center is walkable, far tiles are walls,
  A* finds an entrance->stairs path, and a closed door blocks (then unblocks) its tile. The full pipeline
  in `_test_release` now runs with `world_grid` wired through the placers.

### M30 Exit Criteria

- The player cannot leave walkable cells; monsters reach the player through corridors (not through walls);
  locked/unopened doors block movement and monster pathing until opened. `_test_world_physics` and the full
  boot self-test are green. With M30, **the game is playable end-to-end as a stealth survival game**, not
  merely a Release Candidate prototype.

---

> **Next:** Ship / post-RC fixes as needed. Real art (currently placeholder silhouettes) and a non-placeholder
> ending scene remain optional polish, deferred by prior decision.
