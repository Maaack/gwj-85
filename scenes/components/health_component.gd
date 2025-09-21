class_name HealthComponent
extends ComponentBase

signal health_changed(new_value : float)
signal max_health_changed(new_value : float)
signal died

@export_range(0, 1000, 1, "or_greater") var starting_health : float = 100
@export_range(0, 1000, 1, "or_greater") var max_health : float = 100 :
	set(value):
		max_health = value
		max_health_changed.emit(max_health)
@export var enabled : bool = true
var dead : bool = false

var health : float :
	set(value):
		if not enabled:
			return
		health = value
		if health < 0:
			health = 0
		if health > max_health:
			health = max_health
		health_changed.emit(health)
		if not dead and health == 0:
			_die()

func is_full() -> bool:
	return health >= max_health

func _die():
	if dead:
		return
	dead = true
	emit_signal("died")

func heal(amount : float):
	if amount < 0:
		push_warning("cannot heal a negative amount")
	health += amount

func damage(amount : float):
	if amount < 0:
		push_warning("cannot damage a negative amount")
	health -= amount

func initialize():
	health = starting_health
	max_health = max_health
