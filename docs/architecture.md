# architecture.md

## 1. Game Flow Overview
This diagram shows the main scene flow and interactions:
```mermaid
flowchart TD
    MainMenu -->|Play| IntroScene
    IntroScene -->|Arrive at Castle| Floor1
    Floor1 --> Floor2 --> Floor3 --> Floor4 --> Floor5 --> Floor6 --> Floor7
    Floor7 --> RoofEnding
    RoofEnding --> Credits
MainMenu: Rainy night forest background (animated). Button ➔ IntroScene.
IntroScene: Boy walks through forest to castle. Fade to black, then load Floor1.
Floor Scenes (1–7): Each floor is loaded with procedural layout (Floor<n>.tscn). Entry point always fixed (castle gate).
RoofEnding: Static scene with boy on roof watching moon and playing credits.
2. Core Systems
Player System: Controls movement (top-down WASD), lantern logic, energy/hiding state, and interaction (chests, doors, furniture).
Monster AI System: Each monster has states: Patrol (random walk), Detect (hearing or sight), Chase (pursue player on grid path), and Return (go home).
Lighting System: Manages lantern radius and fade. Also applies night-vision or darkness effects (e.g. Blood Codex red filter).
Inventory System: Tracks coins, keys, food, and artifacts. Allows use of items (e.g. drink potion, cloak).
Item & Artifact System: Defines behaviors for consumables (restore oil/energy), equipment (cloak, night-vision), and triggers their effects.
World/Level Generator: Procedurally creates each floor’s layout (rooms, corridors, decorations, spawn points).
Room Management: Each room has nodes for geometry, furniture (beds, wardrobes), chests, monsters, and triggers (doors, etc).
Merchant (Ghost): NPC that can appear to trade items. Has its own logic for offering items and updating inventory.
Save/Load System: Global manager to serialize/deserialize game state (see save-system.md).
UI System: HUD with health/energy bar, oil gauge, coin counter. Screens: Main Menu, Pause, Game Over, Credits.
Audio System: Plays music (floor ambiance), SFX (footsteps, heartbeat, item pickups), and UI sounds.
GameManager: Overall control (start game, advance floors, track achievements, handle game over).
3. System Interactions
mermaid
Copy
flowchart LR
    Input --> PlayerController
    PlayerController --> Lantern (update radius)
    PlayerController --> InteractionController
    PlayerController --> InventoryManager
    MonsterAI --> HeartbeatSound
    PlayerController -->|signal:damage| UIManager
    InventoryManager --> UIManager
    SaveManager --> GameManager
    GameManager --> SceneLoader
The PlayerController processes input and moves the player node. It updates lantern light radius via the LightingSystem.
When Player interacts (e.g. presses Use key), InteractionController handles opening chests, hiding, or using items.
InventoryManager updates coin counts, consumables, and artifacts; UIManager displays these on HUD.
MonsterAI emits events (e.g. on_player_spotted) causing audio/visual effects (heartbeat sound, enemy sprites).
GameManager oversees transitions: on floor clear or fall (game over), it calls the scene loader or credits. SaveManager serializes state via GameManager.save_game().
4. Scene & Node Architecture
MainMenu.tscn: Root node MainMenu with child CanvasLayer (UI) and Rain (Particles2D) and ForestBG (Parallax).
IntroScene.tscn: Animated Character2D walking animation; transitions to Floor1.
Floor<n>.tscn: Root Floor node with children:
TileMap for walls/floors.
RoomNodes (instanced scenes) containing environment, monsters, items.
Player (spawn at entrance).
Camera2D (tracking Player, locked to Floor bounds).
CanvasLayer/HUD (attached UI).
UI Scenes: HUD.tscn (health bar, coin counter, oil meter), PauseMenu.tscn, GameOver.tscn, Credits.tscn.
Entity Scenes: Player.tscn (KinematicBody2D, Sprite, Collision), Monster.tscn, Merchant.tscn (NPC dialogue), Chest.tscn, etc.
5. Folder Structure
bash
Copy
PixelHorrorCastle/
├── AGENTS.md
├── PROJECT.md
├── README.md
├── scenes/          # Godot .tscn files
│   ├── MainMenu.tscn
│   ├── IntroScene.tscn
│   ├── FloorScene.tscn
│   └── ... 
├── scripts/         # .gd files
│   ├── PlayerController.gd
│   ├── MonsterAI.gd
│   ├── InventoryManager.gd
│   ├── SaveManager.gd
│   └── ...
├── assets/          
│   ├── sprites/     
│   ├── audio/       
│   ├── tilesets/    
│   └── ...
└── docs/
    ├── architecture.md
    ├── gameplay.md
    ├── world.md
    └── ...
(Continue reading docs/ files as needed for details. The agent should not modify scene structure without considering this architecture.)