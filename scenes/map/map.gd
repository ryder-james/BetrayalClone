class_name Map
extends Node2D

enum DoorLegality {
	ILLEGAL,
	WRONG_ROTATION,
	LEGAL,
}

const BASEMENT = 1
const GROUND = 2
const UPPER = 4
const ROOF = 8

var active_floor_map: FloorMap
var active_floor := GROUND

@onready var ground_floor: FloorMap = %GroundFloor


func _ready() -> void:
	active_floor_map = ground_floor


func place_tile(map_coords: Vector2i, tile_id: Vector2i, rotations := 0) -> void:
	active_floor_map.place_tile(map_coords,
			TileManager.get_tile_info(tile_id),
			rotations)


func get_tile_position(global_pos: Vector2) -> Vector2:
	var coords = get_tile_coords(global_pos)
	return active_floor_map.map_to_local(coords)


func get_tile_position_from_coords(tile_coords: Vector2i) -> Vector2:
	return active_floor_map.map_to_local(tile_coords)


func get_tile_coords(global_pos: Vector2) -> Vector2i:
	var local = active_floor_map.to_local(global_pos)
	return active_floor_map.local_to_map(local)


func get_tile_info(map_coords: Vector2i) -> Dictionary:
	return active_floor_map.get_tile_info(map_coords)


func get_neighbors(map_coords: Vector2i, include_empty := true) -> Dictionary:
	return active_floor_map.get_neighbors(map_coords, include_empty)


func get_door_legality(tile_position: Vector2i, tile_id: Vector2i, rotations := 0) -> DoorLegality:
	var tile_info = TileManager.get_tile_info(tile_id)
	if not tile_info:
		return DoorLegality.ILLEGAL
	return active_floor_map.get_door_legality(tile_position, tile_info.doors, rotations)


func get_legal_rotations(tile_position: Vector2i, tile_id: Vector2i, origin_direction: int) -> Array:
	var tile_info = TileManager.get_tile_info(tile_id)
	if not tile_info:
		return []
	return active_floor_map.get_legal_rotations(tile_position, tile_info, origin_direction)
