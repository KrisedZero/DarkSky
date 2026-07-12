# Audio Pipeline & Asset Provenance

This document records how every file under `res://assets/audio/` was sourced, licensed,
and converted so the project ships with **valid PCM WAV** assets (Godot 4 import requirement)
instead of the original invalid/non-PCM placeholders.

## Why this exists
The original 17 `.wav` files were corrupt / non-PCM and failed Godot import with errors such as
`Format not supported for WAVE file (not PCM)` and `Can't save empty resource`. They have been
replaced with real, royalty-free recordings converted to 44.1 kHz / 16-bit PCM WAV.

## Tooling
- Conversion: `ffmpeg` (local build, full static). Command pattern used:
  - Stereo (music / ambient / game-over):
    `ffmpeg -y -i <src> -ar 44100 -sample_fmt s16 -ac 2 <out>.wav`
  - Mono (one-shot SFX):
    `ffmpeg -y -i <src> -ar 44100 -sample_fmt s16 -ac 1 <out>.wav`
- Note: ffmpeg cannot open the project's Cyrillic path (`пример`), so conversion was done to a
  temp ASCII dir and the resulting WAV was copied into `assets/audio/` via the OS shell.

## Asset mapping (17 files)

| Target file (`assets/audio/`) | Source pack | License | Original file | Channels |
|---|---|---|---|---|
| `music_menu.wav` | Soundimage.org | CC-BY 4.0 | `Surreal-Game-Menu.mp3` | stereo |
| `music_floor.wav` | Soundimage.org | CC-BY 4.0 | `Lurking-in-the-Shadows.mp3` | stereo |
| `ambient_rain.wav` | Soundimage.org | CC-BY 4.0 | `Gentle-Rain_Looping.mp3` | stereo |
| `ambient_wind.wav` | Soundimage.org | CC-BY 4.0 | `Wispy_Wind_1.mp3` | stereo |
| `ambient_floor.wav` | Soundimage.org | CC-BY 4.0 | `Eeroioe-Industrial-Drone.mp3` | stereo |
| `sfx_door_open.wav` | Soundimage.org | CC-BY 4.0 | `Creeky-Interior-Door.mp3` | mono |
| `sfx_heartbeat.wav` | Soundimage.org | CC-BY 4.0 | `Creepy_Percussion_1.mp3` | mono |
| `sfx_detection.wav` | Soundimage.org | CC-BY 4.0 | `Creepy2.mp3` | mono |
| `sfx_game_over.wav` | Soundimage.org | CC-BY 4.0 | `Horrible-Realization.mp3` | stereo |
| `sfx_ui_hover.wav` | Kenney (UI Audio) | CC0 | `Audio/rollover1.ogg` | mono |
| `sfx_ui_confirm.wav` | Kenney (UI Audio) | CC0 | `Audio/click1.ogg` | mono |
| `sfx_lantern_on.wav` | Kenney (Interface Sounds) | CC0 | `Audio/switch_001.ogg` | mono |
| `sfx_lantern_off.wav` | Kenney (Interface Sounds) | CC0 | `Audio/switch_002.ogg` | mono |
| `sfx_pickup.wav` | Kenney (Impact Sounds) | CC0 | `Audio/impactGeneric_light_000.ogg` | mono |
| `sfx_door_lock.wav` | Kenney (Impact Sounds) | CC0 | `Audio/impactWood_heavy_000.ogg` | mono |
| `sfx_footstep_player.wav` | Kenney (Impact Sounds) | CC0 | `Audio/footstep_concrete_000.ogg` | mono |
| `sfx_footstep_monster.wav` | Kenney (Impact Sounds) | CC0 | `Audio/footstep_wood_003.ogg` | mono |

All Soundimage tracks are by **Eric Matyas** (https://soundimage.org), licensed CC-BY 4.0.
Kenney packs are CC0 (no attribution required); see `assets/audio/LICENSE_KENNEY.txt`.

## Substitutions / notes
- `sfx_heartbeat` uses a creepy percussion loop as a **heartbeat proxy** — no literal CC0 heartbeat
  recording was found via the available sources. Swap in a dedicated heartbeat asset if desired.
- `sfx_detection` uses a creepy stinger as a monster-alert cue.
- `ambient_floor` uses an industrial drone as an ominous floor tone.

## Integration
1. Valid WAVs were placed at the exact filenames `AudioManager` loads
   (`res://assets/audio/<name>.wav`). **No gameplay code or `audio_manager.gd` was changed.**
2. Stale import metadata was cleared: all `assets/audio/*.wav.import` and the matching
   `.godot/imported/*<name>.wav*` cache entries were deleted so Godot reimports cleanly.

## One-time manual step (looping)
`AudioManager` does not set `stream.loop` at runtime, so looping is controlled by the imported
resource. After opening the project in Godot, for these five files enable **Loop** in the
Import dock (then click Reimport) — setting persists in the generated `.import`:
- `music_menu.wav`, `music_floor.wav`
- `ambient_rain.wav`, `ambient_wind.wav`, `ambient_floor.wav`

Without this, music/ambient play once and stop (functional, but not seamless).

## Re-running conversion
If you need to re-derive the WAVs:
```
ffmpeg -y -i <source.ogg|mp3> -ar 44100 -sample_fmt s16 -ac <1|2> assets/audio/<name>.wav
```
