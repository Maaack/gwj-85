extends StaticBody2D

signal resources_changed(delta, reason)
signal state_changed(resources, damage)
signal destroyed(reason)

const NO_TILE = -1
const CARDINAL_DIRECTIONS : Array = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]

@export var resources : int = 6
@export var health : int = 10
