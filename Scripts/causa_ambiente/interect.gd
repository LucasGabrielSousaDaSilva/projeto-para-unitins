
extends Area2D

@export var nome_jogo: String = "Minijogo"
@export var cena_jogo: PackedScene

@onready var indicador: Node2D = $Indicador
@onready var label: Label = $Indicador/Label

var jogador_perto: bool = false
var jogador: Node2D = null


func _ready() -> void:
	indicador.hide()
	label.text = "[E] " + nome_jogo

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_perto = true
		jogador = body
		indicador.show()


func _on_body_exited(body: Node2D) -> void:
	if body == jogador:
		jogador_perto = false
		jogador = null
		indicador.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not jogador_perto:
		return

	if event.is_action_pressed("interagir") and not event.is_echo():

		if cena_jogo == null:
			push_warning(
				"Nenhum jogo configurado para " + nome_jogo
			)
			return

		if GameManager.em_transicao:
			return

		get_viewport().set_input_as_handled()

		GameManager.abrir_jogo(cena_jogo, jogador)
