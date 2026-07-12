Outlines the procedural generation rules for floors (rooms, corridors, items, monsters).

1. Floor Layout
Floor Count: 7 floors total (floors 1–6 random, floor 7 = final rooftop).
Seed: Each new game/random floor uses a fresh random seed to ensure reproducibility. Store seed in save.
Room Count: 12–30 rooms per floor (random within range). Larger floors in later levels.
Connectivity: Rooms form a tree graph (no loops by default). Guarantee a path from Entrance ➔ Stairs out. No isolated rooms.
Floor Types: Each floor must include: Entrance room (player spawn), Stairs room (exit), at least 1 Balcony, at least 1 Bedroom (with bed and chest). Others: Hall, Library, Kitchen, Dining, Storage, Chapel, Secret Room, etc.
2. Corridors & Doors
Corridors: Connect rooms in a branching pattern. Corridor nodes are implicit (room adjacency).
Doors: Randomly place doors between some rooms/corridors. Some doors are locked (require key). Place matching keys elsewhere on the floor. Locked doors count ≤ 3 per floor.
3. Furniture & Decoration
Beds: Spawn only in Bedroom-type rooms (1 bed per bedroom).
Wardrobes: Spawn in corridors and bedroom closets (random 0–2 per floor).
Chests: Spawn 3–6 chests per floor (at least 1 in a bedroom). Assign unique ID for tracking.
Interactables: Place torches on walls in halls/rooms (for ambience only, not interactable). Paintings on walls (decorative).
Balconies: 1–2 balconies per floor. Treated as special rooms: brightly lit (safe zones), contain some loot (food, coins), no monsters. Player can exit out-of-bounds (non-return path).
4. Monster Placement
Count: 3–8 monsters per floor (random). Increase with floor index for difficulty.
Rooms: Do not place monsters right next to entrance. At least 1 monster placed near stairs or other key room for challenge.
Patrol: Monsters roam their assigned room(s) and nearby corridors. Use A* on TileMap for pathfinding when chasing.
5. Items & Loot
Coins in Chests: Each chest contains 1–10 coins. Distribution: majority (≈70%) contain 1–5 coins, rare chests (≈15%) have 6–9, ultra-rare (≈5%) have 10.
Food: Chests have a 40% chance to contain 1 food item (apple, cookie, cheese, or pie). Rarity: apple/cookie (common), cheese (uncommon), pie (rare).
Oil: 20% of chests contain oil (small 50% vs. large 10%). Rare floor caches have big oil barrel.
Artifacts: 10% chance per floor to spawn exactly one rare artifact (from Merchant trades or hidden chest). Artifacts: Invisibility Cloak, Fire Tome, Danger Senses, Night Vision Potion, Sleep Potion, Blood Codex. Only 0–1 per type per game.
Rare Items in Chests: Monster Repellent (REP_SPRAY) spawns in ~5% of chests. Amulet of Survival (LIFE_AMULET) spawns in ~2% of chests (very rare).
Spawn on Balcony: Always include at least 1 of each essential resource (food, oil, coins) on balconies.
6. Ghost Merchant
Spawn: 50% chance on each floor ≥2 (except floor1). Merchant appears in one random room (not entrance/exit).
Inventory: Sells special items (listed above). Restocks randomly each floor.
Pricing: Coins (5–10) per item (higher for Blood Codex). Keys not sold, only found.
7. Validation Rules
Ensure each floor is completable:
Entrance ➔ Exit reachable without backtracking into inaccessible areas.
Enough oil/food exists so player cannot get stranded.
Monsters cannot trap the player (always at least one route to hide/run).
Keys for locked doors are placed before doors.
Seed





