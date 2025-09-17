extends Area2D

func _on_body_entered(body):
	if body.has_method("add_resource"):
		body.add_resource()
		queue_free()
