class_name Bullet2D
extends CharacterBody2D

@export var bullet_damage := 10

func _physics_process(_delta) -> void:
	if move_and_slide():
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider.has_method(&"damage"):
				if collider is TileMapLayer:
					collider.damage(bullet_damage, collision.get_position())
				else:
					collider.damage(bullet_damage)
		queue_free()

func damage(_amount : float) -> void:
	queue_free()

func _on_decay_timer_timeout():
	queue_free()
