extends Node3D
## Root game scene controller.
## Handles pause toggle, resume, end-run, and state transitions.

@onready var pause_menu: Control = $UILayer/PauseMenu
@onready var resume_button: Button = $UILayer/PauseMenu/PauseVBox/ResumeButton
@onready var end_run_button: Button = $UILayer/PauseMenu/PauseVBox/EndRunButton


func _ready() -> void:
	# Start a new run.
	GameManager.reset_run()
	GameManager.state_changed.connect(_on_game_state_changed)

	# Wire pause-menu buttons.
	resume_button.pressed.connect(_on_resume)
	end_run_button.pressed.connect(_on_end_run)

	# Kick off the countdown.
	GameManager.change_state(GameManager.State.COUNTDOWN)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _toggle_pause() -> void:
	if GameManager.current_state == GameManager.State.PLAYING:
		GameManager.change_state(GameManager.State.PAUSED)
	elif GameManager.current_state == GameManager.State.PAUSED:
		GameManager.change_state(GameManager.State.PLAYING)


func _on_resume() -> void:
	if GameManager.current_state == GameManager.State.PAUSED:
		GameManager.change_state(GameManager.State.PLAYING)


func _on_end_run() -> void:
	get_tree().paused = false
	GameManager.save_high_score()
	GameManager.change_state(GameManager.State.RESULTS)


func _on_game_state_changed(_old_state: GameManager.State, new_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.PAUSED:
			get_tree().paused = true
			pause_menu.visible = true
		GameManager.State.PLAYING:
			get_tree().paused = false
			pause_menu.visible = false
			# Start run timer on first PLAYING entry.
			if GameManager.distance_traveled == 0.0 and GameManager.get_run_time() <= 0.0:
				GameManager.start_run()
		GameManager.State.RESULTS:
			get_tree().change_scene_to_file("res://scenes/results.tscn")
