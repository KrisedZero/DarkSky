# docs/ui.md

# UI and Menus

This document covers the user interface and HUD, including the main menu, in-game HUD, Game Over screen, and final credits.

- **Main Menu (Title Screen):** 
  - Background: Animated rainy forest leading to castle (looping). Sounds: rain and wind.
  - Buttons: “Play” (starts the game), “Exit” (quits). 
  - UX Note: Only “Play” leads into the castle. There is no “Back” path, so do not offer a way to quit the cutscene or go anywhere else. The menu itself should prevent cursor/character movement off-screen.
  - Button Behavior: On **Play**, fade to black then transition to the cutscene of walking to the castle entrance (as described in Vision.md). On **Exit**, quit the game.

- **Single-Entry Enforcement:** 
  - In both menu and in-engine scenes, ensure the player cannot leave the intended area. For example, in the forest/castle approach scene, moving off the main path should be blocked by invisible barriers (simply collide on screen edges), forcing the player forward to the castle.

- **In-Game HUD Layout:** (visible during gameplay)
  - **Lamp Oil Meter:** A UI bar (e.g. top-left) showing remaining lamp fuel (e.g. a lantern icon with fill level or time countdown).
  - **Coin Counter:** Top-right corner displays “Coins: X”.
  - **Inventory/Effects:** Small icons (bottom-left or right) for active artifacts (e.g. cloak icon if used, blood codex icon if active). 
  - **Visibility Indicator:** (Optional) Show a vignette around darkness edge; otherwise, rely on graphics.
  - **Action Prompts:** When near a hideable object or doorway, show a tooltip (e.g. “Press [Key] to hide” or “Press [Key] to enter”).
  - **Monster Alert:** If Danger Sense or heartbeat triggers, overlay a red directional indicator (for Danger Sense) or flash (for heartbeat) on the screen.

- **Game Over Screen:** 
  - Sequence: After catch sequence (red flash), display a menu overlay with:
    - Title: “Game Over” in stylized horror font.
    - Options: “Main Menu” and “Quit”.
    - Background: dark castle backdrop (faded).
    - Sound: slow ominous tone.
    - Behavior: “Main Menu” returns to title menu; “Quit” exits.

- **Roof / Ending Scene:** 
  - On reaching the roof and sitting at the edge, fade to a night sky view with the moon. Slowly display text “Thank you for playing. To be continued…”. Play a calm ending tune.
  - After credits text, return to main menu automatically or on button press.

- **General UI Style:** Use pixel-art UI frames consistent with game’s palette. Text should have a slight glow or outline for readability in dark scenes. Keep HUD minimal to not obscure environment.

