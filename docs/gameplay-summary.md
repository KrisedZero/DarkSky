# Gameplay Summary — Pixel Horror Castle

> Deliverable 3 of the implementation roadmap. Derived strictly from `docs/gameplay.md`, `docs/vision.md`,
> `docs/monster.md`, `docs/items.md`, `docs/generation.md`, `docs/balancing.md`, `docs/save-system.md`,
> and `docs/ui.md`. Summary only — no invented mechanics, no redesign.

---

## 1. Premise

A no-combat, top-down pixel-art horror-survival game. The player is a frightened boy exploring a medieval
castle at night with a limited-fuel lantern. Survival relies on **light management, resource management,
stealth, and hiding**. The player has **one life** — being caught by a monster is an instant Game Over.
The goal is to ascend 7 procedurally generated floors and reach the rooftop for a quiet ending.

---

## 2. Core Gameplay Loop (per floor)

```
Explore rooms → Manage light & resources → Avoid / hide from monsters
      → Collect items → Find the staircase → Ascend (checkpoint) → next floor
```

Repeat across 7 floors → Roof ending → Credits → Main Menu.

---

## 3. Player

- **States:** `Normal` and `Hidden` (inside furniture = invisible to monsters). No combat, one life.
- **Movement (balancing.md):** walk 120 px/s, run 180 px/s, crouch/hide 80 px/s.
- **Energy:** max 100; walking costs 0.1%/s, running 0.25%/s; regen ~1%/min (minimal) unless sleeping.
- **Lantern:** circular light radius, bright center fading to darkness over a few tiles.
  - Burn time 600 s (10 min) base.
  - Can be manually toggled **off** → harder for monsters to detect (they rely on hearing).
  - At 0 oil the lamp goes out (near-total darkness).
  - Oil refill: small +60 s, large +120 s (balancing.md).

---

## 4. Monsters (threat)

- **Behavior states:** Patrol (random roam) → Detect (vision/hearing) → Chase (A* pursuit) → Return (home).
- **Detection:** vision cone 110°; hearing range 4 tiles (footsteps). Detected only when in sight **and**
  in light and not hidden/invisible. Lamp off → hearing only.
- **Speed (balancing.md):** patrol 90 px/s, chase 140 px/s. Roam pause 1–3 s.
- **Detection / chase radius (balancing.md):** detection 8 tiles, chase/pursue 12 tiles.
- **Search after loss:** ~5 s searching, then return to patrol.
- **Catch = death:** two glowing red eyes → full red screen → "Game Over" → Main Menu / restart.

> All documentation conflicts resolved. See `docs/conflicts-log.md` for details.
> - C3: sight radius = 8 tiles (canonical).
> - C4: chase 140 < run 180 is intentional (energy management creates tension).
> - C9: Danger Sense = permanent directional aura (once acquired).

---

## 5. Stealth & Hiding

- **Furniture (beds, wardrobes, chests):** press interact while adjacent to hide; monster line-of-sight
  cannot see the player while hidden; safe until the player leaves.
- **Balconies:** safe zones — monsters never follow; brighter moonlight; guaranteed loot spawns; can serve
  as a one-way out-of-bounds exit.
- **Lamp off:** reduces detection (monsters fall back to hearing). If dark and not moving fast, a monster
  won't detect the player unless adjacent.
- **Feedback:** heartbeat sound + subtle screen effect (camera shake / vignette pulse) when a monster is
  very close or on detection; red border flash on being spotted.

---

## 6. Resources & Items

| Category | Items | Effect |
|----------|-------|--------|
| Currency | Gold Coin (COIN) | Spent at ghost merchant |
| Fuel | Lamp Oil (small +60 s, large +120 s) | Refills lantern |
| Food | Apple +20, Cookie +10, Cheese +25, Pie +35 energy | Restore energy |
| Access | Old Key (KEY) | Opens one locked door |
| Rare | Monster Repellent (REP_SPRAY), Amulet of Survival (LIFE_AMULET) | Repel / one-time death shield |

