class_name SpaceStation2D
extends Node2D

signal resources_changed(delta)
signal size_changed(new_size)
signal center_destroyed
signal destroyed

const ENEMY_COLLISION_LAYER = 8
const NO_TILE = -1
const CARDINAL_DIRECTIONS : Array = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
const CANTOR_LIMIT = int(pow(2, 30))

enum PartType {
	CENTER,
	ARM,
	JUNCTION,
	TIP
}

@export var station_explosion_scene : PackedScene
@export var part_explosion_scene : PackedScene
@export var resource_scene : PackedScene
@export var enemy : bool = false
@export var resources : int = 0 :
	set(value):
		var _delta = value - resources
		resources = value
		resources_changed.emit(_delta)
@export var health : float = 3
@export var size_limit : int = 8
@export var fire_delay : float = 0.4
@export var part_fire_delay : float = 1.0
@export var projectile_velocity : float = 80.0
@export var projectile_scenes : Array[PackedScene]
@export var asteroid_projectile_scenes : Array[PackedScene]
@export_range(0, 1, 0.001) var resource_drop_chance : float = 0.125
@export_range(0, 16, 0.01, "or_greater") var resource_drop_range : float = 4.0


@onready var astar = AStar2D.new()
@onready var station_parts : TileMapLayer = %StationParts
@onready var cell_size := station_parts.tile_set.tile_size
@onready var damage_animation_player = %DamageAnimationPlayer
@onready var hurt_stream_player_2d = %HurtStreamPlayer2D

var is_center_destroyed : bool = false
var is_destroyed : bool = false
var connected_parts : Array
var disconnected_parts : Array
var part_distance_map : Dictionary
var furthest_part_distance : int
var point_id_position_map : Dictionary[int, Vector2i]
var tile_health_map : Dictionary[Vector2i, int]
var tile_type_map : Dictionary[Vector2i, PartType]
var shooting_positions : Array[Vector2i]
var shooting_cooldown_map : Dictionary[Vector2i, float]
var shooting_cooldown : float = 0.0

func get_used_cell_global_positions() -> Array:
	var cells = station_parts.get_used_cells()
	var cell_positions := []
	for cell in cells:
		var cell_position := station_parts.map_to_local(cell)
		cell_positions.append(cell_position)
	return cell_positions

func connect_cardinals(point_position : Vector2i) -> void:
	var center := get_point(point_position, false)
	for direction in CARDINAL_DIRECTIONS:
		var cardinal_point := get_point(point_position + direction, false)
		if cardinal_point != center and astar.has_point(cardinal_point):
			astar.connect_points(center, cardinal_point, true)

func create_pathfinding_points() -> void:
	astar.clear()
	point_id_position_map.clear()
	for cell_position in station_parts.get_used_cells():
		astar.add_point(get_point(cell_position, false), cell_position)
		point_id_position_map[get_point(cell_position, false)] = cell_position
	for cell_position in point_id_position_map.values():
		connect_cardinals(cell_position)
	_map_tiles()
	size_changed.emit(point_id_position_map.size())


func set_path_length(point_path: Array, max_distance: int) -> Array:
	if max_distance < 0: return point_path
	point_path.resize(min(point_path.size(), max_distance))
	return point_path

func to_natural(num: int) -> int:
	if num < 0:
		return CANTOR_LIMIT + num
	return num

func get_point(point_position: Vector2, in_local_space : bool = true) -> int:
	var cell_position : Vector2i = Vector2i(point_position)
	if in_local_space:
		cell_position = round(point_position / Vector2(cell_size))
	# Cantor pairing function
	var a := to_natural(cell_position.x)
	var b := to_natural(cell_position.y)
	return (a + b) * (a + b + 1) / 2 + b

func has_point(point_position: Vector2, in_local_space : bool = true) -> bool:
	var point_id := get_point(point_position, in_local_space)
	return astar.has_point(point_id)

