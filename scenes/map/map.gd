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
var explorers_on_floor: Array[Explorer] :
		get: return active_floor_map.explorers
var _existing_tiles: Dictionary
var _floors: Array[FloorMap]

@onready var basement: FloorMap = %Basement
@onready var ground_floor: FloorMap = %GroundFloor
@onready var upper_floor: FloorMap = %UpperFloor
@onready var roof: FloorMap = %Roof


func _ready() -> void:
	active_floor_map = ground_floor
	_floors = [
		basement,
		ground_floor,
		upper_floor,
		roof,
	]
	basement.tile_placed.connect(_on_floor_tile_placed)
	ground_floor.tile_placed.connect(_on_floor_tile_placed)
	upper_floor.tile_placed.connect(_on_floor_tile_placed)
	roof.tile_placed.connect(_on_floor_tile_placed)
	basement.place_landing()
	ground_floor.place_landing()
	upper_floor.place_landing()
	roof.place_landing()


func change_floor(new_floor_raw: float) -> void:
	var new_floor = int(new_floor_raw) - 1
	for map_floor in _floors:
		map_floor.visible = false
	active_floor_map = _floors[new_floor]
	active_floor = active_floor_map.map_floor
	active_floor_map.visible = true


func place_tile(map_coords: Vector2i, tile_id: Vector2i, rotations := 0, tile_floor := -1) -> void:
	var tile_info = TileManager.get_tile_info(tile_id)
	_get_floor(tile_floor).place_tile(map_coords,
			tile_info,
			rotations)


func tile_exists(tile_name: String) -> bool:
	return _existing_tiles.has(tile_name)


func get_linked_tiles(map_coords: Vector2i, tile_floor := -1) -> Array[Dictionary]:
	var existing_links: Array[Dictionary] = []
	var all_links = _get_floor(tile_floor).get_linked_tiles(map_coords)

	for link in all_links:
		if _existing_tiles.has(link.name):
			var linked_tile: Tile = _existing_tiles[link.name]
			link.position = linked_tile.position
			link.floor = linked_tile.map_floor
			link.doors = linked_tile.doors
			existing_links.append(link)
	
	return existing_links


func get_tile_position(global_pos: Vector2, tile_floor := -1) -> Vector2:
	var coords = get_tile_coords(global_pos)
	return _get_floor(tile_floor).map_to_local(coords)


func get_tile_position_from_coords(tile_coords: Vector2i, tile_floor := -1) -> Vector2:
	return _get_floor(tile_floor).map_to_local(tile_coords)


func get_tile_coords(global_pos: Vector2, tile_floor := -1) -> Vector2i:
	var local = _get_floor(tile_floor).to_local(global_pos)
	return _get_floor(tile_floor).local_to_map(local)


func get_tile(map_coords: Vector2i, tile_floor := -1) -> Tile:
	return _get_floor(tile_floor).get_tile(map_coords)


func get_neighbors(map_coords: Vector2i, tile_floor := -1) -> Dictionary:
	return _get_floor(tile_floor).get_neighbors(map_coords)


func get_door_legality(tile_position: Vector2i, tile_id: Vector2i, rotations := 0, tile_floor := -1) -> DoorLegality:
	var tile_info = TileManager.get_tile_info(tile_id)
	if not tile_info:
		return DoorLegality.ILLEGAL
	return _get_floor(tile_floor).get_door_legality(tile_position, tile_info.doors, rotations)


func get_legal_rotations(tile_position: Vector2i, tile_id: Vector2i, origin_direction: int, tile_floor := -1) -> Array:
	var tile_info = TileManager.get_tile_info(tile_id)
	if not tile_info:
		return []
	return _get_floor(tile_floor).get_legal_rotations(tile_position, tile_info, origin_direction)


func _on_floor_tile_placed(tile: Tile) -> void:
	_existing_tiles[tile.name] = tile


func _get_floor(tile_floor: int) -> FloorMap:
	match tile_floor:
		BASEMENT:
			return basement
		GROUND:
			return ground_floor
		UPPER:
			return upper_floor
		ROOF:
			return roof
	
	return active_floor_map


class Tile:
	var name: String
	var doors: int
	var position: Vector2i
	var map_floor: int
	var id: Vector2i
	var rotations: int