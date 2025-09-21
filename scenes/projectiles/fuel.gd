class_name Fuel2D
extends CharacterBody2D

@export var fuel := 4.0

var destroyed : bool = false

func destroy() -> void:
	if destroyed: return
	destroyed = true
	queue_free()

func _physics_process(_delta) -> void:
	if destroyed: return
	var _velocity = velocity
	if move_and_slide():
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider.has_method(&"add_fuel"):
				collider.add_fuel(fuel)
				break
		destroy()

func damage(_amount : float) -> void:
	destroy()

func _on_decay_timer_timeout():
	destroy()
