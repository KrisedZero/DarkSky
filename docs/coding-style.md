
## coding-style.md  
```markdown
# Coding Style Guidelines

- **Godot Conventions:** Follow GDScript style: use **snake_case** for filenames, functions, and variables, and **PascalCase** for class and node names. Prepend `_` for private or virtual methods. Use signals for event callbacks.  
- **Function Length:** Keep functions concise (ideally ≤50 lines). Prefer splitting complex logic into smaller helpers.  
- **Composition Over Inheritance:** Favor composing nodes and resources; avoid deep inheritance.  
- **No “Magic”:** Avoid magic numbers/strings. Define constants for configurable values. All tunable parameters (speeds, timers, UI text) should be exported or driven by config files.  
- **Readability:** Use clear, descriptive names. Keep classes focused on a single responsibility. Minimize nested conditionals; prefer early returns. Document public methods with comments.  
- **Asset Placeholders:** If an asset (sprite, sound) is missing, use a clearly named placeholder and mark with TODO comments.  
- **Testing & Linting:** Write unit tests where possible (e.g. logic functions). Ensure the code compiles with no lint warnings. Use Godot’s built-in debugging tools and automated test scenes.  
- **Version Control / Commits:** Keep changesets small and focused. As Atlassian recommends, smaller PRs simplify review.  Commit messages should state *what* changed and *why* (not just *how*). For example: `Fixed player detection logic: now hides correctly under wardrobes`.  
- **Pull Requests:** Limit PR size to a single feature or bugfix. Include summary descriptions. Review code with a checklist (compiles, no unused code, etc).  
- **Examples (GDScript idioms, Godot 4):**  
  ```gdscript
  # Signal example
  signal monster_alerted
  # Constants
  const MAX_LANTERN_OIL: float = 600.0  # seconds (10 minutes)
  # Class
  class_name PlayerController
  extends CharacterBody2D
  func _ready():
      # Exported variable with default value (Godot 4 syntax)
      @export var max_energy: int = 100
      # Scenes or resources preloaded
      const MonsterScene := preload("res://scenes/Monster.tscn")
      # ...
  func _process(delta: float) -> void:
      # Process logic here
      pass
