
```markdown
# docs/gameplay.md

# Gameplay Mechanics (Core Loop)

The player controls a young boy (the “hero”) exploring a multi-level castle at night, using a handheld lamp/lantern.  The core gameplay loop on each floor is: **Explore rooms → Manage light and resources → Avoid or hide from monsters → Collect items → Find stairs**.  Key mechanics:

- **Player States:** The boy has no combat; he can *Normal* or *Hidden*. Hidden (inside furniture) means monsters cannot see him. He has one life (Game Over if caught). He has a **lamp** with limited oil and can carry items/coins.

- **Lamp/Torch Mechanics:** The lamp creates a circular light radius around the player. Light intensity **fades with distance** (bright at center, gradual falloff over a few tiles to darkness). Maximum visible radius ≈ *N* tiles (game designer to specify). The lamp has a **burn time of 10 minutes** in real-time (600 seconds).  An **oil item** refill adds additional time (each oil adds e.g. +1-2 minutes; exact duration unspecified). If the lamp oil reaches zero, the lamp goes out (player is in total darkness, except for tiny glow).  The lamp can be manually turned **off** as well; with lamp off, the player is harder for monsters to detect (see below). Lamp status and remaining fuel are shown in the HUD (see UI.md).

- **Monster Encounters:** Various monsters roam the castle corridors. Each monster has:
   - **Detection:** A *visual radius* (8 tiles, 110° cone) and hearing (4 tiles). If the player steps within a monster's **sight radius** *and* is not hidden/invisible, the monster detects the player. If the lamp is off, detection radius is reduced (monsters rely on sound only).
  - **Footsteps Audio:** When a monster is nearby but hasn’t seen the player, the game plays *footstep* sounds and distant monster cries, cueing the player.
   - **Chase Behavior:** Once detected, a monster chases the player persistently. Monster chase speed is 140 px/s (player walk 120, run 180). The player can temporarily outrun a chasing monster by sprinting, but running drains energy. Chase tension comes from energy management, multiple monsters cornering the player, and patrol catching the player off-guard.
  - **Heartbeat Effect:** As soon as a monster is very close (one or two tiles) *or* upon detection trigger, a heartbeat sound plays and a subtle screen-effect (slight camera shake or vignette pulsing) mimics the heart pounding.
  - **Catch Sequence:** If the monster reaches the player, a “caught” sequence occurs: the player’s view briefly shows two glowing red eyes over the screen, then the screen turns fully red with **“Game Over”** text. After a short delay, the game returns to the main menu or restart option.

- **Hiding Mechanics:** In any room or corridor, certain objects allow hiding:
  - **Furniture (beds, wardrobes, chests):** If the player is adjacent to a bed, wardrobe, or chest, he can press a button to *hide*. While hidden, the monster’s line-of-sight cannot see him, and he remains safe until he leaves. The lamp can remain on or off; the hide action is how he survives.
  - **Balconies:** Some rooms have balcony exits. Entering a balcony yields a *safe zone*: monsters never follow onto balconies. On a balcony, ambient light is brighter (moonlight), and special items (see Items.md) often spawn. 

- **Items & Artifacts:** Throughout the castle the player finds:
  - **Gold Coins:**  Currency, stackable. Each chest or treasure may contain *1–10 coins*. Distribution: 1 coin (common), 3–5 coins (most common), 7 coins (uncommon), 8–9 coins (rare), 10 coins (very rare). (See Items.md table for percentages.)
  - **Lamp Oil:** Refills lamp fuel. Found in chests/counters.
  - **Food (apples, cookies, pie, cheese):** Healing items that restore a small amount of stamina/health. (If no explicit health system, they could represent energy points or be a lore element.)
  - **Keys:** Used to open locked doors (some castle doors require keys). Usually found in chests or on balconies.
  - **Monster Repellent / Amulet (unspecified):** (Not fully defined) potential rare items that could scare off monsters or grant one safe escape. (Details unspecified).
  - **Ghost Merchant Trades:** Occasionally, in random rooms, a ghostly merchant appears. He offers to trade coins for powerful one-time artifacts (see Items.md):
    - *Invisibility Cloak:* Grants temporary invisibility (monster cannot see the player for N seconds or 1 chase, exact duration unspecified).
    - *Fire Magic:* After purchase, the player no longer needs the lamp; he holds a permanent flame (lamp always on, or infinite light duration).
    - *Danger Sense:* Grants a permanent directional aura indicator; a red glow appears on the side of the screen pointing toward the nearest monster (persistent while the artifact is owned).
    - *Sleep Potion:* Instantly ends the current night. The game shows “The boy sleeps and wakes at dawn” and the next floor begins with brighter ambient light. Monsters’ detection/speed are reduced (~15–20%) on the following floor due to daylight and monster grogginess.
    - *Codex of Blood:* Unlocks a special “Blood Mode” for the remainder of this playthrough. In Blood Mode: all textures become red-tinged, monsters move faster and detect quicker, the player gets tired faster, and resources (oil, items) appear ~40% less often. If the player completes the game in this mode, the achievement **“Bloodbringer”** is awarded. (Only one such codex exists per run; after buying it, no more ghosts appear.)
  - For the merchant trades: coin prices are game-balance decisions (examples: Cloak 20–50 coins, Fire Magic 15–30, etc.). If unspecified, note “Price: unspecified” and adjust in balancing (see Items.md).

- **Floor Progression:** The castle has **7 floors** plus the roof. Each floor is a random maze of rooms/corridors (rooms contain furniture and items, corridors connect them).  On each floor, a *staircase up* is randomly located.  When the player reaches the staircase and goes up:
  - Transition effect: screen fades out momentarily, then fades in on the next floor.
  - The game displays “Checkpoint saved (Floor N)” meaning if the player later dies, he restarts on this floor at the beginning (not from Floor 1).
- On the 7th floor, the staircase leads to the **Roof**. On the roof, gameplay pauses: the player character can “sit at the edge of the roof”. While sitting, the moon is visible; after a short time, the game shows end credits text “Thank you for playing – To Be Continued…”. 

- **User Interface (HUD):** See UI.md for full layout. In brief: display current **lamp oil meter**, **gold coin counter**, and **inventory/accessories** on screen. Show a small minimap or indicator of dark/light boundaries is *optional* (not specified). Indicate monster alerts via UI effects (e.g. red vignette during danger sense or heartbeat). On Game Over, show full red-screen overlay with “Game Over” and menu options.

- **Audio Cues:** Continuous **rain** and distant thunder play on the menu and early floors. **Footsteps** sounds signal nearby monsters. A **heartbeat** thump plays when a monster is very close or has detected you. Subtle ambient castle sounds (wind, dripping water) add atmosphere. Simple UI sounds for menu and item pickup.

- **Balance & Parameters:** All gameplay numbers (detection radii, chase speed, item rarities, effect durations) should be specified explicitly. From user spec: Lamp burn time = 10 min; Monster patrol 90 px/s, chase 140 px/s; detection radius 8 tiles; monster alert reduction with lamp off = 0.5×; Danger Sense aura is permanent (once acquired); Sleep buff = 15–20% slower monsters next day; Blood Mode resource drop chance = ~60% of normal (40% rarer). Mark any unspecified values clearly for later design.

