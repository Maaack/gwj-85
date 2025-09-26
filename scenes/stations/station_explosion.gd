extends Area2D

@export var deal_damage : float = 1.0
@export var damage_delay : float = 0.5

var damage_objects: Array[Node2D]

func _on_animation_player_animation_finished(_anim_name):
	queue_free()

func _on_body_entered(body):
	if body is PlayerCharacter2D or body is Asteroid2D:
		damage_objects.append(body)
		while body in damage_objects:
			body.damage(deal_damage)
			await get_tree().create_timer(damage_delay, false).timeout

func _on_body_exited(body):
	if body is PlayerCharacter2D or body is Asteroid2D:
		damage_objects.erase(body)
