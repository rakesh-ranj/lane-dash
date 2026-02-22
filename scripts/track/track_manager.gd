## TrackManager – infinite straight treadmill scroller.
## Spawns road tiles ahead of the player, scrolls them toward the camera,
## and recycles tiles that pass behind the player.
extends Node3D

# ── Constants ────────────────────────────────────────────────────────────────

## Length of one roadStraightLong tile along Z (actual mesh depth is ~1 unit).
const TILE_LENGTH: float = 1.0
## Number of side-by-side lane columns.
const NUM_LANES: int = 3
## Lateral offsets for lanes (left, center, right).
var LANE_OFFSETS: Array[float] = [-1.0, 0.0, 1.0]
## How many rows of tiles to keep alive at once.
const NUM_ROWS: int = 60
## Z threshold behind the camera at which tiles are recycled.
const DESPAWN_Z: float = 8.0

## Decoration placement margins.
const DECORATION_INNER_X: float = 2.5
const DECORATION_OUTER_X: float = 5.0

# ── Obstacle Constants ───────────────────────────────────────────────────────

const OBSTACLE_MIN_GAP: int = 5
const OBSTACLE_SPAWN_CHANCE: float = 0.35

# ── Asset Paths ──────────────────────────────────────────────────────────────

var ROAD_SCENE_PATH: String = "res://assets/kenney_racing_kit/models/roadStraightLong.glb"

var TREE_SCENE_PATHS: Array[String] = [
	"res://assets/quaternius_trees/Tree_01.fbx",
	"res://assets/quaternius_trees/Tree_02.fbx",
	"res://assets/quaternius_trees/Tree_03.fbx",
	"res://assets/quaternius_trees/Tree_04.fbx",
	"res://assets/quaternius_trees/Tree_05.fbx",
]

var LIGHT_SCENE_PATHS: Array[String] = [
	"res://assets/kenney_racing_kit/models/lightPostLarge.glb",
	"res://assets/kenney_racing_kit/models/lightPostModern.glb",
]

var GRANDSTAND_SCENE_PATHS: Array[String] = [
	"res://assets/kenney_racing_kit/models/grandStand.glb",
	"res://assets/kenney_racing_kit/models/grandStandCovered.glb",
]

var TENT_SCENE_PATHS: Array[String] = [
	"res://assets/kenney_racing_kit/models/tent.glb",
	"res://assets/kenney_racing_kit/models/tentLong.glb",
	"res://assets/kenney_racing_kit/models/tentClosed.glb",
]

var OBSTACLE_SCENE_PATHS: Array[String] = [
	"res://assets/kenney_racing_kit/models/barrierRed.glb",
	"res://assets/kenney_racing_kit/models/barrierWhite.glb",
	"res://assets/kenney_racing_kit/models/pylon.glb",
]

var OBSTACLE_TEMPLATE_PATH: String = "res://scenes/obstacles/obstacle.tscn"

# ── Variables ────────────────────────────────────────────────────────────────

var road_scene: PackedScene = null
var tree_scenes: Array[PackedScene] = []
var light_scenes: Array[PackedScene] = []
var grandstand_scenes: Array[PackedScene] = []
var tent_scenes: Array[PackedScene] = []
var obstacle_visual_scenes: Array[PackedScene] = []
var obstacle_template: PackedScene = null
var _rows_since_last_obstacle: int = 0
## Deterministic lane counter — cycles 0, 1, 2, 0, 1, 2, ...
var _obstacle_lane_counter: int = 0

## All active row container nodes.
var rows: Array[Node3D] = []

var rng := RandomNumberGenerator.new()

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	rng.seed = 42
	_preload_scenes()
	_build_initial_rows()


func _process(delta: float) -> void:
	var speed: float = GameManager.current_speed
	if speed <= 0.0:
		return

	var dz: float = speed * delta

	# Report distance to GameManager.
	GameManager.add_distance(dz)

	# Scroll all rows toward the camera (+Z).
	for row in rows:
		row.position.z += dz

	# Recycle any rows that passed behind the camera.
	_recycle_rows()


# ── Preloading ───────────────────────────────────────────────────────────────

func _preload_scenes() -> void:
	if ResourceLoader.exists(ROAD_SCENE_PATH):
		road_scene = load(ROAD_SCENE_PATH) as PackedScene
	else:
		push_error("TrackManager: road scene not found – %s" % ROAD_SCENE_PATH)

	for path in TREE_SCENE_PATHS:
		if ResourceLoader.exists(path):
			tree_scenes.append(load(path) as PackedScene)

	for path in LIGHT_SCENE_PATHS:
		if ResourceLoader.exists(path):
			light_scenes.append(load(path) as PackedScene)

	for path in GRANDSTAND_SCENE_PATHS:
		if ResourceLoader.exists(path):
			grandstand_scenes.append(load(path) as PackedScene)

	for path in TENT_SCENE_PATHS:
		if ResourceLoader.exists(path):
			tent_scenes.append(load(path) as PackedScene)

	for path in OBSTACLE_SCENE_PATHS:
		if ResourceLoader.exists(path):
			obstacle_visual_scenes.append(load(path) as PackedScene)

	if ResourceLoader.exists(OBSTACLE_TEMPLATE_PATH):
		obstacle_template = load(OBSTACLE_TEMPLATE_PATH) as PackedScene


# ── Row Management ───────────────────────────────────────────────────────────

func _build_initial_rows() -> void:
	if road_scene == null:
		return

	# Place rows from just behind the camera out to far ahead.
	for i in range(NUM_ROWS):
		var z: float = DESPAWN_Z - float(i + 1) * TILE_LENGTH
		var row := _create_row(z)
		rows.append(row)

	pass


