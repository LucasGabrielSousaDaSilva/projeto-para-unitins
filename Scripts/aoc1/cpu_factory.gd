extends Control

@onready var phase_1: Control = %Phase1
@onready var phase_2: Control = %Phase2

@onready var phase_label: Label = %PhaseLabel
@onready var score_label: Label = %ScoreLabel

@onready var power_button: Button = %PowerButton

@onready var boot_overlay: ColorRect = $%BootOverlay
@onready var status_panel: PanelContainer = %StatusPanel
@onready var status_title: Label = %StatusTitle
@onready var status_message: Label = %StatusMessage
@onready var next_button: Button = %NextButton

@onready var boot_progress: ProgressBar = %ProgressBar

@onready var check_cpu: Label = %CheckCPU
@onready var check_memory: Label = %CheckMemory
@onready var check_bus: Label = %CheckBus
@onready var check_io: Label = %CheckIO
@onready var final_status: Label = %FinalStatus

var current_phase := 1
var score := 1000

var phase_1_slots: Array[DropSlot]
var phase_2_slots: Array[DropSlot]


func _ready() -> void:
	phase_1_slots = [
		$Phase1/Board/MemorySlot,
		$Phase1/Board/ProcessorSlot,
		$Phase1/Board/PeripheralSlot
	]

	phase_2_slots = [
		$Phase2/CPUBoard/ControlSlot,
		$Phase2/CPUBoard/ALUSlot,
		$Phase2/CPUBoard/RegistersSlot,
		$Phase2/CPUBoard/CacheSlot
	]

	phase_1.show()
	phase_2.hide()
	boot_overlay.hide()
	# status_panel.hide()
	next_button.hide()

	power_button.pressed.connect(_on_power_pressed)
	next_button.pressed.connect(_on_next_pressed)
	power_button.pivot_offset = power_button.size / 2.0

	_update_ui()


func _on_power_pressed() -> void:
	var slots: Array[DropSlot]

	if current_phase == 1:
		slots = phase_1_slots
	else:
		slots = phase_2_slots

	var correct := true

	for slot in slots:
		if slot.current_component.is_empty():
			correct = false

	for slot in slots:
		if not slot.is_correct():
			correct = false

	await play_boot_and_wait(correct)

	if correct:
		_phase_completed()
	else:
		_show_first_error(slots)

		await get_tree().create_timer(2.0).timeout

		reset_current_phase()

func play_boot_and_wait(success: bool) -> void:
	play_boot_sequence(success)

	await get_tree().create_timer(2.5).timeout

	boot_overlay.hide()

func _show_hardware_error(slot: DropSlot) -> void:
	var placed := _get_component_name(slot.current_component)
	var expected := _get_component_name(slot.expected_component)

	#status_panel.show()
	status_title.text = "⚠ FALHA DE HARDWARE"
	status_message.text = (
		"%s foi instalado no local incorreto.\n\n"
		+ "Esse encaixe é destinado a: %s."
	) % [placed, expected]

	next_button.hide()


func _phase_completed() -> void:
	#status_panel.show()

	if current_phase == 1:
		status_title.text = "✓ BOOT PARCIAL CONCLUÍDO"
		status_message.text = (
			"Memória, processador e periféricos estão "
			+ "corretamente conectados ao barramento.\n\n"
			+ "Agora precisamos montar o interior da CPU."
		)

		next_button.text = "ABRIR PROCESSADOR"
		next_button.show()

	else:
		status_title.text = "✓ BOOT CONCLUÍDO"
		status_message.text = (
			"CPU operacional.\n\n"
			+ "Unidade de Controle, ULA, Registradores e Cache "
			+ "instalados corretamente.\n\n"
			+ "SISTEMA PRONTO."
		)

		power_button.disabled = true
		next_button.text = "JOGAR NOVAMENTE"
		next_button.show()


func _show_error(title: String, message: String) -> void:
	status_panel.show()
	status_title.text = title
	status_message.text = message
	next_button.hide()


func _on_next_pressed() -> void:
	if current_phase == 1:
		current_phase = 2

		phase_1.hide()
		phase_2.show()

		#status_panel.hide()
		next_button.hide()

		power_button.text = "⚡ LIGAR CPU"

	else:
		get_tree().reload_current_scene()

	_update_ui()


func _update_ui() -> void:
	phase_label.text = "FASE %d/2" % current_phase
	score_label.text = "PONTOS: %04d" % score


func _get_component_name(id: String) -> String:
	match id:
		"memory":
			return "Memória RAM"
		"processor":
			return "Processador"
		"peripherals":
			return "Periféricos"
		"control":
			return "Unidade de Controle"
		"alu":
			return "ULA"
		"registers":
			return "Registradores"
		"cache":
			return "Memória Cache"
		_:
			return id

func play_boot_sequence(success: bool) -> void:
	boot_overlay.show()

	boot_progress.value = 0

	check_cpu.text = "CHECK CPU............"
	check_memory.text = "CHECK MEMORY........."
	check_bus.text = "CHECK BUS............"
	check_io.text = "CHECK I/O............"
	final_status.text = ""

	var tween := create_tween()

	tween.tween_property(boot_progress, "value", 25, 0.4)
	tween.tween_callback(func():
		check_cpu.text = "CHECK CPU............ OK"
	)

	tween.tween_interval(0.25)

	tween.tween_property(boot_progress, "value", 50, 0.4)
	tween.tween_callback(func():
		check_memory.text = "CHECK MEMORY......... OK"
	)

	tween.tween_interval(0.25)

	tween.tween_property(boot_progress, "value", 75, 0.4)
	tween.tween_callback(func():
		check_bus.text = "CHECK BUS............ OK"
	)

	tween.tween_interval(0.25)

	if success:
		tween.tween_property(boot_progress, "value", 100, 0.4)

		tween.tween_callback(func():
			check_io.text = "CHECK I/O............ OK"
			final_status.text = "BOOT CONCLUÍDO\nCPU OPERACIONAL"
		)

	else:
		tween.tween_callback(func():
			check_io.text = "CHECK I/O............ ERROR"
			final_status.text = "FALHA DE HARDWARE"
		)

func animate_power_button() -> void:
	var tween := create_tween()

	tween.tween_property(
		power_button,
		"scale",
		Vector2(0.92, 0.92),
		0.08
	)

	tween.tween_property(
		power_button,
		"scale",
		Vector2.ONE,
		0.12
	)

func _show_first_error(slots: Array[DropSlot]) -> void:
	for slot in slots:
		if slot.current_component.is_empty():
			_show_error(
				"COMPONENTE AUSENTE",
				"Existem componentes que ainda não foram instalados."
			)
			return

		if not slot.is_correct():
			_show_hardware_error(slot)
			return

func reset_current_phase() -> void:
	var slots: Array[DropSlot]

	if current_phase == 1:
		slots = phase_1_slots
	else:
		slots = phase_2_slots

	for slot in slots:
		slot.reset_slot()

	#status_panel.hide()
	next_button.hide()
