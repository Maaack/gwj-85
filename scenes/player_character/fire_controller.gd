extends Node

@export_node_path("CharacterBody2D") var character_body_node_path : NodePath = ^".."
@export var player_controller : PlayerController
@export var ammo_storage : UnitStorageComponent
@export var fire_sound_player : AudioStreamPlayer
@export var no_ammo_sound_player : AudioStreamPlayer
@export var bullet_scene : PackedScene
@export var spawn_offset : Vector2 = Vector2.ZERO
@export var spawn_speed : float = 25.0
@export var cooldown_delay : float = 0.2
@export var fire_action : StringName = &"shoot"

var in_cooldown : bool = false

@onready var character_body : CharacterBody2D = get_node(character_body_node_path)

func _no_ammo() -> void:
	if no_ammo_sound_player:
		if not no_ammo_sound_player.playing:
			no_ammo_sound_player.play()

func _process(_delta) -> void:
	if not Input.is_action_pressed(fire_action): return
	if in_cooldown : return
	if ammo_storage.amount <= 0:
		_no_ammo()
		return
	if player_controller.facing_vector == Vector2.ZERO: return
	var bullet_instance : Node2D = bullet_scene.instantiate()
	bullet_instance.global_position = character_body.global_position + spawn_offset.rotated(player_controller.facing_vector.angle())
	bullet_instance.velocity = spawn_speed * player_controller.facing_vector
	ammo_storage.subtract(1)
	if fire_sound_player:
		fire_sound_player.play()
	GameEvents.object_spawned.emit(bullet_instance)
	in_cooldown = true
	await get_tree().create_timer(cooldown_delay, false).timeout
	in_cooldown = false
	
