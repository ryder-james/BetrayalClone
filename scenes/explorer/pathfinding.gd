class_name Pathfinder
extends Node2D

signal on_start_moving(positions_on_floor: Array[Vector2])
signal on_stop_moving
signal on_target_changed(target_position: Vector2i, target_floor: int)
signal on_target_reached

var map: Map
var current_floor = Map.GROUND

var _speed := 3.5
var _path: Array[PathNode] = []
var _target_queue: Array[Vector3i]
var _active_target: Vector3i
var _has_active_target := false
var _next_point: Vector2
var _current_point: Vector2
var _is_traveling := false

@onready var explorer: Explorer = $".."


func _ready() -> void:
	Event.on_target_updated.connect(_on_target_updated)
	map = get_tree().get_first_node_in_group("map") as Map


func _process(delta: float) -> void:
	if not _has_active_target and _target_queue.size() > 0:
		_active_target = _target_queue.pop_back()
		_has_active_target = true
		_recalculate_path_internal(_active_target)
		on_target_changed.emit(Vector2i(_active_target.x, _active_target.y), _active_target.z)
		_path.pop_front()

	if _has_active_target and not _is_traveling and _path.size() > 0:
		_is_traveling = true
		var next_node = _path.pop_front()
		_next_point = map.get_tile_position_from_coords(next_node.position, next_node.map_floor)
	
	if _is_traveling:
		on_start_moving.emit()
		explorer.global_position = explorer.global_position.lerp(_next_point, delta * _speed)
		if (_next_point - explorer.global_position).length_squared() <= 750.0:
			_is_traveling = false
			_current_point = _next_point
			_next_point = Vector2.ZERO
			_recalculate_path_internal(_active_target)
			_path.pop_front()
			if _path.size() == 0:
				on_target_reached.emit()
				explorer.global_position = _current_point
				_has_active_target = false


func get_travel_path() -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for node in _path:
		path.append(node.position)
	return path


func recalculate_path(target: Vector2i, target_floor := -1) -> void:
	if _has_active_target:
		return
	if target_floor < Map.BASEMENT:
		target_floor = current_floor
	_recalculate_path_internal(Vector3i(target.x, target.y, target_floor))
	

func _recalculate_path_internal(target_id: Vector3i) -> void:
	var start: Vector2i = map.get_tile_coords(explorer.global_position)

	var open: Dictionary = {}
	var closed: Dictionary = {}
	var all_nodes: Dictionary = {}
	
	# Add the starting square (or node) to the open list
	var first_node = PathNode.new()
	first_node.position = start
	first_node.map_floor = current_floor
	first_node.doors = map.get_tile(start, current_floor).doors
	first_node.has_parent = false
	first_node.weight = 0
	first_node.heuristic = (target_id - first_node.pos_id).length_squared()
	first_node.f = 0

	open[first_node.pos_id] = first_node
	all_nodes[first_node.pos_id] = first_node
	
	while open.keys().size() > 0:
		# Arbitrarily high number
		var lowest_f := 6000.0
		var current: PathNode
		for node in open.values():
			if node.f < lowest_f:
				lowest_f = node.f
				current = node
		open.erase(current.pos_id)
		closed[current.pos_id] = current
		
		if current.pos_id == target_id:
			var path: Array[PathNode] = []
			var path_point: PathNode = current
			while path_point:
				# TODO: This will be broken when moving between floors.
				path.append(path_point)
				if path_point.has_parent:
					path_point = closed[path_point.parent_id]
				else:
					path_point = null
			path.reverse()
			_path = path
			return
		
		var neighbors = map.get_neighbors(current.position, current.map_floor)
		for direction in neighbors:
			var neighbor_position = current.position + Direction.as_vector(direction)			
			if neighbor_position == current.position:
				continue
			
			# If we don't point at them, move on
			if current.doors & direction != direction:
				continue
			
			# If there is a tile there, we need to see if they point at us
			if neighbors[direction]:
				# If they don't point at us, move on
				var opp = Direction.opposite(direction)
				if neighbors[direction].doors & opp != opp:
					continue

			var doors = neighbors[direction].doors if neighbors[direction] else Direction.opposite(direction)
			var child = PathNode.new()
			child.position = neighbor_position
			child.map_floor = current.map_floor
			child.doors = doors
			child.parent_id = current.pos_id
			child.has_parent = true
			
			all_nodes[child.pos_id] = child
			current.child_ids.append(child.pos_id)
		
		var linked_tiles = map.get_linked_tiles(current.position, current.map_floor)
		for link in linked_tiles:
			var child = PathNode.new()
			child.position = link.position
			child.map_floor = link.floor
			child.doors = link.doors
			child.parent_id = current.pos_id
			child.has_parent = true
			
			all_nodes[child.pos_id] = child
			current.child_ids.append(child.pos_id)
		
		for child_id in current.child_ids:
			if closed.has(child_id):
				continue
			
			# TODO: Sub 1 for node weight (enemy team or w/e)
			all_nodes[child_id].weight = current.weight + 1
			all_nodes[child_id].heuristic = (target_id - child_id).length_squared()
			all_nodes[child_id].f = all_nodes[child_id].weight + all_nodes[child_id].heuristic
			
			for node_id in open:
				if child_id == node_id and all_nodes[child_id].weight > open[node_id].weight:
					continue
			
			open[child_id] = all_nodes[child_id]
	
	_path = [ first_node ]


func _on_target_updated(new_target: Vector2i, map_floor: int) -> void:
	var target = Vector3i(new_target.x, new_target.y, map_floor)
	_target_queue.push_front(target)


class PathNode:
	var pos_id: Vector3i :
		get:
			return Vector3(position.x, position.y, map_floor)
		set(value):
			position = Vector2i(value.x, value.y)
			map_floor = value.z
	var position: Vector2i
	var map_floor: int = Map.GROUND
	var doors: int = Direction.NONE
	var parent_id: Vector3i
	var has_parent: bool = false
	var child_ids: Array[Vector3i] = []
	var weight: int
	var heuristic: int
	var f: int
