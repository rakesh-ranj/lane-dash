extends Node3D
## Player car controller for an infinite straight track.
## The car stays at Z = 0. W/S controls track scroll speed, A/D controls
## lateral position. The TrackManager reads GameManager.current_speed to
## scroll the road tiles.

# ── Constants ────────────────────────────────────────────────────────────────
const BASE_SPEED: float          = 8.0   # units / sec (drives treadmill)
const LATERAL_SPEED: float       = 2.5   # units / sec
const LATERAL_ACCEL: float       = 15.0  # acceleration
const LANE_WIDTH: float          = 1.0
var LANE_CENTERS: Array[float]   = [-1.0, 0.0, 1.0]
const TRACK_HALF_WIDTH: float    = 1.1   # clamp to road surface (no grass)
const LANE_MAGNET_STRENGTH: float = 0.05
const TILT_ANGLE: float          = 8.0   # degrees, Z-axis tilt on steering
const ACCEL_BOOST: float         = 1.4   # +40 % speed when holding W
const BRAKE_FACTOR: float        = 0.4   # -60 % speed when holding S
const PITCH_ANGLE_ACCEL: float   = -3.0  # nose dips when accelerating (degrees)
const PITCH_ANGLE_BRAKE: float   = 4.0   # nose lifts when braking (degrees)
const Z_OFFSET_LERP: float       = 4.0   # how quickly visual offsets respond

# ── Node References ──────────────────────────────────────────────────────────
@onready var car_model: Node3D   = $CarModel
@onready var camera_rig: Node3D  = $CameraRig  # has script camera_rig.gd

# ── State ────────────────────────────────────────────────────────────────────
var lateral_velocity: float   = 0.0
var input_enabled: bool       = false
var throttle_factor: float    = 1.0
var current_speed: float      = 0.0

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("player")
	GameManager.state_changed.connect(_on_game_state_changed)
	GameManager.obstacle_hit.connect(_on_obstacle_hit)

	# Load the selected car model.
	if GameManager.selected_car != "":
		set_car_model_scene(GameManager.selected_car)


func _physics_process(delta: float) -> void:
	if not input_enabled:
		return

	# ── Input ────────────────────────────────────────────────────────────
	var steer_dir: float = Input.get_axis("steer_left", "steer_right")

	# ── Accelerate / brake ───────────────────────────────────────────────
	var target_pitch: float = 0.0
	if Input.is_action_pressed("accelerate"):
		throttle_factor = ACCEL_BOOST
		target_pitch = PITCH_ANGLE_ACCEL
	elif Input.is_action_pressed("brake"):
		throttle_factor = BRAKE_FACTOR
		target_pitch = PITCH_ANGLE_BRAKE
	else:
		throttle_factor = 1.0

	# ── Speed (drives the treadmill via GameManager) ─────────────────────
	current_speed = BASE_SPEED * throttle_factor
	GameManager.current_speed = current_speed

	# ── Lateral movement (position.x) ───────────────────────────────────
	if steer_dir != 0.0:
		lateral_velocity = move_toward(lateral_velocity,
				steer_dir * LATERAL_SPEED, LATERAL_ACCEL * delta)
	else:
		lateral_velocity = move_toward(lateral_velocity, 0.0,
				LATERAL_ACCEL * delta)
		# Lane magnet – gently pull toward the nearest lane center.
		var nearest_lane: float = _get_nearest_lane_center(position.x)
		position.x = lerp(position.x, nearest_lane, LANE_MAGNET_STRENGTH)

	position.x += lateral_velocity * delta
	position.x = clampf(position.x, -TRACK_HALF_WIDTH, TRACK_HALF_WIDTH)

	# ── Car model visual feedback ────────────────────────────────────────
	# Pitch (nose down on accel, up on brake).
	var target_pitch_rad: float = deg_to_rad(target_pitch)
	car_model.rotation.x = lerpf(car_model.rotation.x, target_pitch_rad, Z_OFFSET_LERP * delta)

	# Tilt on steering.
	var target_tilt: float = deg_to_rad(-steer_dir * TILT_ANGLE)
	car_model.rotation.z = lerp(car_model.rotation.z, target_tilt, 10.0 * delta)

	# Update camera FOV for speed sensation.
	if camera_rig.has_method("update_fov"):
		camera_rig.update_fov((throttle_factor - BRAKE_FACTOR) / (ACCEL_BOOST - BRAKE_FACTOR))


# ── State Callbacks ──────────────────────────────────────────────────────────

func _on_game_state_changed(_old_state: GameManager.State, new_state: GameManager.State) -> void:
	input_enabled = (new_state == GameManager.State.PLAYING)

func _on_obstacle_hit() -> void:
	# Scale-pulse the car model.
	var tw := create_tween()
	tw.tween_property(car_model, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
	tw.tween_property(car_model, "scale", Vector3.ONE, 0.15)
	# Camera shake.
	if camera_rig.has_method("shake"):
		camera_rig.shake(0.06, 0.3)


# ── Public helpers ───────────────────────────────────────────────────────────

func set_car_model_scene(car_scene_path: String) -> void:
	## Replace the current CarModel child mesh with a new packed scene.
	var new_scene: PackedScene = load(car_scene_path) as PackedScene
	if new_scene == null:
		push_warning("player_car: could not load scene at '%s'" % car_scene_path)
		return

	# Remove existing children of CarModel.
	for child in car_model.get_children():
		child.queue_free()

	# Instance and attach the new model.
	var instance: Node3D = new_scene.instantiate() as Node3D
	car_model.add_child(instance)


# ── Private helpers ──────────────────────────────────────────────────────────

func _get_nearest_lane_center(x_pos: float) -> float:
	var best: float = LANE_CENTERS[0]
	var best_dist: float = absf(x_pos - best)
	for lc in LANE_CENTERS:
		var d: float = absf(x_pos - lc)
		if d < best_dist:
			best = lc
			best_dist = d
	return best
