extends Node2D

@onready var player: Player = $Player

func _ready() -> void:
	if Global.destination_level != "":
		var point = get_node(Global.destination_level)
		if point:
			player.global_position = point.global_position
		else:
			print("⚠️ Ponto de destino não encontrado:", Global.destination_point)
	
	if GameManager.posicao_salva:
		player.global_position = GameManager.posicao_jogador
		GameManager.posicao_salva = false
