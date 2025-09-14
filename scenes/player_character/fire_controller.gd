extends Node

@export_node_path("CharacterBody2D") var character_body_node_path : NodePath = ^".."
@export var bullet_scene : PackedScene
@export var spawn_offset : Vector2 = Vector2.ZERO
@export var spawn_speed : float = 25.0
@export var cooldown_delay : float = 0.2
@export var fire_action : StringName = &"shoot"

var facing_vector : Vector2
var in_cooldown : bool = false

@onready var character_body : CharacterBody2D = get_node(character_body_node_path)

func _process(_delta) -> void:
	if not Input.is_action_pressed(fire_action): return
	if in_cooldown : return
	var bullet_instance : Node2D = bullet_scene.instantiate()
	bullet_instance.global_position = character_body.global_position + spawn_offset.rotated(character_body.rotation)
	bullet_instance.rotation = character_body.rotation
	bullet_instance.velocity = spawn_speed * Vector2.from_angle(character_body.rotation)
	GameEvents.object_spawned.emit(bullet_instance)
	in_cooldown = true
	await get_tree().create_timer(cooldown_delay, false).timeout
	in_cooldown = false
	
