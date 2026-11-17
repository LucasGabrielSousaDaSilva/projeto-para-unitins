extends Area2D
## Coloque esta área sobre a porta do Laboratório 1, dentro de unitins.tscn.
## O player da sua cena aparece com o nome "Player".

@export_file("*.tscn") var cena_dos_desafios: String = ""
@export var nome_do_jogador: StringName = &"Player"

var _ativada: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _ativada or body.name != nome_do_jogador:
		return
	if Missoes.encontrar_laboratorio_1(cena_dos_desafios):
		_ativada = true
