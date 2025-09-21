extends Node

@export var station_starting_size : int = 128

@onready var health_bar = %HealthBar
@onready var ammo_progress_bar = %AmmoProgressBar
@onready var boost_progress_bar = %BoostProgressBar
@onready var resource_progress_bar = %ResourceProgressBar
@onready var station_resource_label = %StationResourceLabel
@onready var station_size_label = %StationSizeLabel

var player_station : SpaceStation2D
var enemy_stations : Array[SpaceStation2D]

func _on_object_spawned(node_2d : Node2D) -> void:
	add_child.call_deferred(node_2d)

func _on_enemy_station_destroyed(station : SpaceStation2D) -> void:
	enemy_stations.erase(station)
	if enemy_stations.is_empty():
		GameEvents.enemy_stations_destroyed.emit()

func _ready() -> void:
	GameEvents.object_spawned.connect(_on_object_spawned)
	for child in get_children():
		if child is SpaceStation2D:
			child.resources += station_starting_size
			child.expand_station(station_starting_size)
			child.size_limit = 0
			var new_label = station_size_label.duplicate()
			new_label.show()
			new_label.modulate = child.modulate
			new_label.text = "%d" % (station_starting_size + 7)
			child.size_changed.connect(func(new_size: int) : new_label.text = "%d" % new_size)
			station_size_label.add_sibling.call_deferred(new_label)
			if player_station == null:
				player_station = child
				child.destroyed.connect(func() : GameEvents.player_station_destroyed.emit())
				child.resources_changed.connect(func(_delta : float) : station_resource_label.text = "%d" % child.resources)
				continue
			child.enemy = true
			enemy_stations.append(child)
			child.destroyed.connect(_on_enemy_station_destroyed.bind(child))
	ammo_progress_bar.value = 1.0
	boost_progress_bar.value = 1.0


func _on_player_heatlh_changed(current_health, max_health):
	if health_bar:
		health_bar.value = current_health / max_health

func _on_give_enemies_resource_timer_timeout():
	for station in enemy_stations:
		station.resources += 1

func _on_player_ammo_ratio_changed(new_ratio):
	if ammo_progress_bar:
		ammo_progress_bar.value = new_ratio

func _on_player_boost_ratio_changed(new_ratio):
	if boost_progress_bar:
		boost_progress_bar.value = new_ratio

func _on_player_resource_ratio_changed(new_ratio):
	if resource_progress_bar:
		resource_progress_bar.value = new_ratio
