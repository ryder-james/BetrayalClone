class_name DrawPile
extends Node2D

const TILE_COUNT = 61
const TILES = preload("res://scenes/tiles.tres") as TileSet
const BACKS_SOURCE_ID = 2
const NO_TILE = -Vector2i.ONE

var _draw_pile: Array = []
var _discard_pile: Array = []
var _back_atlas: TileSetAtlasSource
var _draw_back_cache: Dictionary = {}

@onready var draw_back: Sprite2D = %DrawBack
@onready var discard_back: Sprite2D = %DiscardBack
@onready var draw_count: Label = %DrawCount
@onready var discard_count: Label = %DiscardCount


func _ready() -> void:
	_back_atlas = TILES.get_source(BACKS_SOURCE_ID) as TileSetAtlasSource
	_create_draw_pile()
	_update()


func get_current_back() -> Texture2D:
	return draw_back.texture


func peek() -> Vector2i:
	return _draw_pile[-1] if _draw_pile.size() > 0 else NO_TILE


func draw() -> Vector2i:
	if _draw_pile.size() == 0:
		_reshuffle_discard_pile()	
	
	var tile = _draw_pile.pop_back()
	_update()
	return tile


func discard() -> void:
	_discard_pile.append(draw())
	_update()


func _update() -> void:
	# Update textures
	draw_back.texture = _get_back(peek())
	if _discard_pile.size() > 0:
		discard_back.texture = _get_back(_discard_pile[-1])
	else:
		discard_back.texture = null
	
	# Update counts
	draw_count.text = "%s" % _draw_pile.size()
	discard_count.text = "%s" % _discard_pile.size()


func _get_back(tile_id: Vector2i) -> Texture2D:
	if tile_id == -Vector2i.ONE:
		if _draw_back_cache.has(0):
			return _draw_back_cache[0]
		else:
			var texture = _create_back_texture_from_atlas(Vector2i.ZERO)
			_draw_back_cache[0] = texture
			return texture
	
	var tile_data = TileManager.get_tile_info(tile_id)
	var tile_floors = tile_data.floors
	
	if _draw_back_cache.has(tile_floors):
		return _draw_back_cache[tile_floors]
	
	var back_id = Vector2i(tile_floors % 4, tile_floors / 4)
	var back_data = _back_atlas.get_tile_data(back_id, 0)
	if back_data.get_custom_data("Floor") == tile_floors:
		var texture = _create_back_texture_from_atlas(back_id)
		_draw_back_cache[tile_floors] = texture
		return texture
	
	return null


func _create_back_texture_from_atlas(back_id: Vector2i) -> Texture2D:
	var tex_subregion = AtlasTexture.new()
	tex_subregion.set_atlas(_back_atlas.get_texture())
	tex_subregion.set_region(_back_atlas.get_runtime_tile_texture_region(back_id, 0))
	return tex_subregion


func _reshuffle_discard_pile() -> void:
	for n in _discard_pile.size():
		# Pick a random available tile
		var tile_index = randi_range(0, _discard_pile.size() - 1)
		
		# Remove it from the available tiles
		var tile = _discard_pile[tile_index]
		_discard_pile.remove_at(tile_index)
		
		# Convert that into IDs for TileMap and add to DrawPile
		_draw_pile.append(tile)


func _create_draw_pile() -> void:
	var available_tiles = []
	
	# Initialize an array containing all possible tile indices
	for i in TILE_COUNT:
		available_tiles.append(i)
	
	for n in TILE_COUNT:
		# Pick a random available tile
		var tile_index = randi_range(0, available_tiles.size() - 1)
		
		# Remove it from the available tiles
		var tile = available_tiles[tile_index] + 3
		available_tiles.remove_at(tile_index)
		
		# Convert that into IDs for TileMap and add to DrawPile
		_draw_pile.append(Vector2i(tile % 8, tile / 8))
