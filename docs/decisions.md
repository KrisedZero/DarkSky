This document records key architecture and design decisions (ADR = Architecture Decision Record).

ADR-001: Engine – Use Godot Engine 4.7. Rationale: modern 2D support, active development, free and portable.
ADR-002: Camera & View – Top-down orthographic. Rationale: simplifies level design and fits puzzle/horror theme.
ADR-003: Resolution – 320×180 (16:9) base. Rationale: Crisp pixel art style; common retro resolution.
ADR-004: Pixel Art Settings – Nearest-neighbor filtering, integer scaling enabled. Rationale: Preserve pixel fidelity.
ADR-005: Save Format – JSON. Rationale: Human-readable, easy debugging.
ADR-006: Procedural Generation – Use random seeds per floor. Rationale: Replayability and unpredictability.
ADR-007: Stealth Mechanic – Hiding (under furniture / on balconies) over combat. Rationale: Matches horror-survival tone.
ADR-008: Resource Limits – Finite lantern oil (10 min default) and food. Rationale: Pressure and strategy.
ADR-009: Difficulty Variant – “Blood Codex” mode (hard). Rationale: Optional challenge & achievement.
ADR-010: Single Player Only. Rationale: Focus on narrative and atmosphere; no networking.

ADR-011: Missing Reference Documents — Created README.md and docs/world.md. AGENT.md (singular) is canonical.
ADR-012: Godot 4 Export Syntax — Use @export (Godot 4) not export() (Godot 3). See coding-style.md.
ADR-013: Chase Speed Design — Monster chase 140 px/s < player run 180 px/s is intentional. Tension from energy management and positioning, not raw speed. See conflicts-log C4.
ADR-014: No Health System — Player has one life. Caught = death (no HP bar). PLAYER_MAX_HEALTH constant retained for future use only.
ADR-015: Roof is Win State — Reaching the roof triggers the ending and credits (not Game Over). See conflicts-log C7.
ADR-016: Danger Sense is Permanent — Once purchased from the merchant, the directional aura persists for the run (no timer). See conflicts-log C9.
ADR-017: Achievement Name — "Bloodbringer" (not "Blood Patron"). See conflicts-log C10.
ADR-018: Data-Driven Balancing — All gameplay tunables live in the BalancingConfig Resource
(res://config/balancing.tres, M27), loaded and mirrored by the Config autoload. Gameplay code
reads Config.X unchanged; rebalancing edits the .tres, not code. Resolved provisional values:
LAMP_OFF_DETECTION_FACTOR = 0.5 (lantern off halves effective detection); LANTERN_RADIUS_TILES = 5
(fills 320x180 viewport at 32px); CLOAK_USES = 1 ("1 hit", balancing.md); Blood Mode factors
detect 1.5x / energy 1.5x / monster speed 1.2x (monster.md). DANGER_SENSE_DURATION removed as dead
— Danger Sense is permanent per ADR-016. Loot oil small:large = 4:1 (loot_oil_small_ratio = 0.8).

(Update this log whenever major changes are made. Agents should consult this before altering foundational choices.)