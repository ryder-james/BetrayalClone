class_name Explorer
extends Node2D

@export var map: Map

var current_floor = Map.GROUND
var _speed := 3.5
var _path = []
var _target_queue: Array
var _next_point: Vector2
var _current_point: Vector2
var _path_line: Line2D
var _is_traveling := false


func _ready() -> void:
	Event.on_target_updated.connect(_on_target_updated)
	_path_line = get_tree().get_first_node_in_group("path_line") as Line2D


func _process(delta: float) -> void:
	if _path.size() == 0 and _target_queue.size() > 0:
		_path = calculate_path(_target_queue.pop_back())

	if not _is_traveling and _path.size() > 0:
		_is_traveling = true
		_next_point = map.get_tile_position_from_coords(_path.pop_front())
	
	if _is_traveling:
		draw_path(_path)
		global_position = global_position.lerp(_next_point, delta * _speed)
		if (_next_point - global_position).length_squared() <= 750.0:
			_is_traveling = false
			_current_point = _next_point
			_next_point = Vector2.ZERO
			if _path.size() == 0:
				_path_line.clear_points()
				global_position = _current_point


func draw_path(path: Array) -> void:
	if not _path_line:
		return
	
	_path_line.clear_points()
	if _is_traveling:
		_path_line.add_point(global_position)
		_path_line.add_point(_next_point)
	for point in path:
		_path_line.add_point(map.get_tile_position_from_coords(point))


func hide_path() -> void:
	if _path_line:
		_path_line.clear_points()


func calculate_path(target: Vector2i, target_floor := -1) -> Array[Vector2i]:
	var start: Vector2i = map.get_tile_coords(global_position)
	if target_floor < 0:
		target_floor = map.active_floor

	var target_id := Vector3i(target.x, target.y, target_floor)

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
		var lowest_f := 60.0
		var current: PathNode
		for node in open.values():
			if node.f < lowest_f:
				lowest_f = node.f
				current = node
		open.erase(current.pos_id)
		closed[current.pos_id] = current
		
		if current.position == target and current.map_floor == target_floor:
			var path: Array[Vector2i] = []
			var path_point: PathNode = current
			while path_point:
				# TODO: This will be broken when moving between floors.
				path.append(path_point.position)
				if path_point.has_parent:
					path_point = closed[path_point.parent_id]
				else:
					path_point = null
			path.reverse()
			return path
		
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
	
	return [ first_node.position ]


func _on_target_updated(new_target: Vector2i) -> void:
	_target_queue.push_front(new_target)


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