## Road obstacle that the player must dodge.
## "Passed" detection is handled by TrackManager during row recycle.
extends Node3D

var was_hit: bool = false

@onready var area: Area3D = $Area3D

func _ready() -> void:
	area.area_entered.connect(_on_area_entered)
	add_to_group("obstacle")

func _on_area_entered(_other_area: Area3D) -> void:
	if was_hit:
		return
	was_hit = true
	GameManager.on_obstacle_hit()