func get_astar_path(start_position: Vector2, end_position: Vector2, max_distance := -1) -> Array:
	if not has_point(start_position) or not has_point(end_position):
		return []
	var astar_path := astar.get_point_path(get_point(start_position), get_point(end_position))
	return set_path_length(astar_path, max_distance)

func get_cell_part_type(cellv: Vector2i) -> PartType:
	if cellv == Vector2i.ZERO : return PartType.CENTER
	var cell_atlas_coords := station_parts.get_cell_atlas_coords(cellv)
	if cell_atlas_coords.y == 0 or (cell_atlas_coords.x <= 1 and cell_atlas_coords.y <= 1):
		return PartType.ARM
	elif cell_atlas_coords in [Vector2i(2,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2)]:
		return PartType.TIP
	else:
		return PartType.JUNCTION

func _map_tiles():
	connected_parts.clear()
	disconnected_parts.clear()
	part_distance_map.clear()
	tile_type_map.clear()
	shooting_positions.clear()
	furthest_part_distance = 0
	var target_cell := Vector2.ZERO
	var start_cell : Vector2
	for cellv in station_parts.get_used_cells():
		start_cell = cellv * cell_size
		var distance = get_astar_path(start_cell, target_cell).size()
		if start_cell == target_cell or distance > 0:
			connected_parts.append(cellv)
		else:
			disconnected_parts.append(cellv)
		if distance > furthest_part_distance:
			furthest_part_distance = distance
		if not distance in part_distance_map:
			part_distance_map[distance] = []
		part_distance_map[distance].append(cellv)
		tile_type_map[cellv] = get_cell_part_type(cellv)
		if tile_type_map[cellv] in [PartType.TIP, PartType.CENTER]:
			shooting_positions.append(cellv)

func _is_in_bounds(cellv : Vector2) -> bool:
	if size_limit == 0: return true
	return abs(cellv.x) < size_limit and abs(cellv.y) < size_limit

func _is_cell_buildable(cellv : Vector2) -> bool:
	return station_parts.get_cell_atlas_coords(cellv) == -Vector2i.ONE

func _filter_out_of_bounds(vectors : Array[Vector2i]) -> Array[Vector2i]:
	var return_vectors : Array[Vector2i] = []
	for vector in vectors:
		if vector is Vector2i and _is_in_bounds(vector):
			return_vectors.append(vector)
	return return_vectors

func _is_part_connected_to_center(cellv : Vector2i):
	var target_cell = Vector2.ZERO
	var start_cell = cellv * cell_size
	var path_points = station_parts.get_astar_path_avoiding_obstacles(start_cell, target_cell)
	return path_points.size() > 0

func _filter_values_greater_than(dict : Dictionary[Vector2i, int], max_value : int) -> Dictionary[Vector2i, int]:
	var return_dict : Dictionary[Vector2i, int] = {}
	for key in dict:
		if dict[key] <= max_value:
			return_dict[key] = dict[key]
	return return_dict

func _get_buildable_cells():
	var neighboring_cells : Dictionary[Vector2i, int] = {}
	var buildable_cells : Dictionary[Vector2i, int] = {}
	var filter_crowd : int = 1
	for cell_position in station_parts.get_used_cells():
		#if not _is_part_connected_to_center(cell_position):
		#	continue
		for direction in CARDINAL_DIRECTIONS:
			var neighboring_cell = cell_position + direction
			if not _is_cell_buildable(neighboring_cell):
				continue
			if not neighboring_cell in neighboring_cells:
				neighboring_cells[neighboring_cell] = 0
			neighboring_cells[neighboring_cell] += 1
	while buildable_cells.is_empty() and filter_crowd < 5:
		buildable_cells = _filter_values_greater_than(neighboring_cells, filter_crowd)
		filter_crowd += 1
	return buildable_cells.keys()

func _expand_station_with_part(cellv : Vector2i):
	if not _is_cell_buildable(cellv):
		return
	station_parts.set_cells_terrain_connect([cellv], 0, 0)
	create_pathfinding_points()

