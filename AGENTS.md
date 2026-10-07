# AGENTS.md

Guidance for agents and contributors working on Tanky Reloaded.

## Project

- 2D platformer in **Godot 4.5** (GDScript). The player is Tanky, a self-driven toy tank with
  tracked, physics-based propulsion.
- Design intent:
  - The scene opens with Tanky falling onto the terrain, and the camera follows him.
  - The background is locked to `sprites/background.jpg`.
  - Levels evoke classic Mario/Sonic ramps, to show off traction.
  - Projectiles defeat on-screen enemies.
  - Single jump, no double jump.
  - Tanky is a heavy remote-control tank with a life of its own. He should feel weighty and
    jump lower than Mario or Sonic.
- Status: a playable prototype (one test level, enemy drones). It does not yet have damage, lives,
  slopes or a level goal.
- Backlog: GitHub issues, ordered in the roadmap issue
  [#29](https://github.com/SuperJMN/Tanky/issues/29). Work through them one at a time and
  reference the issue in commits.

## Toolchain

- Use **Godot 4.5.x** (4.5.2 is verified). `project.godot` declares the `4.5` feature.
  Opening the project with 4.6 or newer migrates it. Do not do that without an explicit
  decision; mention any engine bump in the commit message.
- Commands assume a `godot` executable on `PATH`. If you use the flatpak, replace `godot`
  with `flatpak run org.godotengine.Godot`.
- The bundled `addons/godot-git-plugin` loads on editor start and sets
  `core.filemode=true` in `.git/config`. If every file suddenly shows as modified with no
  content change, it is the executable bit, not real edits. Fix the file permissions
  (`chmod 644`) and do not commit mode changes (see #27).

## Commands

Run these from the repository root:

```bash
godot --path . -e                        # open the editor
godot --path .                           # run the main scene (scenes/main.tscn)
godot --headless --path . --import       # import assets and parse every script
godot --headless --path . --quit-after 300   # run the main scene for 300 frames, no window
```

The exit code of the headless commands is not reliable. Read their output and treat any line
with `SCRIPT ERROR`, `ERROR:` or `Parse Error` as a failure. In headless mode, `main.gd` and
`tanky.gd` skip music and cosmetic timers on purpose.

## Layout

| Path | Contents |
|---|---|
| `project.godot` | Project settings, input map, main scene. Single source of truth for configuration. |
| `scenes/main.tscn` + `scripts/main.gd` | Playfield: background, terrain, enemies, Tanky, music. |
| `scenes/tanky.tscn` + `scripts/tanky.gd` | Player rig and controller. |
| `scenes/projectile.tscn` + `scripts/projectile.gd` | Bullet (`Area2D`, own gravity). |
| `scenes/enemy_drone.tscn` + `scripts/enemy_drone.gd` | Patrolling, hovering drone. |
| `scenes/explosion.tscn` + `scripts/explosion.gd` | One-shot explosion effect with SFX. |
| `scenes/terrain/tile_map_layer.tscn` | Terrain chunk (`TileMapLayer`, 16 px tiles, instanced at scale 3). |
| `sprites/`, `sounds/` | Imported art and audio, with their `.import` files. |
| `audio/default_bus_layout.tres` | Audio buses. |

- Every scene has its script under `scripts/`, with the same name in `lower_snake_case`.
  New levels go under `scenes/`.
- Commit the `.import` and `.uid` files together with their assets and scripts. Never edit
  them by hand.
- `.godot/` is editor cache and is not committed.

## Architecture

### Units and tuning

- Scale: **100 px = 1 m**. Gravity is 980 px/s² (`project.godot`), i.e. 9.8 m/s².
- Tanky's body is 0.5 m (50 px) long. The constants at the top of `scripts/tanky.gd` are the
  source of truth for tuning:
  - speed from `MIN_SPEED` 150 px/s up to `MAX_SPEED` 500 px/s, reached over `ACCEL_TIME`;
  - `JUMP_HEIGHT` 150 px; every body of the rig takes off at `sqrt(2·g·h)` (damping leaves
    the real peak at ~135 px);
  - projectile speed 700 px/s; shot cooldown 0.35 s (`ShootTimer`);
  - cannon range −60° … 10°.
- None of these values is fixed by the design: the gameplay is still being explored. Tune
  them freely towards the "heavy tank" feel, keep the code comments in sync with the values,
  and write down the before/after numbers (see Validation).

### Tanky rig (`tanky.tscn`)

```
Tanky (Node2D, tanky.gd)
├─ RigidBody2D            chassis, mass 50, collision layer 2
│  ├─ Body                Hull, HeadRig (Head, Eye, Antenna), Cannon (CannonSprite, Muzzle)
│  ├─ BodyCollision       capsule raised so only the wheels touch the ground
│  ├─ BodyAnim            track sprite (visual only)
│  ├─ GroundCastFront / GroundCastRear (RayCast2D)
│  └─ JumpPlayer / ShootPlayer / CannonMovePlayer
├─ RearWheel / FrontWheel (RigidBody2D, mass 8)
├─ FrontJoint / RearJoint (PinJoint2D chassis ↔ wheels)
├─ FollowCamera (Camera2D, moved to the chassis every physics frame)
└─ ShootTimer
```

- Movement is force-based: torque on both wheels, plus a horizontal force on the chassis
  towards the target speed. Velocities are never set directly. In the air, a PD controller
  keeps the chassis level.
- Ground contact comes from the two raycasts (`_is_grounded()`): the surface normal must be
  close to "up" and Tanky must not be rising fast.
- The wheels are separate rigid bodies held by joints, siblings of the chassis. Never nest a
  physics body inside another one: the child gets teleported through the scene tree. Anything
  that teleports Tanky (for example a respawn) must move the chassis and both wheels, and
  reset their velocities.
- Visual effects such as the track compression on jump move sprites only, never the bodies.
- `tanky.gd` gets its children through `@export_node_path` properties set in the scene.
  Keep that pattern in that script. Other scripts may use `$Child`; follow whatever the file
  you are editing already does.
- Tanky always faces right for now. Whether he can turn around is pending decision #21.

### Combat contract

- A projectile hits whatever it overlaps (terrain or enemies). If the target has a
  `hit_by_projectile(projectile)` method, it calls it, then spawns an `Explosion` and frees
  itself. It has two exceptions: it ignores its `shooter`, and it ignores terrain while
  moving upward (#14).
- Enemies implement `hit_by_projectile`, join the `enemies` group and manage their own death.

### Collision layers

The layers have no names in `project.godot`. These are their meanings:

| Layer (bit value) | Used by |
|---|---|
| 1 (1) | Terrain tiles |
| 2 (2) | Tanky chassis and wheels |
| 3 (4) | Projectiles |
| 4 (8) | Enemies |

Projectiles and drones use mask 9 (terrain + enemies). Keep the table up to date when adding
layers, or give the layers names in `project.godot`.

### Input map (`project.godot`)

| Action | Keyboard | Gamepad |
|---|---|---|
| `move_left` / `move_right` | A / D, ← / → | D-pad ← / →, left stick X |
| `jump` | W, Space | Button 0 (A / Cross) |
| `shoot` | Z, X, Enter | Button 2 (X / Square) |
| `aim_up` / `aim_down` | ↑ / ↓ | none yet (#15) |

Always read input through actions (`Input.get_axis`, `Input.is_action_*`), never through raw
keys.

### Audio

- Buses: `Master`, `Music` (background track `sounds/ladynavigation.mp3`), `SFX`
  (all effects).
- Every new player must go to `Music` or `SFX`. If a new bus is needed, add it to
  `audio/default_bus_layout.tres` and document it here.

## Coding style

- GDScript for Godot 4.5, tab indentation, lines under ~100 characters, static typing
  (`:=`, typed parameters and return values).
- Naming:
  - classes and scenes in PascalCase;
  - functions and variables in snake_case, with a `_` prefix for private ones;
  - constants in SCREAMING_SNAKE_CASE;
  - resources with descriptive snake_case names (`tanky_frames.tres`).
- Do not name a local variable after a property of the node, such as `scale`, `position` or
  `rotation`. It hides the property and produces a warning.
- Load dependencies with `preload("res://...")`; never use paths outside `res://`.
- Comments in English.

## Validation

1. Run the headless import and the headless run (see Commands), and check that neither
   prints any errors.
2. Play `scenes/main.tscn` and try moving, jumping, shooting and aiming with the keyboard and
   with a gamepad.
3. For physics changes, write down the before/after values (heights, speeds, times) in the
   commit or PR.

An agent with an editor-side Godot MCP (see "Local-only tooling") can also play the scene and
check the result: take screenshots and read live node properties of the running game. Use a
normal play: a play with `quiet` parks the window off-screen, and its screenshots can come
out frozen.

## Git, commits and pull requests

- The default branch is `master`.
- Commits: imperative mood, with a Conventional Commits prefix as in recent history
  (`fix: scale enemy drones and face patrol direction`, `feat: add enemy drones`). Add a short
  body when the reason is not obvious, and reference the issue (`Fixes #12`).
- Only stage what belongs to the change. Use `git add -p` for `project.godot`
  (see "Local-only tooling").
- PRs: what changes for the player, which scenes and scripts change, and how it was validated
  (command output, screenshots or GIFs).
- Repository content (commits, issues, PRs, docs, code comments) is written in English.
- Do not credit AI agents anywhere: no `Co-Authored-By` trailers, no "generated with" notes.

## Assets

- Art goes in `sprites/` and audio in `sounds/`. Commit them with their `.import` files.
- Note the source and license of every third-party asset in its commit message.
- Some current assets are placeholders taken from Nintendo games: the Super Mario Bros. 2
  tileset and the SMW/NSMB sound effects. They cannot ship in a public release (#26).

## Local-only tooling

On some machines the **Beckett** Godot MCP is installed for agent use (inspect scenes, run the
game, take screenshots). It is deliberately **not** part of the repository:

- These files must never be committed: `addons/beckett/`, `.beckett/` (it holds an auth
  token) and `.mcp.json`. They are listed in `.git/info/exclude`.
- Enabling the plugin also edits `project.godot`: an `[autoload]` section with
  `BeckettRuntime`, a `[beckett]` section and `[editor_plugins]`. Leave those changes out of
  every commit.
- The MCP server runs inside the editor. Keep an editor open (`godot --path . -e`) while
  using it.
