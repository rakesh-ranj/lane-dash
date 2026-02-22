## GameManager autoload singleton.
## Manages game state, distance-based scoring, high scores, and car selection.
extends Node

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum State {
	MENU,
	CAR_SELECT,
	COUNTDOWN,
	PLAYING,
	PAUSED,
	FINISH,
	RESULTS,
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal state_changed(old_state: State, new_state: State)
signal score_changed(new_score: int)
signal obstacle_hit
signal obstacle_passed

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Points awarded per game-unit of distance traveled.
const POINTS_PER_UNIT: float = 10.0

## Save-file path for the persistent high score.
const HIGHSCORE_PATH: String = "user://highscore.save"

## Valid car colors the player may pick.
var VALID_CAR_COLORS: Array[String] = ["green", "red", "orange", "white"]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var current_state: State = State.MENU

## Currently selected car color (persists across runs until changed).
var selected_car_color: String = "green"

## Scene path for the selected car model (set by main menu before starting).
var selected_car: String = "res://assets/kenney_racing_kit/models/raceCarGreen.glb"

## High score loaded from / saved to disk.
var high_score: int = 0

# --- Per-run statistics (reset with reset_run) ---
var distance_traveled: float = 0.0
var current_speed: float = 0.0
var _run_start_time: float = 0.0

# --- Obstacle stats ---
var obstacle_bonus: int = 0
var obstacles_hit: int = 0
var obstacles_passed: int = 0

## Convenience alias used by UI scripts. Score is purely obstacle-based.
var score: int:
	get: return maxi(0, obstacle_bonus)

# ---------------------------------------------------------------------------
# Built-in callbacks
# ---------------------------------------------------------------------------

func _ready() -> void:
	load_high_score()

# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

## Transition to *new_state*. Emits [signal state_changed].
func change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	var old_state := current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)

# ---------------------------------------------------------------------------
# Run tracking
# ---------------------------------------------------------------------------

## Call when the run begins (first PLAYING state entered).
func start_run() -> void:
	_run_start_time = Time.get_ticks_msec() / 1000.0

## Add distance traveled this frame. Called by TrackManager.
func add_distance(dist: float) -> void:
	distance_traveled += dist

## Time elapsed since the run started.
func get_run_time() -> float:
	if _run_start_time <= 0.0:
		return 0.0
	return (Time.get_ticks_msec() / 1000.0) - _run_start_time

# ---------------------------------------------------------------------------
# Car selection
# ---------------------------------------------------------------------------

## Set the selected car color. Ignored if the color is not in VALID_CAR_COLORS.
func select_car_color(color: String) -> void:
	if color in VALID_CAR_COLORS:
		selected_car_color = color

# ---------------------------------------------------------------------------
# High score persistence
# ---------------------------------------------------------------------------

## Persist the high score to disk if the current score exceeds it.
func save_high_score() -> void:
	var s := score
	if s > high_score:
		high_score = s

	var file := FileAccess.open(HIGHSCORE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()

## Load the high score from disk. Called automatically in _ready().
func load_high_score() -> void:
	if not FileAccess.file_exists(HIGHSCORE_PATH):
		high_score = 0
		return

	var file := FileAccess.open(HIGHSCORE_PATH, FileAccess.READ)
	if file:
		high_score = file.get_32()
		file.close()
	else:
		high_score = 0

# ---------------------------------------------------------------------------
# Obstacle scoring
# ---------------------------------------------------------------------------

func on_obstacle_hit() -> void:
	obstacle_bonus -= 10
	obstacles_hit += 1
	obstacle_hit.emit()
	score_changed.emit(score)

func on_obstacle_passed() -> void:
	obstacle_bonus += 10
	obstacles_passed += 1
	obstacle_passed.emit()
	score_changed.emit(score)

# ---------------------------------------------------------------------------
# Run lifecycle
# ---------------------------------------------------------------------------

## Reset all per-run statistics. Call before starting a new run.
func reset_run() -> void:
	distance_traveled = 0.0
	current_speed = 0.0
	_run_start_time = 0.0
	obstacle_bonus = 0
	obstacles_hit = 0
	obstacles_passed = 0
	score_changed.emit(0)
