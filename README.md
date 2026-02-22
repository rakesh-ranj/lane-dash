# Lane Dash

A 3D endless car racing game built with Godot 4.x. Dodge obstacles across three lanes, rack up points, and chase your high score.

<p align="center">
  <img src="media/gameplay.gif" alt="Lane Dash gameplay" width="600">
</p>

Built with [Kenney Racing Kit](https://kenney.nl/assets/racing-kit) and [Quaternius Textured LowPoly Trees](https://quaternius.itch.io/textured-lowpoly-trees) assets (CC0 licensed).

## Gameplay

- Drive an endless straight road that scrolls toward you
- Steer left and right to dodge barriers and pylons
- Obstacles appear on all three lanes in a rotating pattern
- Earn points for every obstacle you dodge, lose points for every hit
- End your run from the pause menu and see your stats

## Controls

| Key | Action |
|-----|--------|
| A / Left Arrow | Steer left |
| D / Right Arrow | Steer right |
| W / Up Arrow | Accelerate |
| S / Down Arrow | Brake |
| Escape | Pause |

## Running the Game

1. Install [Godot 4.x](https://godotengine.org/download/) (4.6+)
2. Clone this repository
3. Open the project in Godot (`project.godot`)
4. Press F5 to run

## Project Structure

```
scripts/
  autoload/game_manager.gd   # Game state, scoring, high score persistence
  player/player_car.gd       # Lateral movement, speed control
  track/track_manager.gd     # Treadmill road scroller, obstacles, decorations
  camera/camera_rig.gd       # Chase camera with dynamic FOV
  game_controller.gd         # Pause, resume, state transitions
  ui/                        # HUD, main menu, results screen, countdown
  obstacles/obstacle.gd      # Obstacle hit detection
scenes/                      # Godot scene files (.tscn)
assets/kenney_racing_kit/    # 3D models (GLB), textures
```

## Credits

- Game assets: [Kenney Racing Kit](https://kenney.nl/assets/racing-kit) (CC0 1.0)
- Tree models: [Quaternius Textured LowPoly Trees](https://quaternius.itch.io/textured-lowpoly-trees) (CC0)
- Engine: [Godot Engine](https://godotengine.org/)
