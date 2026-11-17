extends Node2D
## Script único para Fases 2, 3, 4 e Boss (Fase 1 opcional no pacote completo).
@export_range(1, 5, 1) var phase_id: int = 2
const MissionData = preload("res://Scripts/aoc1/Game01_BinaryRunner/runner_data.gd")
const MAX_LIVES: int = 3
var lives: int = MAX_LIVES
var selected: Array[String] = []
var mission: Dictionary = {}
var game_finished: bool = false
var phase_won: bool = false

@onready var player: CharacterBody2D = $World/Player
@onready var code_label: Label = $HUD/HUDRoot/TopPanel/CodeLabel
@onready var lives_label: Label = $HUD/HUDRoot/TopPanel/LivesLabel
@onready var hint_label: Label = $HUD/HUDRoot/HintPanel/HintLabel
@onready var shade: ColorRect = $HUD/HUDRoot/Shade
@onready var result_panel: Panel = $HUD/HUDRoot/ResultPanel
@onready var result_title: Label = $HUD/HUDRoot/ResultPanel/ResultTitle
@onready var result_description: Label = $HUD/HUDRoot/ResultPanel/ResultDescription
@onready var result_button: Button = $HUD/HUDRoot/ResultPanel/RestartButton
@onready var gate: Area2D = $World/Gate

func _ready() -> void:
	var progress: Node = get_node_or_null("/root/BinaryProgress")
	if progress == null:
		push_error("Adicione BinaryProgress.gd em Project Settings > Autoload com nome BinaryProgress.")
		return
	if not bool(progress.call("is_unlocked", phase_id)):
		call_deferred("_go_to_hub")
		return
	mission = MissionData.get_mission(phase_id)
	if mission.is_empty():
		push_error("Missão sem dados para a fase %d." % phase_id)
		return
	for i in range(mission["answers"].size()):
		selected.append("_")
	$HUD/HUDRoot/TopPanel/Title.text = mission["title"]
	$HUD/HUDRoot/TopPanel/Objective.text = mission["objective"]
	$HUD/HUDRoot/TopPanel/BitsCaption.text = "BYTE (8 BITS) — 128 64 32 16 8 4 2 1" if phase_id == 2 else "CONVERSÕES RESOLVIDAS"
	$World/Gate/GateLabel.text = "NÚCLEO BOSS" if phase_id == 5 else "PORTA DIGITAL"
	for station in $World/Stations.get_children():
		for item in station.get_children():
			if item.has_signal("picked_up"):
				item.connect("picked_up", Callable(self, "_on_option_picked"))
	player.connect("damaged", Callable(self, "_on_player_damaged"))
	gate.connect("player_entered", Callable(self, "_on_gate_reached"))
	$HUD/HUDRoot/TopPanel/RestartButton.pressed.connect(restart_level)
	result_button.pressed.connect(_on_result_pressed)
	$HUD/HUDRoot/HubButton.pressed.connect(_go_to_hub)
	_update_hud()
	_set_hint("A/D: mover  •  Espaço: pular  •  Resolva as estações antes de entrar no portão")

func _on_option_picked(pickup: Area2D, slot_index: int, answer: Variant) -> void:
	if game_finished or slot_index < 0 or slot_index >= selected.size():
		return
	if selected[slot_index] != "_":
		return
	var chosen := str(answer)
	var expected: String = str(mission["answers"][slot_index])
	if mission["mode"] == "choices" and chosen != expected:
		_set_hint("Resposta %s incorreta! Revise a conversão na estação %d e tente de novo." % [chosen, slot_index + 1])
		_on_player_damaged()
		return
	selected[slot_index] = chosen
	for other in pickup.get_parent().get_children():
		if other == pickup and other.has_method("consume"):
			other.call("consume")
		elif other != pickup and other is Area2D:
			other.set_deferred("monitoring", false)
			other.hide()
	_update_hud()
	if mission["mode"] == "choices":
		_set_hint("Correto! Estação %d/%d concluída. Continue até o núcleo." % [slot_index + 1, selected.size()])
	else:
		_set_hint("Bit %d/%d registrado: %s. Continue até o portão." % [slot_index + 1, selected.size(), chosen])

func _on_player_damaged() -> void:
	if game_finished:
		return
	lives -= 1
	_update_hud()
	if lives <= 0:
		_finish(false, "Sinal interrompido! Revise as conversões e tente novamente.")

func _on_gate_reached() -> void:
	if game_finished:
		return
	if selected.has("_"):
		gate.call("show_failure")
		_finish(false, "Portão fechado: faltaram estações. Retorne e tente novamente!")
		return
	for i in range(selected.size()):
		if selected[i] != str(mission["answers"][i]):
			gate.call("show_failure")
			_finish(false, "Código incorreto. %s" % mission["teaching"])
			return
	gate.call("show_success")
	_finish(true, mission["success"])

func _finish(won: bool, description: String) -> void:
	game_finished = true
	phase_won = won
	player.call("stop_player")
	if won:
		get_node("/root/BinaryProgress").call("complete_phase", phase_id)
	shade.show()
	result_panel.show()
	result_title.text = "BOSS DERROTADO!" if won and phase_id == 5 else ("FASE %d CONCLUÍDA!" % phase_id if won else "TENTE NOVAMENTE")
	result_title.add_theme_color_override("font_color", Color("52edb4") if won else Color("ff7d91"))
	result_description.text = description
	if won and phase_id == 5 and bool(get_node("/root/BinaryProgress").call("can_return_to_laboratory")):
		result_button.text = "VOLTAR AO LABORATÓRIO"
	elif won:
		result_button.text = "VOLTAR AO HUB"
	else:
		result_button.text = "TENTAR NOVAMENTE"
	$HUD/HUDRoot/HubButton.hide()
	_set_hint("Progresso salvo!" if won else "Reinicie a fase para tentar novamente.")

func _update_hud() -> void:
	lives_label.text = "VIDAS: %d/%d" % [lives, MAX_LIVES]
	if phase_id <= 2:
		code_label.text = " ".join(PackedStringArray(selected))
	else:
		var correct_count: int = selected.size() - selected.count("_")
		code_label.text = "%d / %d TERMINAIS" % [correct_count, selected.size()]

func _set_hint(message: String) -> void:
	hint_label.text = message

func restart_level() -> void:
	get_tree().reload_current_scene()

func _on_result_pressed() -> void:
	if not phase_won:
		restart_level()
	elif phase_id == 5 and bool(get_node("/root/BinaryProgress").call("can_return_to_laboratory")):
		get_node("/root/BinaryProgress").call("return_to_laboratory")
	else:
		_go_to_hub()

func _go_to_hub() -> void:
	var progress: Node = get_node_or_null("/root/BinaryProgress")
	if progress != null:
		progress.call("open_hub")
