class_name Explorer
extends Node2D

@export var map: Map

var current_floor: int :
	get: 
		return pathfinder.current_floor
	set(value): 
		pathfinder.current_floor = value

var _path_line: Line2D

@onready var pathfinder: Pathfinder = $Pathfinding


func _ready() -> void:
	_path_line = get_tree().get_first_node_in_group("path_line") as Line2D


func recalculate_path(target: Vector2i, target_floor := -1) -> void:
	pathfinder.recalculate_path(target, target_floor)


func get_travel_path() -> Array[Vector2i]:
	return pathfinder.get_travel_path()


func draw_path() -> void:
	pass
	# if not _path_line:
	# 	return
	
	# _path_line.clear_points()
	# if _is_traveling:
	# 	_path_line.add_point(global_position)
	# 	_path_line.add_point(_next_point)
	# for node in _path:
	# 	_path_line.add_point(map.get_tile_position_from_coords(node.position))


func hide_path() -> void:
	pass
	# if _path_line:
	# 	_path_line.clear_points()
