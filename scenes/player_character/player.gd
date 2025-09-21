extends CharacterBody2D

signal resources_updated(count : int)
signal heatlh_changed(current_health : float, max_health: float)
signal died

@export var resources : int = 0

@onready var health_component = %HealthComponent

func remove_all_resources() -> int:
	var return_value := resources
	resources = 0
	resources_updated.emit(resources)
	return return_value

func add_resource(amount : int = 1) -> bool:
	resources += amount
	resources_updated.emit(resources)
	return true

func damage(amount : float) -> void:
	health_component.damage(amount)

func heal(amount : float) -> void:
	health_component.heal(amount)

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
