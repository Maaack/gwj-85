extends Node2D
class_name AStarGridServer

var astar : AStarGrid2D
@export var region : Rect2i = Rect2i(0, 0, 32, 32)
@export var cell_size : Vector2i = Vector2i(16, 16)
@export var exclude_tilemaps : Array[TileMapLayer]
@export var collision_groups : Array[String]
@export_category("Debugging")
@export var debug_cell_texture : Texture2D
@export var debug_update_time : float = 0
var current_debug_update_time : float = 0
var dynamic_solid_points : Dictionary = {}
var static_solid_points : Array = [] 

func set_path_length(point_path: Array, max_distance: int) -> Array:
	if max_distance < 0:
		return point_path
	point_path.resize(min(point_path.size(), max_distance))
	return point_path

func exclude_tilemap(tilemap : TileMapLayer):
	var layer_count = tilemap.get_layers_count()
	var x_size = region.size.x
	var y_size = region.size.y
	for layer_iter in range(layer_count):
		for x in range(x_size):
			for y in range(y_size):
				var astar_vector = Vector2i(x, y) + region.position
				var ratio = Vector2(cell_size) / Vector2(tilemap.tile_set.tile_size)
				var x_total = floor(astar_vector.x * ratio.x)
				var y_total = floor(astar_vector.y * ratio.y)
				var coord2i = Vector2i(x_total, y_total)
				var results = tilemap.get_cell_source_id(coord2i)
				if results > -1:
					astar.set_point_solid(astar_vector, true)
					static_solid_points.append(astar_vector)

func _process_debug(delta):
	if not get_tree().debug_navigation_hint:
		return
	if debug_update_time <= 0:
		return
	current_debug_update_time += delta
	if current_debug_update_time < debug_update_time:
		return
	current_debug_update_time = debug_update_time - current_debug_update_time
	queue_redraw()

func _process(delta):
	_process_debug(delta)

func _ready_astargrid():
	astar = AStarGrid2D.new()
	astar.region = region
	astar.cell_size = Vector2(cell_size)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	astar.jumping_enabled = true
	astar.update()

func _ready_wall_points():
	for tilemap in exclude_tilemaps:
		exclude_tilemap(tilemap)

func _ready() -> void:
	_ready_astargrid()
	_ready_wall_points()

func _draw():
	if not get_tree().debug_navigation_hint:
		return
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var draw_coords = Vector2(x, y) * Vector2(cell_size) - debug_cell_texture.get_size()/2
			draw_coords += Vector2(get_half_cell_size())
			if astar.is_point_solid(Vector2i(x, y)):
				draw_texture(debug_cell_texture, draw_coords, Color.RED)
			else:
				draw_texture(debug_cell_texture, draw_coords)

func set_points_disabled(points : Array, disabled : bool = true) -> void:
	for point_vector in points:
		point_vector = Vector2i(point_vector)
		if astar.is_in_boundsv(point_vector):
			astar.set_point_solid(point_vector, disabled)

func set_group_disabled(group_name : String, disabled : bool = true):
	if group_name not in dynamic_solid_points.keys():
		return
	for pointID in dynamic_solid_points[group_name]:
		astar.set_point_solid(pointID, disabled)

func get_astar_path(start_cell: Vector2, end_cell: Vector2, max_distance := -1) -> Array:
	if not astar.is_in_boundsv(start_cell) or not astar.is_in_boundsv(end_cell):
		return []
	var astar_path := astar.get_point_path(start_cell, end_cell)
	return set_path_length(astar_path, max_distance)

func get_astar_path_avoiding_points(start_cell: Vector2, end_cell: Vector2, avoid_cells : Array = [], max_distance := -1) -> Array:
	set_points_disabled(avoid_cells)
	var astar_path := get_astar_path(start_cell, end_cell, max_distance)
	set_points_disabled(avoid_cells, false)
	return astar_path
	
func get_half_cell_size() -> Vector2i:
	return cell_size / 2

func get_nearest_tile_position(check_position : Vector2) -> Vector2i :
	return (Vector2i(round(check_position))) / cell_size

func get_world_path_avoiding_points(start_position: Vector2, end_position: Vector2, avoid_positions : Array = [], max_distance := -1) -> Array:
	var start_cell := get_nearest_tile_position(start_position)
	var end_cell := get_nearest_tile_position(end_position)
	var avoid_cells := []
	for avoid_position in avoid_positions:
		avoid_cells.append(get_nearest_tile_position(avoid_position))
	var return_path = get_astar_path_avoiding_points(start_cell, end_cell, avoid_cells, max_distance)
	return add_half_cell_to_path(return_path)

func add_half_cell_to_path(path : Array) -> Array[Vector2]:
	var return_path : Array[Vector2] = []
	for cell_vector in path:
		return_path.append(cell_vector + Vector2(get_half_cell_size()))
	return return_path
