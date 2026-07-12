# Pixel Horror Castle

**Genre:** Top-down pixel-art horror survival  
**Platform:** PC (Steam)  
**Engine:** Godot 4 (GDScript)  
**Resolution:** 320×180 (pixel-art, integer scaling)  
**Target FPS:** 60  
**Phase:** Release Candidate (v1.0.0-rc1)

---

## Overview

A no-combat horror-survival game. The player controls a frightened boy exploring a medieval castle at night with a limited-fuel lantern. Survival depends on light management, resource management, stealth, and hiding. The goal is to ascend 7 procedurally generated floors and reach the rooftop.

Core pillars: **Exploration & Atmosphere**, **Fear & Stealth**, **Resource Management**, **Progression**.

---

## Requirements

- **Godot Engine 4.4** (stable) — the project targets `4.4` features (`config_version=5` in `project.godot`).
- **Export templates for 4.4** — required only if you build the Windows Desktop export (see *Build / Export*).
- **gdtoolkit** for local GDScript lint/format: `pip install "gdtoolkit==4.*"`.
  CI automatically runs `gdlint` and `gdformat --check` on the `scripts/` directory.
- A GPU/driver supporting OpenGL (the project uses the **GL Compatibility** renderer).

---

## How to Run

1. Open the project in Godot 4.x.
2. The main scene is `res://scenes/Main.tscn`.
3. Press **Play** (F5) — self-tests run at boot, then the main menu appears.

---

## Build / Export

The project ships a Windows Desktop export preset (`export_presets.cfg`). With Godot 4.x and the
matching export templates installed:

1. Editor → **Project → Export…** → select **Windows Desktop** → **Export**.
2. Or headless: `godot --headless --export-release "Windows Desktop" build/windows/pixel_horror_castle.exe`

The executable icon is `res://icon.svg`; the main scene is `res://scenes/Main.tscn`.

---

## Controls

| Action | Key | Controller |
|--------|-----|------------|
| Move | WASD | D-Pad |
| Run | Shift | — |
| Interact / Open | E | — |
| Toggle lantern | F | — |
| Pause | Esc | — |
| Confirm | Enter | A / Cross |
| Cancel | Esc | B / Circle |

---

## Documentation Index

| File | Contents |
|------|----------|
| `docs/architecture.md` | System architecture, scene flow, node layout |
| `docs/architecture-summary.md` | Condensed architecture reference |
| `docs/gameplay.md` | Core gameplay mechanics |
| `docs/gameplay-summary.md` | Condensed gameplay reference |
| `docs/vision.md` | Game vision, atmosphere, art direction |
| `docs/items.md` | Item and artifact definitions |
| `docs/monster.md` | Monster AI parameters |
| `docs/generation.md` | Procedural floor generation rules |
| `docs/balancing.md` | Numeric tuning values |
| `docs/save-system.md` | Save schema and persistence |
| `docs/ui.md` | HUD and menu layout |
| `docs/world.md` | Room node contract |
| `docs/input-bindings.md` | Input action bindings |
| `docs/coding-style.md` | GDScript conventions |
| `docs/art-style.md` | Visual and audio aesthetic |
| `docs/decisions.md` | Architecture Decision Records (ADRs) |
| `docs/dependency-graph.md` | System dependency ordering |
| `docs/roadmap.md` | Implementation milestones |
| `docs/project.md` | Project overview and milestones |
| `docs/conflicts-log.md` | Resolved documentation conflicts |

---

## Project Structure

```
PixelHorrorCastle/
├── scenes/        # Godot .tscn scene files
├── scripts/       # GDScript source files
├── assets/        # Sprites, audio, tilesets, fonts
├── data/          # Data-driven JSON tables
├── config/        # Engine config resources (e.g. balancing.tres)
├── tools/         # Dev/utility scripts (e.g. placeholder generation)
├── docs/          # Design and architecture documentation
├── .github/       # CI workflow (Godot import, headless boot, gdtoolkit lint)
└── project.godot  # Engine configuration
```

> **Note:** The `.opencode/` directory (if present) is local assistant/tooling
> configuration and is excluded via `.gitignore`. It should not be committed.
