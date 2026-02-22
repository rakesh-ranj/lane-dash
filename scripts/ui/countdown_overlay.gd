extends Control
## Full-screen countdown overlay.
## Shows 3 - 2 - 1 - GO! before the race begins, then signals the game to
## transition into the PLAYING state.

@onready var count_label: Label = $CountLabel

## Current countdown value.
var count: int = 3


func _ready() -> void:
	visible = false
	GameManager.state_changed.connect(_on_state_changed)


## Begin the 3-2-1-GO sequence.
func start_countdown() -> void:
	visible = true
	count = 3
	_show_count()


func _show_count() -> void:
	if count > 0:
		count_label.text = str(count)
		count_label.modulate = Color.WHITE
		count_label.pivot_offset = count_label.size * 0.5

		# Scale-pulse: grow to 1.5x then shrink back.
		count_label.scale = Vector2(1.5, 1.5)
		var tween := create_tween()
		tween.tween_property(count_label, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# Wait 1 second, then advance to the next number.
		await get_tree().create_timer(1.0).timeout
		count -= 1
		_show_count()
	else:
		# Final "GO!" display.
		count_label.text = "GO!"
		count_label.modulate = Color.GREEN
		count_label.pivot_offset = count_label.size * 0.5

		# Scale pulse for GO!
		count_label.scale = Vector2(1.5, 1.5)
		var tween := create_tween()
		tween.tween_property(count_label, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		await get_tree().create_timer(0.5).timeout
		visible = false
		GameManager.change_state(GameManager.State.PLAYING)


func _on_state_changed(_old_state, new_state) -> void:
	if new_state == GameManager.State.COUNTDOWN:
		start_countdown()
