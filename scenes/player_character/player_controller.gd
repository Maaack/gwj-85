class_name PlayerController
extends Node

@export_node_path("CharacterBody2D") var character_body_node_path : NodePath = ^".."
@export var boost_storage : UnitStorageComponent
@export var animation_player : AnimationPlayer
@export var move_speed : float = 10.0
@export var always_moving : bool = false
@export var move_up_action : StringName = &"move_up"
@export var move_down_action : StringName = &"move_down"
@export var move_left_action : StringName = &"move_left"
@export var move_right_action : StringName = &"move_right"
@export var boost_action : StringName = &"boost"
@export var boost_mod : float = 2.0

@export var collision_damage : float = 5
@export var collision_lock_delay : float = 0.25

var colliding_vector : Vector2
var facing_vector : Vector2 = Vector2.UP
var control_locked : bool = false

@onready var character_body : CharacterBody2D = get_node(character_body_node_path)

func get_direction(from_vector : Vector2) -> StringName:
	var direction : StringName = &"N"
	if from_vector.x > 0:
		direction = &"E"
		if from_vector.y > 0:
			direction = &"SE"
		elif from_vector.y < 0:
			direction = &"NE"
	elif from_vector.x < 0:
		direction = &"W"
		if from_vector.y > 0:
			direction = &"SW"
		elif from_vector.y < 0:
			direction = &"NW"
	else:
		if from_vector.y > 0:
			direction = &"S"
	return direction
		

func _process(delta) -> void:
	var new_facing_vector : Vector2
	var current_boost_mod : float = 1.0
	if not control_locked:
		new_facing_vector = Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action)
	else:
		new_facing_vector = -colliding_vector
	if not new_facing_vector.is_zero_approx():
		facing_vector = new_facing_vector
		if animation_player:
			animation_player.play(get_direction(facing_vector))
	if (not new_facing_vector.is_zero_approx()) or always_moving:
		if Input.is_action_pressed(boost_action):
			if boost_storage.amount > 0.0:
				current_boost_mod = boost_mod
				boost_storage.subtract(delta)
		character_body.velocity = move_speed * facing_vector * current_boost_mod
	if character_body.move_and_slide():
		if control_locked: return
		character_body.damage(collision_damage)
		colliding_vector = facing_vector
		control_locked = true
		await get_tree().create_timer(collision_lock_delay).timeout
		control_locked = false
		
