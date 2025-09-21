@tool
extends StaticBody2D

@export var area_base : float = 100 :
	set(value):
		area_base = value
		if is_inside_tree():
			_refresh_borders()

@export var area_mod : float = 1.0 :
	set(value):
		area_mod = value
		if is_inside_tree():
			_refresh_borders()

var border_shape : Shape2D

@onready var north_border : CollisionShape2D = %NorthBorder
@onready var east_border : CollisionShape2D = %EastBorder
@onready var south_border : CollisionShape2D = %SouthBorder
@onready var west_border : CollisionShape2D = %WestBorder
@onready var line_2d : Line2D = %Line2D

func _get_area() -> float:
	return area_base * area_mod

func _refresh_borders() -> void:
	border_shape.size.x = _get_area()
	north_border.position.y = -(_get_area() / 2)
	east_border.position.x = (_get_area() / 2)
	south_border.position.y = (_get_area() / 2)
	west_border.position.x = -(_get_area() / 2)
	var new_points : PackedVector2Array = [
		(Vector2.LEFT + Vector2.UP) * _get_area() / 2,
		(Vector2.RIGHT + Vector2.UP) * _get_area() / 2,
		(Vector2.RIGHT + Vector2.DOWN) * _get_area() / 2,
		(Vector2.LEFT + Vector2.DOWN) * _get_area() / 2,
	]
	line_2d.points = new_points

func _ready() -> void:
	border_shape = north_border.shape
	_refresh_borders()
