extends Node2D

enum TileAction {
	NONE,
	DISCOVER,
	WRONG_FLOOR,
	MOVE_TO,
}

enum TileMode {
	SELECT,
	DISCOVER
}

@export var draw_pile: DrawPile
@export var map: Map
@export var explorer: Explorer
@export_group("Highlighter Colors")
@export var no_action_color: Color = Color.TRANSPARENT
@export var move_to_color: Color = Color(0xffffff96)
@export var discover_color: Color = Color(0x00ff0096)
@export var illegal_placement_color: Color = Color(0xff000096)

var current_floor := Map.GROUND
var can_place := false
var prev_tile_coords: Vector2i
var active_tile_coords: Vector2i
var active_tile_id: Vector2i
var legal_rotations = []
var placement_rotations := 0
var tile_mode := TileMode.SELECT

@onready var preview: Node2D = $Preview
@onready var highlighter: ColorRect = %Highlighter
@onready var tile_preview: Sprite2D = %TilePreview


func _ready() -> void:
	active_tile_coords = map.get_tile_coords(get_global_mouse_position())
	_update_highlighter()


func _unhandled_input(event: InputEvent) -> void:
	match tile_mode:
		TileMode.SELECT:
			_process_input_select(event)
		TileMode.DISCOVER:
			_process_input_discover(event)


func _process_input_select(event: InputEvent) -> void:
	if event.is_action_pressed("primary"):
		_update_highlighter()
		if can_place:
			var action = _get_tile_action(draw_pile.peek(), active_tile_coords)
			while action != TileAction.DISCOVER:
				draw_pile.discard()
				action = _get_tile_action(draw_pile.peek(), active_tile_coords)
			_switch_mode(TileMode.DISCOVER)
		elif active_tile_id != DrawPile.NO_TILE:
			Event.on_target_updated.emit(active_tile_coords)
	elif event is InputEventMouseMotion:
		prev_tile_coords = active_tile_coords
		active_tile_coords = map.get_tile_coords(get_global_mouse_position())
		var active_tile = map.get_tile(active_tile_coords)
		if active_tile:
			active_tile_id = active_tile.id
		else:
			active_tile_id = DrawPile.NO_TILE
		_update_highlighter()


func _process_input_discover(event: InputEvent) -> void:
	if event.is_action_pressed("primary"):
		if can_place:
			_place_tile()
			_switch_mode(TileMode.SELECT)
	elif event.is_action_pressed("secondary") and legal_rotations.size() > 1:
		var cur_rot_index = legal_rotations.find(placement_rotations)
		var index = (cur_rot_index + 1) % legal_rotations.size()
		placement_rotations = legal_rotations[index]
		_update_discover_visual()

func _switch_mode(new_mode: TileMode) -> void:
	tile_mode = new_mode
	match tile_mode:
		TileMode.SELECT:
			active_tile_coords = map.get_tile_coords(get_global_mouse_position())

			highlighter.visible = true
			tile_preview.visible = false
			
			_update_highlighter()
		TileMode.DISCOVER:
			active_tile_id = draw_pile.draw()
			tile_preview.visible = true
			tile_preview.texture = TileManager.get_tile_texture(active_tile_id)
			
			var path = explorer.calculate_path(active_tile_coords)
			var entering_direction = Direction.get_direction(path[-2], active_tile_coords)

			legal_rotations = map.get_legal_rotations(active_tile_coords, active_tile_id, entering_direction)
			placement_rotations = legal_rotations[0]
			
			Event.on_target_updated.emit(explorer.calculate_path(active_tile_coords)[-2])
			
			_update_discover_visual()

			if legal_rotations.size() == 1:
				_place_tile()
				_switch_mode(TileMode.SELECT)


func _place_tile() -> void:
	map.place_tile(active_tile_coords, active_tile_id, placement_rotations)
	if draw_pile.is_empty():
		draw_pile.refill()


func _update_highlighter() -> void:
	var tile_pos = map.get_tile_position_from_coords(active_tile_coords)
	preview.global_position = tile_pos
	
	can_place = false
	
	var tile_action = _get_tile_action(draw_pile.peek(), active_tile_coords)
	match tile_action:
		TileAction.NONE:
			highlighter.color = no_action_color
			explorer.hide_path()
		TileAction.MOVE_TO:
			highlighter.color = move_to_color
			if prev_tile_coords != active_tile_coords:
				var path = explorer.calculate_path(active_tile_coords)
				explorer.draw_path(path)
		TileAction.WRONG_FLOOR:
			highlighter.color = discover_color
			if prev_tile_coords != active_tile_coords:
				var path = explorer.calculate_path(active_tile_coords)
				explorer.draw_path(path)
			can_place = true
		TileAction.DISCOVER:
			highlighter.color = discover_color
			if prev_tile_coords != active_tile_coords:
				var path = explorer.calculate_path(active_tile_coords)
				explorer.draw_path(path)
			can_place = true


func _update_discover_visual() -> void:
		can_place = false
		highlighter.visible = false
		tile_preview.global_rotation_degrees = 90 * placement_rotations
		
		var legality = map.get_door_legality(active_tile_coords, active_tile_id, placement_rotations)
		if legality == Map.DoorLegality.WRONG_ROTATION:
			highlighter.visible = true
			highlighter.color = illegal_placement_color
		else:
			can_place = true


func _get_tile_action(desired_tile_id: Vector2i, desired_position: Vector2i) -> TileAction:
	var neighbors = map.get_neighbors(desired_position)
	
	if neighbors[Direction.NONE]:
		return TileAction.MOVE_TO
	
	if desired_tile_id == DrawPile.NO_TILE:
		return TileAction.NONE
	
	var door_legality = map.get_door_legality(desired_position, desired_tile_id)
	
	if door_legality == Map.DoorLegality.ILLEGAL:
		return TileAction.NONE
	
	var tile_info = TileManager.get_tile_info(desired_tile_id)
	
	if tile_info.floors & map.active_floor != map.active_floor:
		return TileAction.WRONG_FLOOR
	
	return TileAction.DISCOVER
