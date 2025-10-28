# Repository Guidelines

## Core Gameplay Requirements
- 2D platformer built with Godot 4.5 flatpak featuring Tanky, a self-driven toy tank.
- Realistic physics: tracked propulsion, 0.5 m body length, 2 body-lengths/sec top speed, single jump reaching 1.5 m, no double jumps.
- Scene opens with Tanky falling onto terrain; camera follows; background locked to `sprites/background.jpg`.
- Use `sprites/tanky_spritesheet.png` for movement animation, other art from `sprites/`, music `sounds/ladynavigation.mp3`, and jump SFX (`jump.wav` or `jump.mp3`).
- Levels evoke classic Mario/Sonic ramps, enabling traction showcases; projectiles defeat on-screen enemies.
- Keep assets and code organized for scalable expansion with minimal maintenance overhead.

## Project Structure & Module Organization
- `project.godot` is the single source of truth for project settings, input map, and default main scene (`scenes/main.tscn`).
- `scenes/` hosts gameplay scenes: `tanky.tscn` (player rig), `projectile.tscn` (bullets), and `main.tscn` (playfield). Create new levels under this folder and reference them via `project.godot`.
- `scripts/` contains GDScript logic mirroring node names (`tanky.gd`, `projectile.gd`, `main.gd`). Keep script filenames in lower_snake_case and align them with their owning scene.
- `sprites/`, `sounds/`, and `audio/` hold imported art/audio assets and bus layouts. Preserve existing `.import` artifacts so Godot can reuse metadata.
- `.godot/` caches editor state; only commit deliberate editor configurations.

## Build, Test, and Development Commands
- Launch editor: `flatpak run org.godotengine.Godot --path /mnt/fast/Repos/SuperJMN/TankyReloaded`.
- Run current main scene: press `F5` in the editor or invoke `flatpak run org.godotengine.Godot --path <repo> --editor` and start the scene there.
- Validate scripts headlessly: `flatpak run org.godotengine.Godot --headless --quit --path <repo>` to surface syntax/setup errors without UI.

## Coding Style & Naming Conventions
- Use Godot 4.5 GDScript with tabs (default indentation) and keep lines under ~100 characters.
- Name classes and scenes in PascalCase (`Tanky`, `Projectile`), nodes using Godot’s canonical names (`Camera2D`), and exported resources with descriptive snake_case (`tanky_frames.tres`).
- Preload dependencies using `preload("res://...")`; avoid hard-coded relative paths outside `res://`.

## Testing Guidelines
- No automated unit suite yet; rely on headless validation plus manual playthroughs starting from `scenes/main.tscn`.
- Exercise core interactions (move, jump, shoot) using both keyboard arrows and gamepad D-pad bindings.
- Document any physics tuning or input regressions in issue/PR discussion so future testers can reproduce.

## Commit & Pull Request Guidelines
- Write imperative commits (`Add wheel traction material`, `Tune jump impulse`) and mention Godot version bumps explicitly.
- PRs must outline gameplay-impacting changes, touched scenes/scripts, and validation evidence (command output, GIFs, or screenshots).
- Store new assets in the appropriate folder, include licensing notes for third-party media, and update `project.godot` if input or bus layouts change.

## Asset & Configuration Tips
- Maintain 100 px ≈ 1 m scaling used in `tanky.gd`; adjust physics constants consistently across new scripts.
- When adding audio, route streams through existing buses (`Music`, `SFX`) or document new buses in `audio/default_bus_layout.tres`.
