extends Node

@export_node_path("CharacterBody2D") var character_body_node_path : NodePath = ^".."
@export var move_speed : float = 10.0
@export var always_moving : bool = false

var facing_vector : Vector2

@onready var character_body : CharacterBody2D = get_node(character_body_node_path)

func _process(_delta) -> void:
	var new_facing_vector = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if not new_facing_vector.is_zero_approx():
		facing_vector = new_facing_vector
		character_body.look_at(facing_vector + character_body.global_position)
	if (not new_facing_vector.is_zero_approx()) or always_moving:
		character_body.velocity = move_speed * facing_vector
	character_body.move_and_slide()
