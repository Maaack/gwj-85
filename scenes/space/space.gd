extends Node

func _on_object_spawned(node_2d : Node2D) -> void:
	add_child.call_deferred(node_2d)

func _ready() -> void:
	GameEvents.object_spawned.connect(_on_object_spawned)
