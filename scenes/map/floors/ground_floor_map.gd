extends FloorMap


func get_door_legality(tile_position: Vector2i, doors: int, rotations := 0) -> Map.DoorLegality:
	if tile_position == Vector2i(1, 0):
		return Map.DoorLegality.ILLEGAL
	
	return super.get_door_legality(tile_position, doors, rotations)


func place_landing() -> void:
	# Register Foyer tile
	place_tile(Vector2i.ZERO, TileManager.get_tile_info_from_name("Entrance Hall"))
	place_tile(Vector2i(-1, 0), TileManager.get_tile_info_from_name("Foyer"))
	place_tile(Vector2i(-2, 0), TileManager.get_tile_info_from_name("Grand Staircase"))