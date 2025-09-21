class_name PlayerCharacter2D
extends CharacterBody2D

signal heatlh_changed(current_health : float, max_health: float)
signal ammo_ratio_changed(new_ratio: float)
signal boost_ratio_changed(new_ratio: float)
signal resource_ratio_changed(new_ratio: float)
signal died

@onready var health_component = %HealthComponent
@onready var ammo_storage_component = %AmmoStorageComponent
@onready var boost_storage_component = %BoostStorageComponent
@onready var resource_storage_component = %ResourceStorageComponent
@onready var ammo_up_stream_player = %AmmoUpStreamPlayer
@onready var health_up_stream_player = %HealthUpStreamPlayer
@onready var fuel_up_stream_player = %FuelUpStreamPlayer
@onready var resource_up_stream_player = %ResourceUpStreamPlayer
@onready var resource_give_stream_player = %ResourceGiveStreamPlayer
@onready var damage_stream_player = %DamageStreamPlayer

func remove_all_resources() -> int:
	var return_value : int = round(resource_storage_component.amount)
	resource_storage_component.amount = 0
	if return_value > 0:
		resource_give_stream_player.play()
	return return_value

func add_resource(amount : int = 1) -> void:
	if resource_storage_component.is_full(): return
	resource_storage_component.add(amount)
	resource_up_stream_player.play()

func damage(amount : float) -> void:
	health_component.damage(amount)
	damage_stream_player.play()

func heal(amount : float) -> void:
	if health_component.is_full(): return
	health_component.heal(amount)
	health_up_stream_player.play()

func add_ammo(amount : float) -> void:
	if ammo_storage_component.is_full(): return
	ammo_storage_component.add(amount)
	ammo_up_stream_player.play()

func add_fuel(amount : float) -> void:
	if boost_storage_component.is_full(): return
	boost_storage_component.add(amount)
	fuel_up_stream_player.play()

func _ready() -> void:
	for child in get_children():
		if child is ComponentBase:
			child.initialize()

func _on_health_component_health_changed(_new_value) -> void:
	heatlh_changed.emit(health_component.health, health_component.max_health)

func _on_health_component_max_health_changed(_new_value) -> void:
	heatlh_changed.emit(health_component.health, health_component.max_health)

func _on_health_component_died():
	GameEvents.player_died.emit()
	died.emit()

func _on_ammo_storage_component_storage_ratio_changed(new_value):
	ammo_ratio_changed.emit(new_value)

func _on_boost_storage_component_storage_ratio_changed(new_value):
	boost_ratio_changed.emit(new_value)

func _on_resource_storage_component_storage_ratio_changed(new_value):
	resource_ratio_changed.emit(new_value)
