extends CharacterBody2D

func _physics_process(delta) -> void:
	move_and_slide()

func damage(_amount : float) -> void:
	queue_free()
