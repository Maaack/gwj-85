class_name UnitStorageComponent
extends ComponentBase

signal amount_changed(new_value : float)
signal max_amount_changed(new_value : float)
signal storage_ratio_changed(new_value : float)

@export_range(0, 1000, 1, "or_greater") var amount : float :
	set(value):
		if not enabled: return
		amount = value
		if amount < 0:
			amount = 0
		if amount > max_amount:
			amount = max_amount
		amount_changed.emit(amount)
		storage_ratio_changed.emit(amount / max_amount)
@export_range(0, 1000, 1, "or_greater") var max_amount : float = 100 :
	set(value):
		if not enabled: return
		max_amount = value
		max_amount_changed.emit(max_amount)
		storage_ratio_changed.emit(amount / max_amount)
@export var enabled : bool = true

func get_capacity():
	return max_amount - amount

func is_full() -> bool:
	return amount >= max_amount

func add(delta : float):
	if delta < 0:
		push_warning("cannot add a negative amount")
	amount += delta

func subtract(delta : float):
	if delta < 0:
		push_warning("cannot subtract a negative amount")
	amount -= delta

func initialize():
	amount = amount
	max_amount = max_amount
