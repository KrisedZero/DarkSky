# docs/monsters.md

# Monsters (AI)

Monsters are the main threat. Below are core parameters and behaviors. Any unspecified values should be set and tested later.

- **Detection:** Each monster has a *sight radius* (8 tiles) and a *hearing radius* (4 tiles). If the player is within sight and in light (not hidden/invisible), the monster spots them. With the lamp off, use hearing only (monsters hear footsteps up to hearing radius).
- **Speed:** Monsters patrol at 90 px/s and chase at 140 px/s (player walk 120, run 180). Chasing monsters are slower than a sprinting player, so running allows temporary escape at the cost of energy. They chase once the player is detected.
- **Chase Mechanics:** When chasing, monsters pathfind around obstacles. If the player breaks line of sight (hides), the monster will search for a short time (e.g. 5–10 seconds; unspecified) then return to normal patrol.
- **Stealth Interaction:** If the player turns off the lamp or hides, monsters lose sight. Monster detection chance drops significantly when it’s dark. (Implement: if lamp is off and player not moving fast, monster does not see unless player is adjacent.)
- **Spawn/Behavior:** Monsters spawn roaming on each floor. They patrol rooms and corridors arbitrarily (no fixed spawn points). Increase spawn count slightly on higher floors (not specified).
- **Audio/Visual Feedback:** 
  - *Audio:* Footstep sounds are triggered when a monster is moving within hearing range. A tense ambience intensifies when monsters are nearby. On detection, a sudden scream or alert sound plays.
  - *Visual:* When a monster spots the player, a red border flash (or vignette) appears instantly. If chasing, background music or heartbeat intensifies. On final catch, the “red eyes” Game Over effect appears.

| Property            | Example Value (unspecified)                 | Notes                              |
|---------------------|---------------------------------------------|------------------------------------|
| Sight Radius        | 8 tiles                                     | Monster can see player (vision cone 110°) |
| Hearing Radius      | 4 tiles                                     | Monster hears player if lamp off   |
| Patrol Speed        | 90 px/s                                     | Roaming speed                      |
| Chase Speed         | 140 px/s                                    | Pursuit speed (slower than player sprint 180) |
| Chase Duration      | indefinite until caught or lost (unspecified)| Monster stops only when reaching player or losing sight |
| Search Time after loss | ~5s                                     | Time monster searches after losing sight |
| Damage              | Instant kill (Game Over)                    | Player has no HP bar; caught = death |