func _create_row(z: float) -> Node3D:
	var row := Node3D.new()
	row.position.z = z
	add_child(row)

	# Three road tiles side by side.
	# The roadStraightLong model origin is at its left edge (extends in +X),
	# so shift -0.5 to center each tile on its lane position.
	for lane in range(NUM_LANES):
		var tile: Node3D = road_scene.instantiate() as Node3D
		tile.position.x = LANE_OFFSETS[lane] - 0.5
		row.add_child(tile)

	# Random roadside decorations.
	_add_decorations(row)
	# Road obstacles.
	_add_obstacles(row)
	return row


func _recycle_rows() -> void:
	# Find the actual frontmost (most negative Z) row position.
	var min_z: float = INF
	for r in rows:
		if r.position.z < min_z:
			min_z = r.position.z

	# Recycle any rows that passed behind the camera.
	for row in rows:
		if row.position.z > DESPAWN_Z:
			min_z -= TILE_LENGTH
			row.position.z = min_z
			_refresh_decorations(row)
			_refresh_obstacles(row)


# ── Decorations ──────────────────────────────────────────────────────────────

func _add_decorations(row: Node3D) -> void:
	# Trees – 35 % chance per side.
	if not tree_scenes.is_empty():
		for side_sign in [-1.0, 1.0]:
			if rng.randf() < 0.35:
				var tree_idx: int = rng.randi_range(0, tree_scenes.size() - 1)
				var tree: Node3D = tree_scenes[tree_idx].instantiate() as Node3D
				tree.position.x = side_sign * rng.randf_range(DECORATION_INNER_X, DECORATION_OUTER_X)
				tree.rotation.y = rng.randf_range(0.0, TAU)
				tree.scale = Vector3(0.5, 0.5, 0.5)
				tree.add_to_group("decoration")
				row.add_child(tree)

	# Light posts – ~15 % chance.
	if rng.randf() < 0.15 and not light_scenes.is_empty():
		for side_sign in [-1.0, 1.0]:
			var light_idx: int = rng.randi_range(0, light_scenes.size() - 1)
			var light: Node3D = light_scenes[light_idx].instantiate() as Node3D
			light.position.x = side_sign * (DECORATION_INNER_X + 0.3)
			light.add_to_group("decoration")
			row.add_child(light)

	# Grandstands – rare.
	if rng.randf() < 0.03 and not grandstand_scenes.is_empty():
		var side_sign: float = -1.0 if rng.randf() < 0.5 else 1.0
		var gs_idx: int = rng.randi_range(0, grandstand_scenes.size() - 1)
		var gs: Node3D = grandstand_scenes[gs_idx].instantiate() as Node3D
		gs.position.x = side_sign * (DECORATION_OUTER_X + 1.0)
		gs.rotation.y = PI / 2.0 * side_sign
		gs.add_to_group("decoration")
		row.add_child(gs)

	# Tents – very rare.
	if rng.randf() < 0.04 and not tent_scenes.is_empty():
		var side_sign: float = -1.0 if rng.randf() < 0.5 else 1.0
		var tent_idx: int = rng.randi_range(0, tent_scenes.size() - 1)
		var tent: Node3D = tent_scenes[tent_idx].instantiate() as Node3D
		tent.position.x = side_sign * rng.randf_range(DECORATION_OUTER_X, DECORATION_OUTER_X + 2.0)
		tent.rotation.y = rng.randf_range(0.0, TAU)
		tent.add_to_group("decoration")
		row.add_child(tent)


func _refresh_decorations(row: Node3D) -> void:
	# Remove old decorations (keep road tiles which are not in the group).
	for child in row.get_children():
		if child.is_in_group("decoration"):
			child.queue_free()

	# Add fresh ones.
	_add_decorations(row)


# ── Obstacles ───────────────────────────────────────────────────────────────

func _spawn_one_obstacle(row: Node3D, x_pos: float) -> void:
	var obs: Node3D = obstacle_template.instantiate() as Node3D
	obs.position.x = x_pos
	var vis_idx: int = rng.randi_range(0, obstacle_visual_scenes.size() - 1)
	var vis: Node3D = obstacle_visual_scenes[vis_idx].instantiate() as Node3D
	obs.get_node("MeshRoot").add_child(vis)
	row.add_child(obs)


func _add_obstacles(row: Node3D) -> void:
	if obstacle_template == null or obstacle_visual_scenes.is_empty():
		return
	# No obstacles until the game is actually PLAYING.
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	_rows_since_last_obstacle += 1
	if _rows_since_last_obstacle < OBSTACLE_MIN_GAP:
		return
	if rng.randf() > OBSTACLE_SPAWN_CHANCE:
		return

	_rows_since_last_obstacle = 0

	# Single obstacle — deterministic lane rotation.
	var which: int = _obstacle_lane_counter % 3
	_obstacle_lane_counter += 1
	match which:
		0: _spawn_one_obstacle(row, -1.0)
		1: _spawn_one_obstacle(row, 0.0)
		2: _spawn_one_obstacle(row, 1.0)


func _refresh_obstacles(row: Node3D) -> void:
	# Score any un-hit obstacles as "passed", then free them all.
	for child in row.get_children():
		if child.is_in_group("obstacle"):
			if not child.was_hit:
				GameManager.on_obstacle_passed()
			child.queue_free()

	# Spawn fresh obstacles on the recycled row.
	_add_obstacles(row)
