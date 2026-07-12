
## technical-requirements.md  
```markdown
# Technical Requirements

- **Engine & Platform:** Godot 4.x (chosen for lightweight 2D support). Export target: Windows 10/11 (x86_64 SSE4.2). *(Recommended spec: 4-core CPU, integrated GPU or better; e.g. Intel i5-6600K/Ryzen 5 1600.)*  
- **Resolution & Rendering:** Base resolution 320×180 (16:9) pixel-art. Enable **Pixel Perfect** viewport (disable texture filtering) so sprites remain crisp when scaled. Use Godot’s 2D lighting (Light2D, CanvasModulate) for dynamic shadows; consider performance (cache light shaders, limit light sources).  
- **Frame Rate:** Target 60 FPS; Physics FPS at 60 (Godot default) for smooth movement and interactions.  
- **Performance:** Keep memory use low (<500 MB) by using packed textures (Atlases) and freeing unused nodes. Aim for scene load time <3s. Profile with Godot profiler to catch bottlenecks.  
- **Save System:** Use JSON serialization for save data. Godot’s JSON class can convert dictionaries to strings for saving. Autosave on each floor climb; format: `save_floor#.json`. Ensure backward-compatible saves (avoid breaking changes to saved format).  
- **Localization:** Support English first, plan Russian later. Use Godot’s `tr()` and `tr_n()` for all UI/text (enabling in-project translation).  
- **Input:** Configure input map for keyboard/controller (e.g. move, jump, interact). Document key bindings.  
- **Audio:** Categorize sounds into **Music**, **Ambient**, **SFX**, **UI**. Use 44.1kHz WAV/OGG. No hardcoded audio; control volumes by category (master, music, sfx). Implement heartbeat and footsteps with variable intensity.  
- **Assets:** Pixel-art sprites (e.g. 16×16 or 32×32 tiles, limited palette). Animations with sprite sheets. Placeholder assets must be replaced before final. Audio assets: ambient rain, footsteps, monster roars, UI clicks, etc.  
- **CI/Quality:** Set up automated checks: ensure the game builds and runs (Godot export), no script errors/warnings, lint code (e.g. static analysis). Follow Opencode guidelines: include `AGENTS.md`, `PROJECT.md`, and docs/ in version control, and configure `opencode.json` “instructions” to load relevant docs for the AI agent.  
- **Third-party:** Minimize dependencies. Use Godot’s built-in nodes/libraries. Any open-source plugins must be approved/licensed.

