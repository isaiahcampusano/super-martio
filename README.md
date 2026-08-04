# Pocket Platformer

Pocket Platformer is an original, self-contained 2D platformer built with Godot 4.7.1 and GDScript. V1 contains one complete level, **Mosslight Run**, rendered with original procedural vector art and sound effects so it can be evaluated without external assets.

## Play locally

1. Install the standard build of Godot 4.7.1 and its export templates.
2. Open this folder in the Godot Project Manager.
3. Press **F6** to run an individual scene or **F5** to start from the main menu.

Command-line validation:

```text
godot --headless --path . --editor --quit
godot --headless --path . res://tests/run_tests.tscn
```

## Controls

| Action | Keyboard | Controller |
|---|---|---|
| Move | A/D or arrow keys | Left stick or D-pad |
| Jump | Space, W, or Up | Primary face button |
| Sprint | Shift or Z | Secondary face button |
| Crouch / enter doorway | S or Down | Stick or D-pad down |
| Pause | Escape | Start/menu |

## V1 features

- Acceleration, sprinting, variable jump height, coyote time, and jump buffering
- Safe crouch/stand collision handling
- Three lives, checkpoint respawning, game over, and full restart
- Four interaction types: Walker, Ledge Patroller, Spike Hazard, and two-hit Bruiser
- Stomp detection and bounce
- Fourteen Star Seeds, including four in a hidden sky-room
- Breakable blocks and two moving platforms
- Main menu, level select, HUD, pause, completion, and results interfaces
- ConfigFile persistence for completion, best time, and best collectible count
- Procedurally generated original placeholder art and sound effects
- Windows and single-threaded Web export presets
- Headless automated validation and GitHub Pages workflow

## Exports

```text
mkdir build/web build/windows
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Windows Desktop" build/windows/pocket-platformer.exe
```

Generated builds are ignored by Git. The Pages workflow builds the Web version from source and uploads `build/web` as the deployment artifact.

## Project status

This is a local V1 candidate. It has not been pushed or published. The repository owner must select a software license before public release; no license is implied by the current files.
