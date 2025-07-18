class_name FloorMap
extends TileMap

signal tile_placed(tile: Map.Tile)

const ROTATION_90 := TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
const ROTATION_180 := TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
const ROTATION_270 := TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V

@export_enum("Basement:%s" % Map.BASEMENT, "Ground:%s" % Map.GROUND, "Upper:%s" % Map.UPPER, "Roof:%s" % Map.ROOF) var map_floor: int = Map.BASEMENT

var explorers: Array[Explorer] = []
var _map = {}


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("explorer"):
		if get_children().has(node):
			explorers.append(node as Explorer)


func place_landing() -> void:
	# Register Landing tile
	var landing_name = "%s Landing" % (
			"Basement" if map_floor == Map.BASEMENT
			else "Upper" if map_floor == Map.UPPER
			else "Roof")
	place_tile(Vector2i.ZERO, TileManager.get_tile_info_from_name(landing_name))


func get_tile(tile_position: Vector2i) -> Map.Tile:
	if _map.has(tile_position):
		return _map[tile_position]
	
	return null


func get_legal_rotations(tile_position: Vector2i, tile_info: TileInfo, origin_direction: int) -> Array:
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


func place_tile(tile_position: Vector2i, tile_info: TileInfo, rotations := 0) -> void:
	var rotated_doors = tile_info.doors
	for n in rotations:
		rotated_doors = Direction.rotate_c(rotated_doors)
	
	var map_tile = Map.Tile.new()
	map_tile.name = tile_info.name
	map_tile.doors = rotated_doors
	map_tile.position = tile_position
	map_tile.map_floor = map_floor
	map_tile.id = tile_info.id
	map_tile.rotations = rotations
	_map[tile_position] = map_tile
	
	var rotation_flags = 0
	if rotations == 1:
		rotation_flags = ROTATION_90
	elif rotations == 2:
		rotation_flags = ROTATION_180
	elif rotations == 3:
		rotation_flags = ROTATION_270
	
	set_cell(0, tile_position, tile_info.source, tile_info.id, rotation_flags)
	tile_placed.emit(map_tile)


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


func has_door_facing(tile_info: TileInfo, direction: int, rotations := 0) -> bool:
	var rotated_doors = tile_info.doors
	for n in rotations:
		rotated_doors = Direction.rotate_c(rotated_doors)
	return rotated_doors & direction == direction


func get_linked_tiles(map_coords: Vector2i) -> Array[Dictionary]:
	var tile = get_tile(map_coords)
	if not tile:
		return []
	return TileManager.get_linked_tiles(get_tile(map_coords).name)


func get_neighbors(map_coords: Vector2i, include_empty := true) -> Dictionary:
	var neighbors = {}
	neighbors[Direction.NONE] = get_tile(map_coords)
	
	var up = get_tile(map_coords + Vector2i.UP)
	var right = get_tile(map_coords + Vector2i.RIGHT)
	var down = get_tile(map_coords + Vector2i.DOWN)
	var left = get_tile(map_coords + Vector2i.LEFT)
	
	if include_empty:
		neighbors[Direction.UP] = up
		neighbors[Direction.RIGHT] = right
		neighbors[Direction.DOWN] = down
		neighbors[Direction.LEFT] = left
	else:
		if up:
			neighbors[Direction.UP] = up
		if right:
			neighbors[Direction.RIGHT] = right
		if down:
			neighbors[Direction.DOWN] = down
		if left:
			neighbors[Direction.LEFT] = left
	
	return neighbors
