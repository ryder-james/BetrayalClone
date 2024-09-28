class_name Explorer
extends Node2D

@export var map: Map
@export var card: ExplorerCard

var current_floor: int :
	get: 
		return pathfinder.current_floor
	set(value): 
		pathfinder.current_floor = value

var _path_line: Line2D

@onready var pathfinder: Pathfinder = $Pathfinder


func _ready() -> void:
	_path_line = get_tree().get_first_node_in_group("path_line") as Line2D
	pathfinder.on_start_moving.connect(_draw_travel_path)
	pathfinder.on_target_reached.connect(hide_path)


func recalculate_path(target: Vector2i, target_floor := -1) -> void:
	pathfinder.recalculate_path(target, target_floor)


func get_travel_path() -> Array[Vector2i]:
	return pathfinder.get_travel_path()


func get_full_path() -> Array[Vector2i]:
	return pathfinder.get_full_path()


func draw_path() -> void:
	_draw_travel_path(get_travel_path())


func hide_path() -> void:
	if _path_line:
		_path_line.clear_points()


func _draw_travel_path(positions: Array[Vector2i]) -> void:	
	if not _path_line:
		return

	_path_line.default_color = card.color
	_path_line.clear_points()
	_path_line.add_point(global_position)
	for tile_position in positions:
		_path_line.add_point(map.get_tile_position_from_coords(tile_position))
