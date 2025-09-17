extends Area2D

func _on_body_entered(body):
	if body.has_method("add_resource"):
		if body.add_resource(1):
			queue_free()
