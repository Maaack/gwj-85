extends Node

@export_node_path("CharacterBody2D") var character_body_node_path : NodePath = ^".."
@export var move_speed : float = 10.0
@export var always_moving : bool = false
@export var move_up_action : StringName = &"move_up"
@export var move_down_action : StringName = &"move_down"
@export var move_left_action : StringName = &"move_left"
@export var move_right_action : StringName = &"move_right"

@export var collision_lock_delay : float = 0.25

var colliding_vector : Vector2
var facing_vector : Vector2
var control_locked : bool = false

@onready var character_body : CharacterBody2D = get_node(character_body_node_path)

func _process(_delta) -> void:
	var new_facing_vector : Vector2
	if not control_locked:
		new_facing_vector = Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action)
	else:
		new_facing_vector = -colliding_vector
	if not new_facing_vector.is_zero_approx():
		facing_vector = new_facing_vector
		character_body.look_at(facing_vector + character_body.global_position)
	if (not new_facing_vector.is_zero_approx()) or always_moving:
		character_body.velocity = move_speed * facing_vector
	if character_body.move_and_slide():
		if control_locked: return
		character_body.damage(1)
		colliding_vector = facing_vector
		control_locked = true
		await get_tree().create_timer(collision_lock_delay).timeout
		control_locked = false
		
