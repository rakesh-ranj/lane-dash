extends Control
## Results / game-over screen.
## Displays distance-based stats with staggered reveal animations and allows
## retry or returning to the main menu.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var distance_label: Label = $VBoxContainer/StatsContainer/DistanceLabel
@onready var total_time_label: Label = $VBoxContainer/StatsContainer/TotalTimeLabel
@onready var score_label: Label = $VBoxContainer/StatsContainer/ScoreLabel
@onready var obstacles_dodged_label: Label = $VBoxContainer/StatsContainer/ObstaclesDodgedLabel
@onready var obstacles_hit_label: Label = $VBoxContainer/StatsContainer/ObstaclesHitLabel
@onready var high_score_label: Label = $VBoxContainer/StatsContainer/HighScoreLabel
@onready var new_high_score_label: Label = $VBoxContainer/NewHighScoreLabel
@onready var retry_button: Button = $VBoxContainer/ButtonContainer/RetryButton
@onready var menu_button: Button = $VBoxContainer/ButtonContainer/MenuButton


func _ready() -> void:
	# Wire up buttons.
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)

	# Gather stats from GameManager.
	var final_score: int = GameManager.score
	var run_time: float = GameManager.get_run_time()
	var dist: float = GameManager.distance_traveled
	var high_score: int = GameManager.high_score
	var is_new_high: bool = (final_score >= high_score and final_score > 0)

	var dodged: int = GameManager.obstacles_passed
	var hit: int = GameManager.obstacles_hit

	# Prepare labels.
	title_label.text = "RUN COMPLETE!"
	distance_label.text = "Distance: %d m" % int(dist)
	total_time_label.text = "Time: %s" % _format_time(run_time)
	score_label.text = "Score: %d" % final_score
	obstacles_dodged_label.text = "Obstacles Dodged: %d" % dodged
	obstacles_hit_label.text = "Obstacles Hit: %d" % hit
	high_score_label.text = "High Score: %d" % high_score
	new_high_score_label.text = "NEW HIGH SCORE!" if is_new_high else ""
	new_high_score_label.visible = is_new_high

	# Staggered reveal animation.
	var stat_labels: Array[Label] = [distance_label, total_time_label, score_label, obstacles_dodged_label, obstacles_hit_label, high_score_label]
	for lbl in stat_labels:
		lbl.modulate.a = 0.0

	var reveal_tween := create_tween()
	var delay: float = 0.0
	for lbl in stat_labels:
		reveal_tween.tween_property(lbl, "modulate:a", 1.0, 0.35).set_delay(delay)
		delay += 0.5

	# Flash the "NEW HIGH SCORE!" label if applicable.
	if is_new_high:
		new_high_score_label.modulate.a = 0.0
		reveal_tween.tween_property(new_high_score_label, "modulate:a", 1.0, 0.35).set_delay(delay)

		var pulse := create_tween().set_loops()
		pulse.tween_property(new_high_score_label, "modulate", Color.YELLOW, 0.5)
		pulse.tween_property(new_high_score_label, "modulate", Color.WHITE, 0.5)


func _format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: float = fmod(seconds, 60.0)
	return "%d:%05.2f" % [mins, secs]


func _on_retry() -> void:
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_menu() -> void:
	GameManager.reset_run()
	GameManager.change_state(GameManager.State.MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
