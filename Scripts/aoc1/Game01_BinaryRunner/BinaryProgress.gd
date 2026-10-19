extends Node
## Autoload BinaryProgress — progresso salvo entre sessões do jogo.
const SAVE_FILE: String = "user://binary_runner_progresso.cfg"
const HUB_SCENE: String = "res://Prefabs/AOC1/Game01_BinaryRunner/BinaryHub.tscn"

var highest_unlocked: int = 1
var completed: Array[int] = []
var laboratory_scene_path: String = ""

func _ready() -> void:
	load_progress()

func load_progress() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_FILE)
	if error != OK:
		return
	highest_unlocked = clampi(int(config.get_value("progress", "highest_unlocked", 1)), 1, 5)
	completed.clear()
	var stored: Array = config.get_value("progress", "completed", [])
	for value in stored:
		var phase := int(value)
		if phase >= 1 and phase <= 5 and not completed.has(phase):
			completed.append(phase)
	# Corrige saves antigos incompletos ou incoerentes.
	for phase in range(1, 5):
		if completed.has(phase):
			highest_unlocked = maxi(highest_unlocked, phase + 1)

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_unlocked", highest_unlocked)
	config.set_value("progress", "completed", completed)
	var error := config.save(SAVE_FILE)
	if error != OK:
		push_error("BinaryProgress: não foi possível salvar: %s" % error)

func is_unlocked(phase: int) -> bool:
	return phase >= 1 and phase <= highest_unlocked

func is_completed(phase: int) -> bool:
	return completed.has(phase)

func complete_phase(phase: int) -> void:
	if phase < 1 or phase > 5 or not is_unlocked(phase):
		return
	if not completed.has(phase):
		completed.append(phase)
	highest_unlocked = maxi(highest_unlocked, mini(phase + 1, 5))
	save_progress()

func all_completed() -> bool:
	return completed.size() == 5

func reset_progress() -> void:
	completed.clear()
	highest_unlocked = 1
	save_progress()

func enter_from_laboratory(scene_path: String) -> void:
	# Chame esta função no botão do laboratório para habilitar o retorno.
	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		laboratory_scene_path = scene_path
	open_hub()

func open_hub() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)

func can_return_to_laboratory(fallback_path: String = "") -> bool:
	return (not laboratory_scene_path.is_empty() and ResourceLoader.exists(laboratory_scene_path)) or (not fallback_path.is_empty() and ResourceLoader.exists(fallback_path))

func return_to_laboratory(fallback_path: String = "") -> void:
	var target := laboratory_scene_path
	if target.is_empty() or not ResourceLoader.exists(target):
		target = fallback_path
	if target.is_empty() or not ResourceLoader.exists(target):
		push_warning("Defina o caminho do laboratório no Inspector do BinaryHub ou entre pelo botão do laboratório.")
		return
	get_tree().change_scene_to_file(target)
