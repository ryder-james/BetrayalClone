class_name FloorMap
extends TileMap

const ROTATION_90 := TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
const ROTATION_180 := TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
const ROTATION_270 := TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V

@export_enum("Basement:1", "Ground:2", "Upper:4", "Roof:8") var map_floor: int

var _map = {}


func _ready() -> void:
	_place_landing()


func _place_landing() -> void:
	pass


func get_tile_info(tile_position: Vector2i) -> Dictionary:
	if _map.has(tile_position):
		return _map[tile_position]
	
	return {}


func get_legal_rotations(tile_position: Vector2i, tile_info: Dictionary, origin_direction: int) -> Array:
	# Prioritize first connecting to at least the door we started from,
	#   then to maximizing remaining open doors.
	
	var best := 0
	var door_rotations = {}
	for rotation_count in 4:
		var legality = get_door_legality(tile_position, tile_info.doors, rotation_count)
		match legality:
			Map.DoorLegality.ILLEGAL:
				return []
			Map.DoorLegality.LEGAL:
				var unblocked = get_unblocked_doors(tile_position, tile_info.doors,
						rotation_count)
				if has_door_facing(tile_info, origin_direction, rotation_count):
					door_rotations[rotation_count] = unblocked
				if unblocked > best:
					best = unblocked
	
	var best_placements = []
	for c_rotations in door_rotations.keys():
		if door_rotations[c_rotations] == best:
			best_placements.append(c_rotations)
	
	best_placements.sort()
	return best_placements


func place_tile(tile_position: Vector2i, tile_info: Dictionary, rotations := 0) -> void:
	var rotated_doors = tile_info.doors
	for n in rotations:
		rotated_doors = Direction.rotate_c(rotated_doors)
	
	var map_obj = {
		name = tile_info.name,
		doors = rotated_doors,
		tile_position = tile_position,
		id = tile_info.id,
		rotations = rotations,
	}
	_map[tile_position] = map_obj
	
	var rotation_flags = 0
	if rotations == 1:
		rotation_flags = ROTATION_90
	elif rotations == 2:
		rotation_flags = ROTATION_180
	elif rotations == 3:
		rotation_flags = ROTATION_270
	
	set_cell(0, tile_position, tile_info.source, tile_info.id, rotation_flags)


func get_door_legality(tile_position: Vector2i, doors: int, rotations := 0) -> Map.DoorLegality:
	for rot_count in rotations:
		doors = Direction.rotate_c(doors)
	
	var neighbors = get_neighbors(tile_position)
	
	var possible_neighbors = []
	for direction in neighbors.keys():
		if neighbors[direction] and neighbors[direction].doors > 0:
			possible_neighbors.append(direction)
	
	if possible_neighbors.size() == 0:
		return Map.DoorLegality.ILLEGAL
	
	for i in range(possible_neighbors.size() - 1, -1, -1):		
		var direction = possible_neighbors[i]
		
		# If that neighbor doesn't have a door looking at us, remove it
		var opp = Direction.opposite(direction)
		if neighbors[direction].doors & opp != opp:
			possible_neighbors.remove_at(i)
	
	# None of our neighbors have a door to us
	if possible_neighbors.size() == 0:
		return Map.DoorLegality.ILLEGAL
	
	var opens_to_neighbor := false
	for i in possible_neighbors.size():		
		var direction = possible_neighbors[i]
		
		# If we have a door in that neighbor's direction, we're golden
		if doors & direction == direction:
			opens_to_neighbor = true
			break
	
	if opens_to_neighbor:
		return Map.DoorLegality.LEGAL
	else:
		return Map.DoorLegality.WRONG_ROTATION


func get_unblocked_doors(tile_position: Vector2i, doors: int, rotation_count := 0) -> int:
	var rotated_doors = doors
	for n in rotation_count:
		rotated_doors = Direction.rotate_c(rotated_doors)
	
	var neighbors = get_neighbors(tile_position)
	
	var unblocked_count := 0
	for direction in neighbors.keys():
		if direction == Direction.NONE:
			continue
		if not neighbors[direction] and rotated_doors & direction == direction:
			unblocked_count += 1
	
	return unblocked_count


func has_door_facing(tile_info: Dictionary, direction: int, rotations := 0) -> bool:
	var rotated_doors = tile_info.doors
	for n in rotations:
		rotated_doors = Direction.rotate_c(rotated_doors)
	return rotated_doors & direction == direction


func get_neighbors(map_coords: Vector2i, include_empty := true) -> Dictionary:
	var neighbors = {}
	neighbors[Direction.NONE] = get_tile_info(map_coords)
	
	var up = map_coords + Vector2i.UP
	var right = map_coords + Vector2i.RIGHT
	var down = map_coords + Vector2i.DOWN
	var left = map_coords + Vector2i.LEFT
	
	if include_empty:
		neighbors[Direction.UP] = get_tile_info(up)
		neighbors[Direction.RIGHT] = get_tile_info(right)
		neighbors[Direction.DOWN] = get_tile_info(down)
		neighbors[Direction.LEFT] = get_tile_info(left)
	else:
		if get_tile_info(up):
			neighbors[Direction.UP] = get_tile_info(up)
		if get_tile_info(right):
			neighbors[Direction.RIGHT] = get_tile_info(right)
		if get_tile_info(down):
			neighbors[Direction.DOWN] = get_tile_info(down)
		if get_tile_info(left):
			neighbors[Direction.LEFT] = get_tile_info(left)
	
	return neighbors



