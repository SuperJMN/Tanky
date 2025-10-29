# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

TankyReloaded is a 2D platformer built with Godot 4.5 flatpak. The player controls Tanky, a self-driven toy tank with realistic physics (tracked propulsion, constrained jumping, projectile combat). The game features classic Mario/Sonic-style ramps and enemy encounters.

## Development Commands

### Launch and Run
```bash
# Open Godot editor
flatpak run org.godotengine.Godot --path /mnt/fast/Repos/SuperJMN/TankyReloaded

# Run from editor
# Press F5 or use the play button
```

### Validation
```bash
# Validate scripts headlessly (surface syntax/setup errors without UI)
flatpak run org.godotengine.Godot --headless --quit --path /mnt/fast/Repos/SuperJMN/TankyReloaded
```

## Architecture

### Core Physics Constants
The game uses a **100 pixels = 1 meter** scale factor (`PIXELS_PER_METER := 100.0` in `tanky.gd`). All physics constants must maintain consistency with this scaling:
- Tanky body length: 0.5 m (50 px)
- Top speed: 3 body-lengths/sec
- Jump height: 1.5 m (150 px)
- Default gravity: 980.0 px/s² (set in `project.godot`)

When adding new physics-based entities, always derive impulses and forces using these established constants.

### Scene-Script Architecture
The project follows a strict 1:1 mapping between scenes and scripts:
- **`scenes/tanky.tscn`** ↔ **`scripts/tanky.gd`**: Player rig with RigidBody2D chassis + wheel physics
- **`scenes/projectile.tscn`** ↔ **`scripts/projectile.gd`**: Bullet Area2D with velocity-based movement
- **`scenes/main.tscn`** ↔ **`scripts/main.gd`**: Main playfield, camera setup, and level geometry

Each scene node tree is designed to be instantiated by its paired script. The script accesses child nodes via `@onready` bindings (see `tanky.gd` for reference pattern).

### Player Controller (`tanky.gd`)
The player rig is composed of:
- `Chassis`: Central RigidBody2D with camera and sprite
- `FrontWheel` / `RearWheel`: RigidBody2Ds driven by torque forces
- Ground detection via two `RayCast2D` nodes (`GroundCastFront`, `GroundCastRear`)

Movement is torque-driven rather than direct velocity assignment. The `_apply_drive` method applies torque to wheels, and `_apply_drag` provides air/ground control feel. This allows realistic traction simulation.

Animation state is determined by velocity thresholds and ground contact in `_update_orientation()`, which dynamically selects `idle`, `move`, or `jump` animations from `tanky_spritesheet.png`.

### Input System
Input actions are defined in `project.godot`:
- **move_left** / **move_right**: A/D keys, arrow keys, gamepad axis/D-pad
- **jump**: W, Space, gamepad button 0
- **shoot**: Z/X, gamepad button 2

All input polling uses `Input.get_axis()` or `Input.is_action_*()` for consistent keyboard + gamepad support.

### Audio System
Audio buses are defined in `audio/default_bus_layout.tres`. Two buses exist:
- **Music**: Background looping track (`sounds/ladynavigation.mp3`)
- **SFX**: Jump and shoot sounds

Route new audio streams through these buses rather than adding ad-hoc players.

## Coding Standards

### GDScript Style
- **Indentation**: Tabs (Godot default)
- **Line length**: ~100 characters
- **Naming**:
  - Classes/scenes: PascalCase (`Tanky`, `Projectile`)
  - Methods/variables: snake_case (`_is_grounded`, `move_input`)
  - Private members: prefix with `_` (no trailing underscores)
  - Constants: SCREAMING_SNAKE_CASE (`MAX_SPEED`, `JUMP_HEIGHT_METERS`)
- **Resource paths**: Always use `res://` protocol and `preload()` for scenes/assets

### Node Access Pattern
```gdscript
@onready var chassis: RigidBody2D = $Chassis
@onready var sprite: AnimatedSprite2D = $Chassis/AnimatedSprite2D
```
Use `@onready` to bind nodes once in `_ready()` rather than repeated `get_node()` calls.

## Testing

No automated test suite exists. Validation workflow:
1. Run headless validation command (see above)
2. Manual playthrough from `scenes/main.tscn`
3. Exercise all inputs: keyboard arrows + WASD + gamepad
4. Verify physics tuning by observing jump height (should reach ~1.5m platforms) and speed caps

Document physics regressions in PR descriptions with before/after measurements.

## Asset Management

### Required Assets
- `sprites/tanky_spritesheet.png`: 32x32 frame strip for movement animation
- `sprites/background.jpg`: Fixed parallax background
- `sounds/ladynavigation.mp3`: Background music
- `sounds/jump.wav` or `sounds/jump.mp3`: Jump SFX

### Import Artifacts
`.import` files in `sprites/` and `sounds/` contain Godot's import metadata. Do not manually edit or delete these; Godot regenerates them as needed.

### Adding New Assets
1. Place files in appropriate folder (`sprites/`, `sounds/`, `audio/`)
2. If adding audio, route through existing `Music` or `SFX` buses
3. Update `project.godot` only if adding new input actions or bus layouts
4. Include licensing notes for third-party media in commit message

## Commit Conventions

- Use imperative mood: `Add wheel traction material`, `Tune jump impulse`
- Mention Godot version changes explicitly: `Upgrade to Godot 4.5.1`
- For physics changes, include before/after values: `Increase jump impulse from 1200 to 1350`
- Asset additions should note source/license: `Add jump.mp3 (CC0 from freesound.org)`

## Pull Request Guidelines

PRs must include:
1. **Gameplay impact summary**: What changed for the player?
2. **Touched files list**: Scenes, scripts, assets modified
3. **Validation evidence**: Command output, GIFs, or screenshots demonstrating changes
4. **Physics measurements** (if applicable): Jump heights, speed values, cooldown timings
