extends Node

@onready var win_lose_controller = %WinLoseController

func _ready() -> void:
	GameEvents.player_died.connect(win_lose_controller.game_lost)
