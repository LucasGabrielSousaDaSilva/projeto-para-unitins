extends Node2D
## Fase 1: os quatro bits representam 8, 4, 2, 1.
const TARGET_CODE: String = "1010"
const TARGET_DECIMAL: int = 10
const MAX_LIVES: int = 3

var lives: int = MAX_LIVES
var selected_bits: Array[String] = ["_", "_", "_", "_"]
var game_finished: bool = false
var phase_won: bool = false


@onready var result_action_button: Button = $HUD/HUDRoot/ResultPanel/RestartButton
@onready var player: CharacterBody2D = $World/Player
@onready var code_label: Label = $HUD/HUDRoot/TopPanel/CodeLabel
@onready var lives_label: Label = $HUD/HUDRoot/TopPanel/LivesLabel
@onready var hint_label: Label = $HUD/HUDRoot/HintPanel/HintLabel
@onready var shade: ColorRect = $HUD/HUDRoot/Shade
@onready var result_panel: Panel = $HUD/HUDRoot/ResultPanel
@onready var result_title: Label = $HUD/HUDRoot/ResultPanel/ResultTitle
@onready var result_description: Label = $HUD/HUDRoot/ResultPanel/ResultDescription
@onready var gate: Area2D = $World/Gate

func _ready() -> void:
	for station in $World/Stations.get_children():
		for candidate in station.get_children():
			if candidate.has_signal("picked_up"):
				candidate.connect("picked_up", Callable(self, "_on_bit_picked_up"))

	player.connect("damaged", Callable(self, "_on_player_damaged"))
	gate.connect("player_entered", Callable(self, "_on_gate_reached"))
	$HUD/HUDRoot/TopPanel/RestartButton.pressed.connect(restart_level)
	result_action_button.pressed.connect(_on_result_action_pressed)
	_update_hud()
	_set_hint("A/D ou ←/→: mover   •   Espaço: pular   •   Pesos dos bits: 8, 4, 2, 1")
	

func _on_bit_picked_up(pickup: Area2D, slot_index: int, bit_value: int) -> void:
	if game_finished or selected_bits[slot_index] != "_":
		return
	selected_bits[slot_index] = str(bit_value)
	for other in pickup.get_parent().get_children():
		if other != pickup and other is Area2D:
			other.set_deferred("monitoring", false)
			other.hide()
	_update_hud()
	_set_hint("Estação %d/4: você escolheu %d. Continue até o portão digital!" % [slot_index + 1, bit_value])

func _on_player_damaged() -> void:
	if game_finished:
		return
	lives -= 1
	_update_hud()
	if lives <= 0:
		_finish(false, "O sinal se perdeu nos circuitos. Tente novamente e pule os obstáculos!")
	else:
		_set_hint("Choque no barramento! Restam %d vidas. Pule as áreas vermelhas." % lives)

func _on_gate_reached() -> void:
	if game_finished:
		return
	var code: String = selected_bits[0] + selected_bits[1] + selected_bits[2] + selected_bits[3]
	if code == TARGET_CODE:
		gate.call("show_success")
		_finish(true, "Muito bem! 1010₂ = 8 + 0 + 2 + 0 = 10₁₀. Você dominou os bits!")
	else:
		gate.call("show_failure")
		_finish(false, "Acesso negado: você formou %s. A resposta é 1010, pois 10 = 8 + 2." % code)

func _finish(won: bool, description: String) -> void:
	game_finished = true
	player.call("stop_player")
	shade.show()
	result_panel.show()
	result_title.text = "FASE 1 CONCLUÍDA!" if won else "TENTE NOVAMENTE"
	result_title.add_theme_color_override("font_color", Color("52edb4") if won else Color("ff7d91"))
	result_description.text = description
	_set_hint("Pressione REINICIAR para recomeçar com três vidas e todos os bits disponíveis.")
	
	phase_won = won
	if won:
		BinaryProgress.complete_phase(1)
	result_action_button.text = "VOLTAR AO HUB" if won else "TENTAR NOVAMENTE"

func _update_hud() -> void:
	code_label.text = "%s     %s     %s     %s" % [selected_bits[0], selected_bits[1], selected_bits[2], selected_bits[3]]
	lives_label.text = "VIDAS: %d/%d" % [lives, MAX_LIVES]

func _set_hint(message: String) -> void:
	hint_label.text = message

func restart_level() -> void:
	get_tree().reload_current_scene()

func _on_result_action_pressed() -> void:
	if phase_won:
		BinaryProgress.open_hub()
	else:
		restart_level()
