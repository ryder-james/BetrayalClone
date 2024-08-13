extends Node
# Autoload as TileManager

const TILES = preload("res://scenes/map/tiles.tres") as TileSet
const TILE_SOURCE_ID = 0
const FOYER_SOURCE_ID = 1
const DOOR_BIT := 0

#region Foyer Tiles
const ENTRANCE_HALL = {
	name = "Entrance Hall",
	doors = Direction.UP | Direction.DOWN | Direction.LEFT,
	id = Vector2i(2, 0),
	source = FOYER_SOURCE_ID,
}
const FOYER = {
	name = "Foyer",
	doors = Direction.UP | Direction.RIGHT | Direction.DOWN | Direction.LEFT,
	id = Vector2i(1, 0),
	source = FOYER_SOURCE_ID,
}
const GRAND_STAIRCASE = {
	name = "Grand Staircase",
	doors = Direction.RIGHT,
	id = Vector2i.ZERO,
	source = FOYER_SOURCE_ID,
}
#endregion

var _tile_name_cache: Dictionary = {}
var _tile_data_cache: Dictionary = {}
var _tile_atlas: TileSetAtlasSource


func _ready() -> void:
	_tile_atlas = TILES.get_source(0) as TileSetAtlasSource


func get_tile_info_from_name(tile_name: String) -> Dictionary:
	var foyer_tile = _get_foyer_tile(tile_name)
	if foyer_tile:
		return foyer_tile
	
	if _tile_name_cache.has(tile_name):
		return _get_tile_info(_tile_name_cache[tile_name])
	
	for tile_index in _tile_atlas.get_tiles_count():
		var tile_id = _tile_atlas.get_tile_id(tile_index)
		var tile_data = _tile_atlas.get_tile_data(tile_id, 0)
		if (tile_data.get_custom_data("Name") == tile_name):
			return _get_tile_info(tile_id)
	
	return {}


func get_tile_info(tile_id: Vector2i) -> Dictionary:
	return _get_tile_info(tile_id)


func get_tile_texture(tile_id: Vector2i) -> Texture2D:
	var tex_subregion = AtlasTexture.new()
	tex_subregion.set_atlas(_tile_atlas.get_texture())
	tex_subregion.set_region(_tile_atlas.get_runtime_tile_texture_region(tile_id, 0))
	return tex_subregion

func _get_foyer_tile(tile_name: String) -> Dictionary:
	match tile_name:
		"Entrance Hall":
			return ENTRANCE_HALL
		"Foyer":
			return FOYER
		"Grand Staircase":
			return GRAND_STAIRCASE
	
	return {}


func _get_tile_info(tile_id: Vector2i) -> Dictionary:
	if _tile_data_cache.has(tile_id):
		return _tile_data_cache[tile_id]
	
	var tile_data = _tile_atlas.get_tile_data(tile_id, 0)
	
	var doors = Direction.NONE
	if tile_data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE) == DOOR_BIT:
		doors |= Direction.UP
	if tile_data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE) == DOOR_BIT:
		doors |= Direction.RIGHT
	if tile_data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE) == DOOR_BIT:
		doors |= Direction.DOWN
	if tile_data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE) == DOOR_BIT:
		doors |= Direction.LEFT
	
	var tile_obj = {
		name = tile_data.get_custom_data("Name"),
		doors = doors,
		floors = tile_data.get_custom_data("Floor"),
		id = tile_id,
		source = TILE_SOURCE_ID,
	}
	
	_tile_name_cache[tile_obj.name] = tile_id
	_tile_data_cache[tile_id] = tile_obj
	return tile_obj
