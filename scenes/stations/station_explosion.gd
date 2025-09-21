extends Area2D

@export var deal_damage : float = 1.0

func _on_animation_player_animation_finished(_anim_name):
	queue_free()

func _on_body_entered(body):
	if body is PlayerCharacter2D:
		body.damage(deal_damage)
