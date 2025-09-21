class_name SpaceStation2D
extends Node2D

signal resources_changed(delta, reason)
signal state_changed(resources, damage)
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

@export var enemy : bool = false
@export var resources : int = 0
@export var health : int = 10
@export var size_limit : int = 8
@export var fire_delay : float = 0.4
@export var part_fire_delay : float = 1.0
@export var projectile_velocity : float = 80.0
@export var projectile_scenes : Array[PackedScene]


@onready var astar = AStar2D.new()
@onready var station_parts : TileMapLayer = %StationParts
@onready var cell_size := station_parts.tile_set.tile_size

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
	expand_station(2)

func _ready():
	create_pathfinding_points()
	if enemy:
		var new_tile_set = station_parts.tile_set.duplicate()
		new_tile_set.set_physics_layer_collision_layer(0, ENEMY_COLLISION_LAYER)
		station_parts.tile_set = new_tile_set

func _on_friendly_area_2d_body_entered(body):
	if body.has_method("remove_all_resources"):
		resources += body.remove_all_resources()

func _on_station_parts_tile_damaged(tile_id, _amount):
	var part_type := tile_type_map[tile_id]
	if part_type in [PartType.ARM, PartType.JUNCTION] : return
	station_parts.set_cell(tile_id)
	create_pathfinding_points()
	for part in disconnected_parts:
		station_parts.set_cell(part)
	if connected_parts.is_empty():
		is_destroyed = true
		destroyed.emit()

func _get_player_vector(tile_id : Vector2i) -> Vector2:
	var world_position := global_position + Vector2(tile_id * cell_size) 
	var player := get_tree().get_first_node_in_group(&"player")
	return player.global_position - world_position

func _get_shooting_positions_in_range_of_player(max_range : float = 100) -> Array[Vector2i]:
	var in_range_positions : Array[Vector2i]
	for shooting_position in shooting_positions:
		var distance := _get_player_vector(shooting_position).length()
		if distance < max_range:
			in_range_positions.append(shooting_position)
	return in_range_positions

func _process(delta):
	if is_destroyed : return
	shooting_cooldown -= delta
	for shooting_position in shooting_cooldown_map:
		shooting_cooldown_map[shooting_position] -= delta
	if shooting_cooldown > 0: return
	var in_range_positions := _get_shooting_positions_in_range_of_player()
	for shooting_position in in_range_positions:
		if shooting_position in shooting_cooldown_map and shooting_cooldown_map[shooting_position] > 0.0:
			continue
		shooting_cooldown_map[shooting_position] = part_fire_delay
		shooting_cooldown = fire_delay
		var projectile_scene = projectile_scenes.pick_random()
		var bullet_instance : CharacterBody2D = projectile_scene.instantiate()
		bullet_instance.global_position = global_position + Vector2(shooting_position * cell_size)
		bullet_instance.velocity = _get_player_vector(shooting_position).normalized() * projectile_velocity
		GameEvents.object_spawned.emit(bullet_instance)
		break
