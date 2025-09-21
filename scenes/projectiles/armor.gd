class_name Armor2D
extends CharacterBody2D

@export var health := 4

func _physics_process(delta) -> void:
	var _velocity = velocity
	if move_and_slide():
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider.has_method(&"heal"):
				collider.heal(health)
		queue_free()

func damage(_amount : float) -> void:
	queue_free()

func _on_decay_timer_timeout():
	queue_free()
