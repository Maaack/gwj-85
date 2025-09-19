extends Node

@onready var resources = %Resources
@onready var health_bar = %HealthBar

func _on_object_spawned(node_2d : Node2D) -> void:
	add_child.call_deferred(node_2d)

func _ready() -> void:
	GameEvents.object_spawned.connect(_on_object_spawned)

func _on_player_heatlh_changed(current_health, max_health):
	if health_bar:
		health_bar.value = current_health / max_health

func _on_player_resources_updated(count):
	resources.text = "%d" % count
