# docs/items.md

# Items and Artifacts

Each item below is identified by an **ID** (for implementation), a description, its in-game effect, whether it can stack, where it spawns, and its rarity/probability. Prices for merchant trades are noted if known (otherwise marked *unspecified*).

| ID               | Name               | Description                                         | Effect                                         | Stackable? | Spawn Location                 | Rarity / Prob.       | Merchant Price (coins)    |
|------------------|--------------------|-----------------------------------------------------|------------------------------------------------|------------|--------------------------------|----------------------|---------------------------|
| COIN             | Gold Coin          | Currency.                                            | Collected coins used to buy items.             | Yes        | Chests, rooms                   | 1→common, 3-5→common, 7→occasional, 8-9→rare, 10→very rare (see below table) | —                         |
| OIL              | Lamp Oil           | Lantern fuel.                                        | Restores lamp burn time (+X minutes).          | No         | Chests, balconies               | Unspecified/common   | —                         |
| APPLE            | Apple              | Food (fruit).                                        | Restores small health/stamina.                 | No         | Chests, floors, balconies       | Common               | —                         |
| COOKIE           | Cookie             | Food (biscuit).                                      | Restores small health/stamina.                 | No         | Chests, floors                  | Common               | —                         |
| PIE              | Pie Slice          | Food (piece of pie).                                 | Restores moderate health.                      | No         | Chests, floors (rare)           | Unspecified/rare     | —                         |
| CHEESE           | Cheese             | Food (cheese).                                       | Restores small health.                         | No         | Chests, floors (rare)           | Unspecified/rare     | —                         |
| KEY              | Old Key            | Door key.                                            | Unlocks one locked door.                       | Yes (low)  | Chests, balconies               | Unspecified uncommon | —                         |
| REP_SPRAY        | Monster Repellent  | Spray or charm.                                      | Temporarily repels monsters (unspecified effect)| No         | Rare in chests                  | Rare                 | —                         |
| LIFE_AMULET      | Amulet of Survival | Magical amulet.                                      | Prevents death once (one time shield).         | No         | Very rare (chests)              | Very Rare            | —                         |
| CLOAK            | Invisibility Cloak | Worn cloak.                                          | Grants temporary invisibility (exact duration TBD). | No    | (Not found; purchased from ghost merchant) | Artifact | ~unspecified (e.g. 20–50)   |
| FIRE_MAGIC       | Fire Magic Tome    | Spellbook of flame.                                  | Lighting in hand; lamp no longer needed.       | No         | (Merchant only)                 | Artifact             | ~unspecified (e.g. 15–30)   |
| DANGER_SENSE     | Amulet of Sensing  | Mystic amulet.                                       | Shows red aura on screen toward any monster’s direction. | No | (Merchant only)                 | Artifact             | ~unspecified (e.g. 10–20)   |
| NIGHT_VISION     | Night Vision Potion| Magical potion.                                      | Grants night vision for 120 seconds (brighter view in dark areas). | No | (Merchant only)              | Artifact             | ~unspecified (e.g. 10–20)   |
| SLEEP_POTION     | Sleep Potion       | Flask of potion.                                     | Ends night early: skip to dawn, boosts vision and slows monsters next floor. | No | (Merchant only)               | Rare Artifact        | ~unspecified (e.g. 5–15)    |
| BLOOD_CODEX      | Codex of Blood     | Tome with dark lore.                                 | Activates “Blood Mode”: red textures, tougher monsters, fewer resources. Achievement if finish game in this mode. | No | (Merchant only, unique)    | Very Rare Artifact   | ~unspecified (e.g. 50–100)  |

**Coin Drop Table (Rarity %):**

| # of Coins | Common (%) | Uncommon (%) | Rare (%) | Very Rare (%) |
|------------|------------|--------------|----------|---------------|
| 1          |     50     |      —       |    —     |       —       |
| 2          |     20     |      —       |    —     |       —       |
| 3-5        |     25     |      —       |    —     |       —       |
| 6          |     3      |      —       |    —     |       —       |
| 7          |      —     |     15%      |    —     |       —       |
| 8-9        |      —     |      —       |   ~10%   |       —       |
| 10         |      —     |      —       |    —     |     ~2%       |

*(The above distribution is illustrative. Actual percentages should be balanced so that 3–5 coins occur most often, 7 occasional, 8–9 rare, 10 very rare.)*

