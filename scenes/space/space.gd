extends Node

@export var station_starting_size : int = 128

@onready var resources = %Resources
@onready var health_bar = %HealthBar

var player_station : SpaceStation2D
var enemy_stations : Array[SpaceStation2D]

var enemy_stations_destroyed : int = 0

func _on_object_spawned(node_2d : Node2D) -> void:
	add_child.call_deferred(node_2d)

func _on_enemy_station_destroyed() -> void:
	enemy_stations_destroyed += 1
	if enemy_stations_destroyed >= enemy_stations.size():
		GameEvents.enemy_stations_destroyed.emit()

func _ready() -> void:
	GameEvents.object_spawned.connect(_on_object_spawned)
	for child in get_children():
		if child is SpaceStation2D:
			child.resources += station_starting_size
			child.expand_station(station_starting_size)
			if player_station == null:
				player_station = child
				child.destroyed.connect(func() : GameEvents.player_station_destroyed.emit())
				continue
			child.enemy = true
			enemy_stations.append(child)
			child.destroyed.connect(_on_enemy_station_destroyed)

func _on_player_heatlh_changed(current_health, max_health):
	if health_bar:
		health_bar.value = current_health / max_health

func _on_player_resources_updated(count):
	resources.text = "%d" % count

func _on_give_enemies_resource_timer_timeout():
	for station in enemy_stations:
		station.resources += 2
