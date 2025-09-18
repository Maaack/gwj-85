extends CharacterBody2D

signal resources_updated(count : int)

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

func _ready():
	for child in get_children():
		if child is ComponentBase:
			child.initialize()