**Coin drop:** each chest 1–10 coins. 3–5 coins most common, 7 occasional, 8–9 rare, 10 very rare.
(Exact percentages differ between items.md and balancing.md — to be reconciled in balancing.)

---

## 7. Artifacts (merchant-only, one-time)

| Artifact | Effect |
|----------|--------|
| Invisibility Cloak (CLOAK) | Temporary invisibility (1 hit / duration TBD) |
| Fire Magic Tome (FIRE_MAGIC) | Permanent hand flame; lamp no longer needed |
| Danger Sense (DANGER_SENSE) | Red aura on screen edge toward nearest monster |
| Sleep Potion (SLEEP_POTION) | Ends the night; next floor brighter, monsters ~15–20% weaker |
| Codex of Blood (BLOOD_CODEX) | Toggles Blood Mode (see §10); unique per run — no more ghosts after buying |

> Note: "Night Vision Potion" appears in generation/balancing/save example but has no canonical items.md
> table entry (conflict C6). REP_SPRAY / LIFE_AMULET lack placement rules (C8).

---

## 8. Ghost Merchant

- Appears with 50% chance on each floor ≥ 2 (never floor 1, never entrance/exit rooms).
- Sells artifacts (above); restocks randomly each floor; prices in coins (higher for Blood Codex).
- Keys are never sold — only found.
- After Blood Codex is purchased, the merchant no longer appears.

---

## 9. Floor Progression & Saving

- **7 floors** + roof; floors 1–6 procedurally generated, floor 7 leads to the roof.
- Each floor: 12–30 rooms as a tree graph; guaranteed path Entrance → Stairs; required room types
  (Entrance, Stairs, ≥1 Balcony, ≥1 Bedroom); ≤3 locked doors with keys placed beforehand.
- **Ascending stairs:** screen fade out/in → "Checkpoint saved (Floor N)".
- **Save (save-system.md):** autosave on ascent only; JSON; stores seed, floor, player stats/inventory,
  opened chest/door IDs, merchant_visited, blood_codex_mode. On load, regenerate floor from seed and
  re-apply opened IDs for deterministic replay.

> ~~C5~~ (resolved): no health system — caught = death. See `docs/conflicts-log.md`.

---

## 10. Difficulty — Blood Codex Mode

Activated by purchasing the Codex of Blood. For the rest of the run:
- All textures become red-tinged.
- Monsters move faster and detect quicker.
- Player tires faster.
- Resources (oil, items) appear ~40% less often (~60% of normal).
- Completing the game in this mode awards an achievement.

> ~~C10~~ (resolved): achievement name = "Bloodbringer". See `docs/conflicts-log.md`.

---

## 11. UI / HUD

- **HUD:** lamp oil meter (top-left), coin counter (top-right), active artifact icons (bottom corner),
  action prompts ("Press [Key] to hide/enter"), monster alert (red vignette flash / directional aura).
- **Screens:** Main Menu (rainy forest, Play/Exit, single-entry), Intro cutscene, Pause, Game Over
  (red overlay → Main Menu/Quit), Roof ending (moon + "Thank you for playing. To be continued…"), Credits.

---

## 12. Audio Cues

- Continuous rain + distant thunder (menu / early floors).
- Footsteps signal nearby monsters; heartbeat when a monster is close or has detected the player.
- Ambient castle sounds (wind, dripping water); UI + pickup sounds.
- Detection alert (scream/sting) on being spotted.

---

## 13. Win / Lose Conditions

- **Win:** reach the roof on floor 7, sit at the edge → ending scene + credits.
- **Lose:** caught by any monster → instant Game Over (restart from last floor checkpoint).

---

## 14. Unresolved Gameplay Values (for balancing phase)

- Monster sight radius (C3), effective chase tension vs player run speed (C4/G1).
- Lamp-off detection reduction factor.
- Cloak duration, Sleep debuff exact %, Danger Sense duration (C9).
- Merchant prices per artifact, chest oil spawn chance.
- Coin drop percentages (reconcile items.md vs balancing.md).
- Health vs instant-death model (C5).
