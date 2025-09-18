class_name Asteroid2D
extends RigidBody2D


@export var game_mass : int = 4
@export var pieces : int = 2
@export var spawn_speed : float = 25.0
@export var collider_radius : float = 22.0
@export var resource_scene : PackedScene

@onready var sprite_2d = %Sprite2D
@onready var collision_shape_2d = %CollisionShape2D

func damage(_amount : int = 1):
	if game_mass > 1:
		for piece_iter in range(pieces):
			var asteroid_instance := self.duplicate()
			var direction = randf_range(-PI, PI)
			asteroid_instance.game_mass -= 1
			asteroid_instance.rotation = randf_range(-PI, PI)
			asteroid_instance.global_position = global_position + (Vector2.from_angle(direction) * 4)
			asteroid_instance.linear_velocity = spawn_speed * Vector2.from_angle(direction)
			GameEvents.object_spawned.emit(asteroid_instance)
	else:
		var resource_instance : Node2D = resource_scene.instantiate()
		resource_instance.global_position = global_position
		GameEvents.object_spawned.emit(resource_instance)
	queue_free()

func _on_body_entered(body: Node2D):
	if body is Asteroid2D or body is Bullet2D: return
	if body.has_method("damage"):
		body.damage(pow(2, game_mass))
	damage(1)

func _ready():
	var _scale_ratio = pow(2, game_mass) / 16.0
	sprite_2d.scale = Vector2(_scale_ratio, _scale_ratio)
	collision_shape_2d.shape.radius = collider_radius * _scale_ratio
