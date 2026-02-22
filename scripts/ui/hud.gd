extends Control
## HUD overlay shown during gameplay.
## Displays score, speed in MPH, distance traveled, and elapsed time.

@onready var score_label: Label = $MarginContainer/TopBar/ScoreLabel
@onready var speed_label: Label = $MarginContainer/TopBar/SpeedLabel
@onready var distance_label: Label = $MarginContainer/BottomBar/DistanceLabel
@onready var time_label: Label = $MarginContainer/BottomBar/TimeLabel

## Current value displayed on the score label (smoothly animated toward target).
var displayed_score: int = 0
## The actual score we are animating toward.
var target_score: int = 0


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.obstacle_hit.connect(_on_obstacle_hit)


func _process(_delta: float) -> void:
	# Animate the displayed score toward the real score.
	if displayed_score != target_score:
		var diff: int = target_score - displayed_score
		var step: int = maxi(absi(diff) / 8, 1)
		if diff > 0:
			displayed_score = mini(displayed_score + step, target_score)
		else:
			displayed_score = maxi(displayed_score - step, target_score)

	score_label.text = "SCORE: %d" % displayed_score

	# Speed display – convert internal speed units to MPH.
	var speed_raw: float = GameManager.current_speed
	var speed_mph: float = speed_raw * 3.28 * 3.0 * 0.681818
	speed_label.text = "%d MPH" % int(speed_mph)

	# Distance traveled (1 game unit ≈ 1 meter).
	var dist: float = GameManager.distance_traveled
	distance_label.text = "DIST: %d m" % int(dist)

	# Run time.
	var run_time: float = GameManager.get_run_time()
	time_label.text = "TIME: %s" % _format_time(run_time)


# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------

func _on_score_changed(new_score: int) -> void:
	target_score = new_score


func _on_state_changed(_old_state, new_state) -> void:
	visible = (new_state == GameManager.State.PLAYING or new_state == GameManager.State.PAUSED)

func _on_obstacle_hit() -> void:
	var tw := create_tween()
	tw.tween_property(score_label, "modulate", Color.RED, 0.05)
	tw.tween_property(score_label, "modulate", Color.WHITE, 0.3)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: float = fmod(seconds, 60.0)
	return "%d:%05.2f" % [mins, secs]
