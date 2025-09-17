extends CharacterBody2D

@export var resources : int = 0

@onready var health_component = %HealthComponent

func add_resource(amount : int = 1) -> void:
	resources += amount

func damage(amount : float) -> void:
	health_component.damage(amount)

func _ready():
	for child in get_children():
		if child is ComponentBase:
			child.initialize()
