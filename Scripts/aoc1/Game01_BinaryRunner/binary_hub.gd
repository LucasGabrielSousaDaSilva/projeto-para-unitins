extends Control
## HUB com liberação sequencial e retorno opcional à cena real do laboratório.
@export_file("*.tscn") var laboratory_scene_path: String = ""
const TITLES := [
	"01  |  BITS", "02  |  BYTE", "03  |  BIN ↔ DEC",
	"04  |  HEXA", "05  |  BOSS"
]
const SUMMARIES := [
	"10₁₀ → 1010₂", "8 bits + nibbles", "Conversões base 2/10",
	"Base 16: 0–F", "Desafio final"
]
const SCENES := [
	"res://Prefabs/AOC1/Game01_BinaryRunner/Level01.tscn",
	"res://Prefabs/AOC1/Game01_BinaryRunner/Level02.tscn",
	"res://Prefabs/AOC1/Game01_BinaryRunner/Level03.tscn",
	"res://Prefabs/AOC1/Game01_BinaryRunner/Level04.tscn",
    "res://Prefabs/AOC1/Game01_BinaryRunner/Boss.tscn"
]

@onready var progress: Node = get_node("/root/BinaryProgress")

func _ready() -> void:
	for i in range(5):
		var button: Button = get_node("StageCards/Card%d" % (i + 1))
		button.pressed.connect(_open_phase.bind(i + 1))
	#$BackButton.pressed.connect(_back_to_lab)
	$ResetButton.pressed.connect(func(): $ResetConfirmation.popup_centered())
	$ResetConfirmation.confirmed.connect(_reset_all)
	_refresh()

func _refresh() -> void:
	var done: int = (progress.get("completed") as Array).size()
	$ProgressLabel.text = "PROGRESSO: %d/5 ETAPAS CONCLUÍDAS" % done
	$ProgressBar.value = done * 20
	for i in range(5):
		var stage: int = i + 1
		var card: Button = get_node("StageCards/Card%d" % stage)
		var unlocked: bool = bool(progress.call("is_unlocked", stage))
		var finished: bool = bool(progress.call("is_completed", stage))
		card.disabled = not unlocked
		card.text = "%s\n\n%s\n\n%s" % [TITLES[i], SUMMARIES[i], "✓ CONCLUÍDA" if finished else ("▶ JOGAR" if unlocked else "🔒 BLOQUEADA")]
		card.tooltip_text = "Conclua a etapa %d antes" % (stage - 1) if not unlocked else "Iniciar ou repetir esta etapa"
	$FinalLabel.text = "TODAS AS ETAPAS CONCLUÍDAS! Retorne ao laboratório." if bool(progress.call("all_completed")) else "Conclua uma etapa para desbloquear a seguinte."
	$FinalLabel.add_theme_color_override("font_color", Color("66edb9") if bool(progress.call("all_completed")) else Color("c0d6e7"))
	#$BackButton.text = "VOLTAR AO LABORATÓRIO" if bool(progress.call("can_return_to_laboratory", laboratory_scene_path)) else "VOLTAR AO LABORATÓRIO (CONFIGURAR)"

func _open_phase(phase: int) -> void:
	if not bool(progress.call("is_unlocked", phase)):
		return
	get_tree().change_scene_to_file(SCENES[phase - 1])

#func _back_to_lab() -> void:
	#if not bool(progress.call("can_return_to_laboratory", laboratory_scene_path)):
		#$FinalLabel.text = "Configure Laboratory Scene Path no Inspector ou abra o HUB pelo laboratório."
		#return
	#progress.call("return_to_laboratory", laboratory_scene_path)

func _reset_all() -> void:
	progress.call("reset_progress")
	_refresh()


func _on_back_button_pressed() -> void:
	GameManager.voltar_laboratorio()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		GameManager.voltar_laboratorio()
