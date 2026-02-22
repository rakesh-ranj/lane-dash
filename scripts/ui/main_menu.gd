extends Control
## Main menu screen.
## Allows the player to select a car colour and start the game.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var high_score_label: Label = $VBoxContainer/HighScoreLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var car_select_container: HBoxContainer = $VBoxContainer/CarSelectContainer

## Dynamically created car-colour buttons (one per colour).
var car_buttons: Array[Button] = []

## Currently selected car colour name.
var selected_car: String = "green"

## Available car colours.
var car_colors: Array[String] = ["green", "red", "orange", "white"]

## Mapping from colour name to scene path.
var car_scene_paths: Dictionary = {
	"green":  "res://assets/kenney_racing_kit/models/raceCarGreen.glb",
	"red":    "res://assets/kenney_racing_kit/models/raceCarRed.glb",
	"orange": "res://assets/kenney_racing_kit/models/raceCarOrange.glb",
	"white":  "res://assets/kenney_racing_kit/models/raceCarWhite.glb",
}


func _ready() -> void:
	title_label.text = "LANE DASH"

	# Display the saved high score.
	high_score_label.text = "HIGH SCORE: %d" % GameManager.high_score

	# Connect start button.
	start_button.pressed.connect(_on_start)

	# Build a button for each car colour.
	for color_name in car_colors:
		var btn := Button.new()
		btn.text = color_name.capitalize()
		btn.custom_minimum_size = Vector2(100, 40)
		btn.pressed.connect(_on_car_selected.bind(color_name))
		car_select_container.add_child(btn)
		car_buttons.append(btn)

	# Highlight the default selection.
	_update_button_highlights()


func _on_car_selected(color: String) -> void:
	selected_car = color
	_update_button_highlights()


func _update_button_highlights() -> void:
	for i in car_buttons.size():
		var btn := car_buttons[i]
		if car_colors[i] == selected_car:
			btn.add_theme_color_override("font_color", Color.YELLOW)
			btn.add_theme_stylebox_override("normal", _highlighted_stylebox())
		else:
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_stylebox_override("normal")


func _highlighted_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 0.0, 0.15)
	sb.border_color = Color.YELLOW
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(8)
	return sb


func _on_start() -> void:
	GameManager.selected_car = car_scene_paths[selected_car]
	get_tree().change_scene_to_file("res://scenes/game.tscn")
