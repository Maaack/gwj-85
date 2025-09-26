extends Node2D

signal object_spawned(object_instance)

@export var spawn_scene : PackedScene
@export var spawn_range : float = 100.0
@export var resource_per_spawn : int = 8
@export var min_resources : int = 9

var current_resources := 0

func _spawn_instance() -> Node2D:
	var spawn_instance = spawn_scene.instantiate()
	var random_angle := randf_range(-PI, PI)
	var random_distance := randf() * spawn_range
	spawn_instance.position = Vector2.from_angle(random_angle) * random_distance + position
	spawn_instance.spawner = self
	current_resources += resource_per_spawn
	object_spawned.emit(spawn_instance)
	GameEvents.object_spawned.emit(spawn_instance)
	return spawn_instance

func _check_resources() -> void:
	while current_resources < min_resources:
		_spawn_instance()

func _on_resource_collected(spawner) -> void:
	if spawner != self : return
	current_resources -= 1
	_check_resources()

func _ready():
	GameEvents.resource_collected.connect(_on_resource_collected)
	_check_resources.call_deferred()
