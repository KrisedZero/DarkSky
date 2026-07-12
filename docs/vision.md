# docs/vision.md

# Vision

The game is a top-down 2D pixel-art horror adventure set in a medieval fantasy castle.  Atmosphere is dark and eerie: heavy rain, wind, and distant thunder against a night sky.  We use pixel graphics with a retro feel, muted colors (dark grays, deep blues, and flickering candlelight yellows), and stylized medieval architecture (stone walls, wooden doors, tapestries).

- **Opening Scene:** The game starts at the main menu over a looping animated background: a rainy night in a dense forest, with occasional flashes of lightning and ambient forest sounds (crickets, rustling leaves, distant owl hoot).  A single “Play” button appears. Pressing **Play** begins a short cutscene: a boy carrying a lit lantern walks through the forest toward a looming castle. The cutscene ends as he reaches the castle entrance.

- **Castle Entrance:** The castle has exactly **one** entrance. All other paths (to the left, right, or back) are blocked by invisible barriers or impassable terrain, enforcing a single route forward. The perspective remains top-down during the cutscene and gameplay.

- **Main Menu Flow:** The main menu has only two options: “Play” and “Exit”.  Selecting **Play** plays the entrance cutscene and loads Floor 1. There is no other path out; the “Play” state is the only way to start the game.

- **Art Style & UX:** The forest and castle are rendered in pixel art with a **horror-fantasy** aesthetic. The menu background animation loops the rain and candle flicker.  On-screen hints/instructions (e.g. “Press Play”) should be minimal and blend with UI.  The *UX flow* is: **Menu (rainy forest) → Play → Cutscene (forest→castle) → Floor 1**. The player cannot proceed anywhere else from the menu (no “back” path).

```mermaid
flowchart LR
    Start([Start Game]) --> Menu[Main Menu<br>(Forest, Rain)]
    Menu -->|Play Button| Cutscene[Boy walks through Forest]
    Cutscene --> CastleEntry[Boy reaches Castle Entrance]
    CastleEntry --> Floor1[Floor 1]
    Floor1 --> Floor2[Floor 2]
    Floor2 --> Floor3[Floor 3]
    Floor3 --> Floor4[Floor 4]
    Floor4 --> Floor5[Floor 5]
    Floor5 --> Floor6[Floor 6]
    Floor6 --> Floor7[Floor 7]
    Floor7 --> Roof[Roof Scene & Credits]
