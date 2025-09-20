extends TileMapLayer

signal tile_damaged(tile_id : Vector2i, amount : float)

func damage(amount : float = 1.0, location : Vector2 = global_position) -> void:
	var relative_location = location - (global_position - position)
	var tile_size := tile_set.tile_size
	var relative_tile : Vector2i = round(relative_location / Vector2(tile_set.tile_size))
	if get_cell_source_id(relative_tile) == -1: return
	tile_damaged.emit(relative_tile, amount)
