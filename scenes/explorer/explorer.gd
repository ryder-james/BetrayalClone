class_name Explorer
extends Node2D

@export var map: Map

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


func calculate_path(target: Vector2i, target_floor := -1) -> Array:
	var start: Vector2i = map.get_tile_coords(global_position)
	var start_id := Vector3i(start.x, start.y, map.active_floor)
	if target_floor < 0:
		target_floor = map.active_floor

	var target_id := Vector3i(target.x, target.y, target_floor)

	var open = {}
	var closed = {}
	var all_nodes = {}
	
	# Add the starting square (or node) to the open list
	open[start_id] = {
		id = start_id, # id - Vector3i(position.x, position.y, floor)
		position = start, # Vector2i
		floor = map.active_floor, # int
		doors = map.get_tile(start).doors, # Direction
		parent = Vector3i.ZERO, # id - Vector3i(parent.position.x, parent.position.y, parent.floor)
		has_parent = false, # bool
		children = [], # Array[id - Vector3i(child.position.x, child.position.y, child.floor)]
		weight = 0, # int
		heuristic = (target_id - start_id).length_squared(), # Distance from end
		f = 0, # Sum of weight and heuristic
	}

	all_nodes[start_id] = open[start_id]
	
	while open.keys().size() > 0:
		# Arbitrarily high number
		var lowest_f := 60.0
		var current: Dictionary
		for node in open.values():
			if node.f < lowest_f:
				lowest_f = node.f
				current = node
		open.erase(current.id)
		closed[current.id] = current
		
		if current.position == target and current.floor == target_floor:
			var path = []
			var path_point: Dictionary = current
			while path_point:
				# TODO: This will be broken when moving between floors.
				path.append(path_point.position)
				if path_point.has_parent:
					path_point = closed[path_point.parent]
				else:
					path_point = {}
			path.reverse()
			return path
		
		var neighbors = map.get_neighbors(current.position, current.floor)
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
			var child = {
				id = Vector3i(neighbor_position.x, neighbor_position.y, current.floor),
				position = neighbor_position,
				floor = current.floor,
				doors = doors,
				parent = current.id,
				has_parent = true,
				children = [],
			}
			
			all_nodes[child.id] = child
			current.children.append(child.id)
		
		var special_connections = []#map.get_special_connections(current.position)
		for special_connection in special_connections:
			pass
		
		for child_id in current.children:
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
	
	return [start]


func _on_target_updated(new_target: Vector2i) -> void:
	_target_queue.push_front(new_target)
