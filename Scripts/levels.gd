extends Node2D

@onready var player: Player = $Player

func _ready() -> void:
	if Global.destination_level != "":
		var point = get_node(Global.destination_level)
		if point:
			player.global_position = point.global_position
