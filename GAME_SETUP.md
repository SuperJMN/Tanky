# Tanky - Game Setup Reference

## Screen & Physics

- **Viewport**: 720x480 pixels
- **Ground Level**: y=460 (StaticBody2D)
- **Ground Top** (for logic): y=435
- **Gravity**: 800.0

## Sprite Sizes & Scales

### Original Sizes
- **Tanky**: 32x32 (scale: 1.0)
- **Bomb**: 320x320 → scaled to 0.1 (32x32 effective)
- **Ship**: 108x64 → scaled to 0.5 (54x32 effective)
- **Background**: 2400x1600 → scaled to 0.3

### Collision Shapes
- **Tanky**: 32x32 rectangle
- **Bomb**: 30x30 rectangle
- **Ship**: 54x32 rectangle
- **Ground**: 1000x50 rectangle at y=460

## Controls

- **Arrow Keys**: Move left/right, Jump
- **Space**: Shoot
- **F1**: Switch weapon
- **Esc**: Quit

## Current Status

✅ Working:
- Physics and gravity
- Ground collision
- Player movement
- Enemy spawning
- Basic collision detection

⚠️ To Do:
- Link audio files
- Tanky walk animation (need sprite sheet)
- Shot/enemy collision damage
- Score tracking
- Lives system
- Explosion animations
