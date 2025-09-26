extends Area2D

@export var resource_amount : int = 1

var spawner : Node2D

func _on_body_entered(body):
	if body.has_method("add_resource"):
		body.add_resource(resource_amount)
		GameEvents.resource_collected.emit(spawner)
		queue_free()
