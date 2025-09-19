extends Node2D

signal resources_changed(delta, reason)
signal state_changed(resources, damage)
signal destroyed(reason)

const NO_TILE = -1
const CARDINAL_DIRECTIONS : Array = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
const CANTOR_LIMIT = int(pow(2, 30))

@export var resources : int = 6
@export var health : int = 10
@export var size_limit : int = 8

@onready var astar = AStar2D.new()
@onready var station_parts : TileMapLayer = %StationParts
@onready var cell_size := station_parts.tile_set.tile_size

var connected_parts : Array
var disconnected_parts : Array
var part_distance_map : Dictionary
var furthest_part_distance : int
var point_id_position_map : Dictionary[int, Vector2i]

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
		print("start_point: %v, %s ; end_point: %v, %s" % [start_position, has_point(start_position), end_position, has_point(end_position)])
		return []
	var astar_path := astar.get_point_path(get_point(start_position), get_point(end_position))
	return set_path_length(astar_path, max_distance)

func _map_parts_connected_to_center():
	connected_parts.clear()
	disconnected_parts.clear()
	part_distance_map.clear()
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

func _is_in_bounds(cellv : Vector2) -> bool:
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

func _expand_station(expand_max : int = 0) -> int:
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
	_expand_station(2)

func _ready():
	create_pathfinding_points()
	_map_parts_connected_to_center()

func _on_friendly_area_2d_body_entered(body):
	if body.has_method("remove_all_resources"):
		resources += body.remove_all_resources()

func _on_station_parts_tile_damaged(tile_id, _amount):
	station_parts.set_cell(tile_id)
	create_pathfinding_points()
	_map_parts_connected_to_center()
	for part in disconnected_parts:
		station_parts.set_cell(part)
