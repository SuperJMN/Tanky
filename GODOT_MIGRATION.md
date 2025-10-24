# Tanky - Godot 4.5 Migration

This project has been migrated from MonoGame/XNA to Godot 4.5 using GDScript.

## Project Structure

```
├── project.godot           # Main project configuration
├── scenes/                 # Godot scene files (.tscn)
│   ├── main.tscn          # Main game scene (to be created in editor)
│   ├── enemies/
│   │   ├── ship.tscn      # Ship enemy scene
│   │   └── bomb.tscn      # Bomb enemy scene
│   ├── shots/
│   │   └── regular_shot.tscn
│   └── effects/
│       ├── explosion.tscn
│       └── aerial_explosion.tscn
├── scripts/                # GDScript files
│   ├── constants.gd
│   ├── game_host.gd
│   ├── main_stage.gd
│   ├── tanky.gd
│   ├── ship.gd
│   ├── bomb.gd
│   ├── regular_shot.gd
│   ├── explosion.gd
│   ├── aerial_explosion.gd
│   └── ui.gd
└── assets/                 # Game assets
    ├── sprites/            # Sprite textures (PNG files)
    └── sounds/             # Audio files (OGG/WAV)
```

## Next Steps

### 1. Open in Godot Editor
```bash
godot4 project.godot
```

### 2. Create Scene Files

You'll need to create the following scenes in the Godot editor:

#### Main Scene (`scenes/main.tscn`)
- Root: `Node` with `game_host.gd` attached
- Child: `Node2D` (MainStage) with `main_stage.gd`
  - Background sprite
  - `CharacterBody2D` (Tanky) with `tanky.gd`
  - `CanvasLayer` (UI) with `ui.gd`
- Child: `AudioStreamPlayer` (BGM)

#### Tanky Scene (Part of main scene)
- Root: `CharacterBody2D` with `tanky.gd`
- Children:
  - `Sprite2D` - tanky sprite
  - `CollisionShape2D` - rectangular collision
  - `AudioStreamPlayer` (JumpSound)
  - `AudioStreamPlayer` (WalkSound)
  - `AudioStreamPlayer` (DieSound)

#### Ship Scene (`scenes/enemies/ship.tscn`)
- Root: `Area2D` with `ship.gd`
- Children:
  - `Sprite2D`
  - `CollisionShape2D`

#### Bomb Scene (`scenes/enemies/bomb.tscn`)
- Root: `RigidBody2D` with `bomb.gd`
- Children:
  - `Sprite2D`
  - `CollisionShape2D`

#### Shot Scene (`scenes/shots/regular_shot.tscn`)
- Root: `Area2D` with `regular_shot.gd`
- Children:
  - `Sprite2D`
  - `CollisionShape2D`

#### Explosion Scenes (`scenes/effects/`)
- Similar structure with `Area2D` root

### 3. Import Assets

Copy your assets from the MonoGame project:

```bash
# Copy sprites
cp Tanky.App/Content/*.png assets/sprites/

# Copy sounds (may need conversion to OGG)
cp Tanky.App/Content/sounds/*.* assets/sounds/
```

Note: Godot prefers OGG format for audio. Convert WAV/MP3 files if needed.

### 4. Configure Sprites

For each scene with sprites:
1. Set the texture in `Sprite2D`
2. For animated sprites (like Tanky walk), use `AtlasTexture` or `AnimatedSprite2D`
3. Adjust sprite regions for tile-based spritesheets

### 5. Setup Physics Layers

Already configured in `project.godot`:
- Layer 1: Player
- Layer 2: Enemy  
- Layer 3: PlayerShot
- Layer 4: EnemyShot
- Layer 5: Explosion

### 6. AutoLoad Constants

Add Constants as AutoLoad:
1. Project → Project Settings → AutoLoad
2. Add `scripts/constants.gd` as "Constants"

## Key Differences from MonoGame

### Signal System (instead of Reactive Extensions)
- MonoGame: `IObservable<T>` / `ISubject<T>`
- Godot: `signal` keyword and `.connect()`

### Physics
- MonoGame: Manual collision detection
- Godot: Built-in physics with `CharacterBody2D`, `RigidBody2D`, `Area2D`

### Scene Tree
- MonoGame: Flat `Stage` with `StageObject` list
- Godot: Hierarchical scene tree with parent-child nodes

### Input
- MonoGame: `Keyboard.GetState()`
- Godot: `Input.is_action_pressed()` with configured actions

### Audio
- MonoGame: `SoundEffect`, `MediaPlayer`
- Godot: `AudioStreamPlayer`, `AudioStreamPlayer2D`

## Testing

Once scenes are created:
1. Press F5 to run the game
2. Test controls:
   - Arrow keys: Move/Jump
   - Space: Shoot
   - F1: Switch weapon
   - Esc: Quit

## Completed Setup

- [x] Create all scene files (.tscn)
- [x] Import sprites from MonoGame project (17 sprites)
- [x] Import audio files (12 sound files)
- [x] Setup Constants as AutoLoad
- [x] Normalize asset filenames
- [x] Configure collision layers
- [x] Setup input actions
- [x] Fix RigidBody2D collision detection (contact_monitor enabled)
- [x] Fix CharacterBody2D collision handling
- [x] Adjust sprite scales for proper sizing
- [x] Add DetectionArea to Bomb for shot detection

## Known TODOs

- [ ] Setup sprite animations for Tanky walk cycle (use AnimatedSprite2D)
- [ ] Link audio files to sound nodes in scenes
- [ ] Add other weapon types (FireBall, SmallShot)
- [ ] Fine-tune physics values
- [ ] Polish explosion animations
- [ ] Test and adjust gameplay balance
