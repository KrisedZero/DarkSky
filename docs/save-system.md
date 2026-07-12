Defines what game state is saved/loaded. Uses JSON serialization.

Save Trigger: Auto-save when ascending floors and at critical points. Optional manual save disabled (no death saves).
File Format: One JSON file per save slot. Versioned schema (compatibility).
Schema (JSON)
```json
{
  "version": 1,
  "current_floor": 3,
  "random_seed": 123456,
  "player": {
    "energy": 60,
    "lamp_oil": 420,
    "lamp_on": true,
    "state": 0
  },
  "inventory": {
    "coins": 12,
    "stacks": { "KEY": 1 },
    "artifacts": ["CODEX_BLOOD"],
    "flags": { "merchant_visited": false }
  },
  "opened_chests": [101, 202, 305],
  "opened_doors": [10, 27],
  "blood_codex_mode": true
}
```
- `version`: Integer schema version (increment if structure changes).
- `current_floor`: Floor number the player is on.
- `random_seed`: RNG seed used to generate this floor layout.
- `player.energy`: Current energy (0–100).
- `player.lamp_oil`: Seconds of fuel remaining in lantern.
- `player.lamp_on`: Whether the lantern is lit.
- `player.state`: 0 = NORMAL, 1 = HIDDEN.
- `inventory.coins`: Coin count (persisted in stacks, mirrored here for query speed).
- `inventory.stacks`: Dict of item ID → quantity (stackable items only, artifacts are separate).
- `inventory.artifacts`: Array of unique artifact IDs acquired.
- `inventory.flags`: Dict of boolean/integer flags (equipment ownership, merchant_visited, etc.).
- `opened_chests`: List of chest IDs that have been looted.
- `opened_doors`: List of door IDs unlocked (locked doors become open on restore).
- `blood_codex_mode`: Bool (true if Blood Codex artifact owned).
Loading Logic: On load, regenerate floor with saved seed and floor number. Then, for each saved chest/door ID, instantiate as already opened (skip spawning loot/lock). Restore player stats and inventory from JSON. This ensures deterministic replay.