func expand_station(expand_max : int = 0) -> int:
	if is_center_destroyed: return 0
	var extra_resources := resources
	if expand_max == 0:
		expand_max = extra_resources
	else:
		expand_max = min(extra_resources, expand_max)
	var expanded : int = 0
	for i in range(expand_max):
		var optional_cells : Array = _get_buildable_cells()
		optional_cells = _filter_out_of_bounds(optional_cells)
		if optional_cells.size() == 0:
			break
		optional_cells.shuffle()
		var cellv = optional_cells.pop_back()
		_expand_station_with_part(cellv)
		expanded += 1
	resources -= expanded
	return expanded

func _on_timer_timeout():
	expand_station(1)

func _ready():
	create_pathfinding_points()
	if enemy:
		var new_tile_set = station_parts.tile_set.duplicate()
		new_tile_set.set_physics_layer_collision_layer(0, ENEMY_COLLISION_LAYER)
		station_parts.tile_set = new_tile_set

func _on_friendly_area_2d_body_entered(body):
	if is_center_destroyed or enemy: return
	if body.has_method("remove_all_resources"):
		resources += body.remove_all_resources()

func _get_tile_neighbors(tile_id : Vector2i) -> Array[Vector2i]:
	var tile_neighbors : Array[Vector2i]
	for direction in CARDINAL_DIRECTIONS:
		var neighboring_tile = tile_id + direction
		if station_parts.get_cell_source_id(neighboring_tile) != -1:
			tile_neighbors.append(neighboring_tile)
	return tile_neighbors

func _neighboring_tile_destroyed(tile_id: Vector2i) -> void:
	var tile_type := tile_type_map[tile_id]
	if tile_id in disconnected_parts or tile_type == PartType.ARM:
		await get_tree().create_timer(0.5, false).timeout
		_destroy_cell(tile_id)
	if tile_type == PartType.JUNCTION:
		if _get_tile_neighbors(tile_id).size() == 1:
			await get_tree().create_timer(0.5, false).timeout
			_destroy_cell(tile_id)

func _destroy_neighboring_tiles(tile_id: Vector2i)-> void:
	for neighboring_tile in _get_tile_neighbors(tile_id):
		_neighboring_tile_destroyed(neighboring_tile)

func _destroy_cell(tile_id: Vector2i) -> void:
	station_parts.set_cell(tile_id)
	create_pathfinding_points()
	var explosion_instance : Node2D
	if tile_id == Vector2i.ZERO:
		is_center_destroyed = true
		center_destroyed.emit()
		explosion_instance = station_explosion_scene.instantiate()
		explosion_instance.global_position = global_position
	else:
		explosion_instance = part_explosion_scene.instantiate()
		explosion_instance.global_position = global_position + Vector2(tile_id * cell_size)
		if randf() < resource_drop_chance:
			var resource_instance : Node2D = resource_scene.instantiate()
			resource_instance.spawner = self
			var resource_spawn_position = global_position
			resource_spawn_position += Vector2(tile_id * cell_size)
			resource_spawn_position += Vector2.from_angle(randf_range(-PI, PI)) * resource_drop_range
			resource_instance.global_position = resource_spawn_position
			GameEvents.object_spawned.emit(resource_instance)
	GameEvents.object_spawned.emit(explosion_instance)
	if tile_id == Vector2i.ZERO:
		await get_tree().create_timer(0.5, false).timeout
	_destroy_neighboring_tiles(tile_id)
	if point_id_position_map.is_empty() and not is_destroyed:
		is_destroyed = true
		destroyed.emit()
		queue_free()

func _on_station_parts_tile_damaged(tile_id, amount):
	var part_type := tile_type_map[tile_id]
	if part_type in [PartType.ARM, PartType.JUNCTION] : return
	if part_type == PartType.CENTER:
		health -= amount
		damage_animation_player.play(&"DAMAGE")
		hurt_stream_player_2d.play()
		if health > 0:
			return
	_destroy_cell(tile_id)

