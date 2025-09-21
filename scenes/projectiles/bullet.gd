class_name Bullet2D
extends CharacterBody2D

@export var bullet_damage := 10

var destroyed : bool = false

func destroy() -> void:
	if destroyed: return
	destroyed = true
	queue_free()

func _physics_process(delta) -> void:
	if destroyed: return
	var _velocity = velocity
	if move_and_slide():
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider.has_method(&"damage"):
				if collider is TileMapLayer:
					collider.damage(bullet_damage, collision.get_position() + _velocity * delta)
				else:
					collider.damage(bullet_damage)
				break
		destroy()

func damage(_amount : float) -> void:
	destroy()

func _on_decay_timer_timeout():
	destroy()
