# Input Bindings

> Authored in M2.T3. Actions are defined in `project.godot` `[input]`. The M4 Input layer consumes these
> action names only (no raw key polling elsewhere).

| Action | Keyboard | Controller | Purpose |
|--------|----------|------------|---------|
| `move_up` | W | D-Pad Up | Move north |
| `move_down` | S | D-Pad Down | Move south |
| `move_left` | A | D-Pad Left | Move west |
| `move_right` | D | D-Pad Right | Move east |
| `run` | Shift | — | Sprint |
| `interact` | E | — | Chests, doors, use |
| `lamp_toggle` | F | — | Turn lantern on/off |
| `hide` | C | — | Hide in furniture |
| `pause` | Esc | — | Pause menu |
| `ui_confirm` | Enter | A / Cross | Menu confirm |
| `ui_cancel` | Esc | B / Circle | Menu back |

Notes:
- No duplicate physical bindings among gameplay actions (`pause` and `ui_cancel` intentionally share Esc,
  which is contextual: gameplay vs menu).
- Controller support currently covers movement + menu confirm/cancel; full gamepad mapping and rebinding UI
  are future (post-M2) work.
