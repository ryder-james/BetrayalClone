extends Node
# Autoload as TileManager

const TILE_SIZE = 512
const TILES = preload("res://scenes/map/tiles.tres") as TileSet
const TILE_SOURCE_ID = 0
const FOYER_SOURCE_ID = 1
const DOOR_BIT := 0

var _tile_name_cache: Dictionary = {}
var _tile_cache: Dictionary = {}
var _tile_atlas: TileSetAtlasSource
var _foyer_atlas: TileSetAtlasSource


func _ready() -> void:
	_tile_atlas = TILES.get_source(TILE_SOURCE_ID) as TileSetAtlasSource
	_foyer_atlas = TILES.get_source(FOYER_SOURCE_ID) as TileSetAtlasSource


func get_tile_info_from_name(tile_name: String) -> TileInfo:
	if _tile_name_cache.has(tile_name):
		return _get_tile_data(_tile_name_cache[tile_name]).info

	if (tile_name == "Entrance Hall"
			or tile_name == "Foyer"
			or tile_name == "Grand Staircase"):
		for tile_index in _foyer_atlas.get_tiles_count():
			var tile_id = _foyer_atlas.get_tile_id(tile_index)
			var tile_data = _foyer_atlas.get_tile_data(tile_id, 0)
			if (tile_data.get_custom_data("Name") == tile_name):
				return _get_tile_data(tile_id, FOYER_SOURCE_ID).info
	else:
		for tile_index in _tile_atlas.get_tiles_count():
			var tile_id = _tile_atlas.get_tile_id(tile_index)
			var tile_data = _tile_atlas.get_tile_data(tile_id, 0)
			if (tile_data.get_custom_data("Name") == tile_name):
				return _get_tile_data(tile_id).info
	
	return null


func get_links(_tile_name: String) -> Dictionary:
	return {}


func get_tile_info(tile_id: Vector2i) -> TileInfo:
	return _get_tile_data(tile_id).info


func get_tile_texture(tile_id: Vector2i) -> Texture2D:
	var tex_subregion = AtlasTexture.new()
	tex_subregion.set_atlas(_tile_atlas.get_texture())
	tex_subregion.set_region(_tile_atlas.get_runtime_tile_texture_region(tile_id, 0))
	return tex_subregion


func _get_tile_data_from_name(tile_name: String) -> TileData:
	if _tile_name_cache.has(tile_name):
		return _get_tile_data(_tile_name_cache[tile_name]).data

	if (tile_name == "Entrance Hall"
			or tile_name == "Foyer"
			or tile_name == "Grand Staircase"):
		for tile_index in _foyer_atlas.get_tiles_count():
			var tile_id = _foyer_atlas.get_tile_id(tile_index)
			var tile_data = _foyer_atlas.get_tile_data(tile_id, 0)
			if (tile_data.get_custom_data("Name") == tile_name):
				return _get_tile_data(tile_id, FOYER_SOURCE_ID).data
	else:
		for tile_index in _tile_atlas.get_tiles_count():
			var tile_id = _tile_atlas.get_tile_id(tile_index)
			var tile_data = _tile_atlas.get_tile_data(tile_id, 0)
			if (tile_data.get_custom_data("Name") == tile_name):
				return _get_tile_data(tile_id, TILE_SOURCE_ID).data
	
	return null


func _get_tile_data(tile_id: Vector2i, source := TILE_SOURCE_ID) -> Tile:
	var internal_id = Vector3i(tile_id.x, tile_id.y, source)
	if _tile_cache.has(internal_id):
		return _tile_cache[internal_id]
	
	var tile_data: TileData
	if source == FOYER_SOURCE_ID:
		tile_data = _foyer_atlas.get_tile_data(tile_id, 0)
	else:
		tile_data = _tile_atlas.get_tile_data(tile_id, 0)
	
	var doors = Direction.NONE
	if tile_data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE) == DOOR_BIT:
		doors |= Direction.UP
	if tile_data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE) == DOOR_BIT:
		doors |= Direction.RIGHT
	if tile_data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE) == DOOR_BIT:
		doors |= Direction.DOWN
	if tile_data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE) == DOOR_BIT:
		doors |= Direction.LEFT
	
	var tile_info = TileInfo.new()
	tile_info.name = tile_data.get_custom_data("Name")
	tile_info.doors = doors
	tile_info.floors = tile_data.get_custom_data("Floor")
	tile_info.id = tile_id
	tile_info.source = source

	var tile = Tile.new()
	tile.data = tile_data
	tile.info = tile_info
	
	_tile_name_cache[tile_info.name] = internal_id
	_tile_cache[internal_id] = tile

	return tile


class Tile:
	var data: TileData
	var info: TileInfo