func _get_player_vector(tile_id : Vector2i) -> Vector2:
	var world_position := global_position + Vector2(tile_id * cell_size)
	var player := get_tree().get_first_node_in_group(&"player")
	return player.global_position - world_position

func _get_asteroid_vector(tile_id : Vector2i) -> Vector2:
	var world_position := global_position + Vector2(tile_id * cell_size)
	var asteroids := get_tree().get_nodes_in_group(&"asteroid")
	var closest_distance_squared : float = INF
	var closest_asteroid : Node2D
	for asteroid in asteroids:
		if asteroid is Node2D:
			var distance_squared:float = asteroid.global_position.distance_squared_to(global_position)
			if distance_squared < closest_distance_squared:
				closest_distance_squared = distance_squared
				closest_asteroid = asteroid
	if closest_asteroid == null : return Vector2.ZERO
	return closest_asteroid.global_position - world_position

func _get_shooting_positions_in_range_of_player(max_range : float = 100) -> Array[Vector2i]:
	var in_range_positions : Array[Vector2i]
	for shooting_position in shooting_positions:
		var distance := _get_player_vector(shooting_position).length()
		if distance < max_range:
			in_range_positions.append(shooting_position)
	return in_range_positions

func _get_shooting_positions_in_range_of_asteroids(max_range : float = 100) -> Array[Vector2i]:
	var in_range_positions : Array[Vector2i]
	if get_tree().get_nodes_in_group(&"asteroid").size() == 0: return []
	for shooting_position in shooting_positions:
		var distance := _get_asteroid_vector(shooting_position).length()
		if distance < max_range:
			in_range_positions.append(shooting_position)
	return in_range_positions

func _shoot_at_player() -> bool:
	var in_range_positions := _get_shooting_positions_in_range_of_player()
	in_range_positions.shuffle()
	for shooting_position in in_range_positions:
		if shooting_position in shooting_cooldown_map and shooting_cooldown_map[shooting_position] > 0.0:
			continue
		if shooting_position != Vector2i.ZERO:
			shooting_cooldown_map[shooting_position] = part_fire_delay
		shooting_cooldown = fire_delay
		var projectile_scene = projectile_scenes.pick_random()
		var bullet_instance : CharacterBody2D = projectile_scene.instantiate()
		bullet_instance.global_position = global_position + Vector2(shooting_position * cell_size)
		bullet_instance.velocity = _get_player_vector(shooting_position).normalized() * projectile_velocity
		GameEvents.object_spawned.emit(bullet_instance)
		return true
	return false
	
func _shoot_at_asteroids() -> bool:
	var in_range_positions := _get_shooting_positions_in_range_of_asteroids()
	in_range_positions.shuffle()
	for shooting_position in in_range_positions:
		if shooting_position in shooting_cooldown_map and shooting_cooldown_map[shooting_position] > 0.0:
			continue
		if shooting_position != Vector2i.ZERO:
			shooting_cooldown_map[shooting_position] = part_fire_delay
		shooting_cooldown = fire_delay
		var projectile_scene = asteroid_projectile_scenes.pick_random()
		var bullet_instance : CharacterBody2D = projectile_scene.instantiate()
		bullet_instance.global_position = global_position + Vector2(shooting_position * cell_size)
		bullet_instance.velocity = _get_asteroid_vector(shooting_position).normalized() * projectile_velocity
		GameEvents.object_spawned.emit(bullet_instance)
		return true
	return false

func _process(delta):
	if is_center_destroyed : return
	shooting_cooldown -= delta
	for shooting_position in shooting_cooldown_map:
		shooting_cooldown_map[shooting_position] -= delta
	if shooting_cooldown > 0: return
	if enemy:
		if not _shoot_at_player():
			_shoot_at_asteroids()
	else:
		if not _shoot_at_asteroids():
			_shoot_at_player()
