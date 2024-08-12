extends Node2D

@export var map: Map

var _speed := 3.5
var _path = []
var _next_point: Vector2
var _current_point: Vector2

func _ready() -> void:
	Event.on_target_updated.connect(_on_target_updated)


func _process(delta: float) -> void:
	if not _next_point and _path.size() > 0:
		_next_point = map.get_tile_position_from_coords(_path.pop_front())
	
	if _next_point:
		global_position = global_position.lerp(_next_point, delta * _speed)
	
	if (_next_point - global_position).length_squared() <= 750.0:
		_current_point = _next_point
		_next_point = Vector2.ZERO
		if _path.size() == 0:
			print("done")
	


func _on_target_updated(new_target: Vector2i) -> void:
	var start: Vector2i = map.get_tile_coords(global_position)
	
	var open = {}
	var closed = {}
	
	# Add the starting square (or node) to the open list
	open[start] = {
		position = start,
		doors = map.get_tile_info(start).doors,
		parent = DrawPile.NO_TILE,
		has_parent = false,
		children = [],
		g = 0,
		h = (new_target - start).length_squared(),
		f = 0,
	}
	
	while open.keys().size() > 0:
		# Arbitrarily high number
		var lowest_f := 60.0
		var current: Dictionary
		for node in open.values():
			if node.f < lowest_f:
				current = node
		open.erase(current.position)
		closed[current.position] = current
		
		if current.position == new_target:
			_path = []
			var path_point: Dictionary = current
			while path_point:
				_path.append(path_point.position)
				if path_point.has_parent:
					path_point = closed[path_point.parent]
				else:
					path_point = {}
			_path.reverse()
			return
		
		var neighbors = map.get_neighbors(current.position, false)
		for direction in neighbors:
			var neighbor_position = neighbors[direction].tile_position			
			if neighbor_position == current.position:
				continue
			
			# If we don't point at them, move on
			if current.doors & direction != direction:
				continue
			
			# If they don't point at us, move on
			var opp = Direction.opposite(direction)
			if neighbors[direction].doors & opp != opp:
				continue

			var child = {
				position = neighbor_position,
				doors = neighbors[direction].doors,
				parent = current.position,
				has_parent = true,
				children = [],
			}
			
			current.children.append(child)
		
		for child in current.children:
			if closed.has(child.position):
				continue
			
			# TODO: Sub 1 for node weight (enemy team or w/e)
			child.g = current.g + 1
			child.h = (new_target - child.position).length_squared()
			child.f = child.g + child.h
			
			for node_pos in open:
				if child.position == node_pos and child.g > open[node_pos].g:
					continue
			
			open[child.position] = child
	
	
