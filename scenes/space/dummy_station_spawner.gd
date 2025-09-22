extends Node2D

signal object_spawned(object_instance)

@export var spawn_scene : PackedScene
@export var spawn_range : float = 100.0
@export var spawn_delay : float = 4.0
@export var auto_spawn : bool = false
@export var spawn_colors : Array[Color] = [Color.CYAN, Color.DARK_VIOLET, Color.YELLOW, Color.GREEN, Color.BLUE, Color.RED, Color.ORANGE, Color.PURPLE]

func _spawn_instance() -> Node2D:
	var spawn_instance = spawn_scene.instantiate()
	var random_angle := randf_range(-PI, PI)
	var random_distance := randf() * spawn_range
	spawn_instance.position = Vector2.from_angle(random_angle) * random_distance + position
	spawn_instance.rotation = randf_range(-PI/4, PI/4)
	if spawn_colors.size() > 0:
		spawn_instance.modulate = spawn_colors.pick_random()
	object_spawned.emit(spawn_instance)
	add_sibling.call_deferred(spawn_instance)
	return spawn_instance

func start_spawning():
	while(true):
		await get_tree().create_timer(spawn_delay, false).timeout
		_spawn_instance()

func _ready():
	if auto_spawn:
		start_spawning()
