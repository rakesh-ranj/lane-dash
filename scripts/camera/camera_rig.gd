extends Node3D
## Camera rig — close third-person chase cam right behind the car.
## Sits low and tight for an immersive driving feel.
## Dynamic FOV on acceleration, banking into turns, slight lag for momentum.

# ── Constants ────────────────────────────────────────────────────────────────

## Camera sits just above the car roof, close behind.
var BASE_OFFSET: Vector3     = Vector3(0.0, 0.75, 1.8)
const LOOK_DOWN_ANGLE: float = -6.0    # degrees – nearly level, looking at the road ahead
const FOLLOW_SPEED: float    = 8.0     # snappy tracking
const FOV_MIN: float         = 70.0    # wider base for immersion
const FOV_MAX: float         = 100.0   # dramatic zoom at top speed
const LANE_TILT_ANGLE: float = 4.0     # degrees – noticeable banking in turns

# ── Node References ──────────────────────────────────────────────────────────
@onready var camera: Camera3D = $Camera3D

# ── State ────────────────────────────────────────────────────────────────────
var target_fov: float     = FOV_MIN
var _shake_intensity: float = 0.0
var _shake_remaining: float = 0.0


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	camera.fov = FOV_MIN
	position = BASE_OFFSET
	camera.rotation_degrees.x = LOOK_DOWN_ANGLE


func _process(delta: float) -> void:
	# ── Smooth follow ────────────────────────────────────────────────────
	var target_pos: Vector3 = BASE_OFFSET
	position = position.lerp(target_pos, FOLLOW_SPEED * delta)

	# ── Shake ────────────────────────────────────────────────────────────
	if _shake_remaining > 0.0:
		_shake_remaining -= delta
		var t: float = _shake_remaining / maxf(_shake_intensity, 0.01)
		var offset_x: float = randf_range(-_shake_intensity, _shake_intensity) * t
		var offset_y: float = randf_range(-_shake_intensity, _shake_intensity) * t
		position.x += offset_x
		position.y += offset_y

	# ── FOV ──────────────────────────────────────────────────────────────
	camera.fov = lerpf(camera.fov, target_fov, FOLLOW_SPEED * delta)

	# ── Lane tilt ────────────────────────────────────────────────────────
	# Read lateral position from the parent PlayerCar node.
	var lateral_ratio: float = get_parent().position.x  # -1.5..1.5
	var target_tilt: float = deg_to_rad(-lateral_ratio * LANE_TILT_ANGLE)
	rotation.z = lerp(rotation.z, target_tilt, FOLLOW_SPEED * delta)


# ── Public API ───────────────────────────────────────────────────────────────

func update_fov(speed_ratio: float) -> void:
	## Adjust the target FOV based on the current speed ratio (0.0 – 1.0).
	target_fov = lerpf(FOV_MIN, FOV_MAX, clampf(speed_ratio, 0.0, 1.0))

func shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_remaining = duration
