extends Node
# Autoload as Direction

const NONE := 0

const UP := 1
const RIGHT := 2
const DOWN := 4
const LEFT := 8

const ALL = UP | RIGHT | DOWN | LEFT


func rotate_c(direction: int) -> int:
	var new_dir = direction << 1
	while new_dir > ALL:
		new_dir -= ALL
	return new_dir


func rotate_cc(direction: int) -> int:
	var new_dir = direction >> 1
	if direction & 1 == 1:
		new_dir += (1 << 3)
	return new_dir


func opposite(direction: int) -> int:
	return rotate_c(rotate_c(direction))


func right(direction: int) -> int:
	return rotate_c(direction)


func left(direction: int) -> int:
	return rotate_cc(direction)


func as_vector(direction: int) -> Vector2i:
	var dir_vector = Vector2i.ZERO
	if direction & UP == UP:
		dir_vector += Vector2i.UP
	if direction & DOWN == DOWN:
		dir_vector += Vector2i.DOWN
	if direction & RIGHT == RIGHT:
		dir_vector += Vector2i.RIGHT
	if direction & LEFT == LEFT:
		dir_vector += Vector2i.LEFT
	return dir_vector


func get_direction(from: Vector2i, to: Vector2i) -> int:
	var direction = NONE

	if from.x < to.x:
		direction |= LEFT
	elif from.x > to.x:
		direction |= RIGHT
	
	if from.y < to.y:
		direction |= UP
	elif from.y > to.y:
		direction |= DOWN
	
	return direction
