extends Control


# ============================================================
# CONFIGURAÇÃO DA BATALHA
# ============================================================

const PLAYER_MAX_HP: int = 100
const ENEMY_MAX_HP: int = 100

const PLAYER_DAMAGE: int = 25
const ENEMY_DAMAGE: int = 15

const ANSWER_FEEDBACK_TIME: float = 0.35
const AFTER_ATTACK_TIME: float = 0.30


# ============================================================
# CORES
# ============================================================

const COLOR_NORMAL: Color = Color.WHITE
const COLOR_CORRECT: Color = Color("#39E58C")
const COLOR_WRONG: Color = Color("#FF3D67")
const COLOR_ATTACK_PLAYER: Color = Color("#23D9FF")
const COLOR_ATTACK_ENEMY: Color = Color("#FF3D67")


# ============================================================
# ESTADO DA BATALHA
# ============================================================

var player_hp: int = PLAYER_MAX_HP
var enemy_hp: int = ENEMY_MAX_HP

var score: int = 0
var combo: int = 0
var turn: int = 1

var correct_answer: String = ""

var battle_locked: bool = false
var battle_over: bool = false


# ============================================================
# RNG
# ============================================================

var rng := RandomNumberGenerator.new()


# ============================================================
# HUD - PLAYER
# ============================================================

@onready var player_hp_bar: ProgressBar = \
	$TopHUD/PlayerCard/Margin/VBox/PlayerHPBar

@onready var player_hp_label: Label = \
	$TopHUD/PlayerCard/Margin/VBox/PlayerTopRow/PlayerHPLabel


# ============================================================
# HUD - ENEMY
# ============================================================

@onready var enemy_hp_bar: ProgressBar = \
	$TopHUD/EnemyCard/Margin/VBox/EnemyHPBar

@onready var enemy_hp_label: Label = \
	$TopHUD/EnemyCard/Margin/VBox/EnemyTopRow/EnemyHPLabel


# ============================================================
# HUD - ESTATÍSTICAS
# ============================================================

@onready var combo_label: Label = \
	$TopHUD/TitleBlock/BattleStats/ComboLabel

@onready var turn_label: Label = \
	$TopHUD/TitleBlock/BattleStats/TurnLabel

@onready var score_label: Label = \
	$TopHUD/TitleBlock/BattleStats/ScoreLabel


# ============================================================
# ARENA
# ============================================================

@onready var arena: Control = $Arena

@onready var player_fighter: PanelContainer = \
	$Arena/PlayerFighter

@onready var enemy_fighter: PanelContainer = \
	$Arena/EnemyFighter

@onready var player_binary: Label = \
	$Arena/PlayerFighter/PlayerVBox/PlayerBinary

@onready var enemy_binary: Label = \
	$Arena/EnemyFighter/EnemyVBox/EnemyBinary

@onready var attack_fx: Label = \
	$Arena/AttackFX


# ============================================================
# PERGUNTA
# ============================================================

@onready var question_panel: PanelContainer = \
	$QuestionPanel

@onready var operation_type: Label = \
	$QuestionPanel/QuestionMargin/QuestionVBox/OperationType

@onready var number_a: Label = \
	$QuestionPanel/QuestionMargin/QuestionVBox/NumberA

@onready var number_b: Label = \
	$QuestionPanel/QuestionMargin/QuestionVBox/NumberB

@onready var question_mark: Label = \
	$QuestionPanel/QuestionMargin/QuestionVBox/QuestionMark


# ============================================================
# RESPOSTAS
# ============================================================

@onready var answer_buttons: Array[Button] = [
	$Answers/Answer1,
	$Answers/Answer2,
	$Answers/Answer3,
	$Answers/Answer4
]


# ============================================================
# OUTROS
# ============================================================

@onready var message_label: Label = \
	$MessageLabel

@onready var animation_player: AnimationPlayer = \
	$AnimationPlayer

var question_manager := QuestionManager.new()

@onready var result_overlay: Control = \
	$ResultOverlay

@onready var result_panel: PanelContainer = \
	$ResultOverlay/ResultPanel

@onready var result_title: Label = \
	$ResultOverlay/ResultPanel/Margin/VBox/ResultTitle

@onready var result_subtitle: Label = \
	$ResultOverlay/ResultPanel/Margin/VBox/ResultSubtitle

@onready var result_score: Label = \
	$ResultOverlay/ResultPanel/Margin/VBox/ResultScore

@onready var result_turns: Label = \
	$ResultOverlay/ResultPanel/Margin/VBox/ResultTurns

@onready var restart_button: Button = \
	$ResultOverlay/ResultPanel/Margin/VBox/RestartButton

# ============================================================
# READY
# ============================================================

func _ready() -> void:
	
	result_overlay.visible = false

	restart_button.pressed.connect(
		restart_battle
	)
	
	rng.randomize()

	player_hp = PLAYER_MAX_HP
	enemy_hp = ENEMY_MAX_HP

	score = 0
	combo = 0
	turn = 1

	battle_locked = false
	battle_over = false

	attack_fx.visible = false
	message_label.text = ""

	for button in answer_buttons:
		button.pressed.connect(
			_on_answer_pressed.bind(button)
		)

	_configure_pivots()

	update_interface()
	generate_question()
	

func _configure_pivots() -> void:
	await get_tree().process_frame

	player_fighter.pivot_offset = player_fighter.size / 2.0
	enemy_fighter.pivot_offset = enemy_fighter.size / 2.0

	question_panel.pivot_offset = question_panel.size / 2.0
	message_label.pivot_offset = message_label.size / 2.0
	

func restart_battle() -> void:
	animation_player.stop()
	question_panel.modulate.a = 1.0

	battle_over = false
	battle_locked = true

	player_hp = PLAYER_MAX_HP
	enemy_hp = ENEMY_MAX_HP

	score = 0
	combo = 0
	turn = 1

	correct_answer = ""

	message_label.text = ""

	player_binary.text = "00000000"
	enemy_binary.text = "101?110!"

	reset_combat_visuals()

	player_hp_bar.value = PLAYER_MAX_HP
	enemy_hp_bar.value = ENEMY_MAX_HP

	update_interface()

	result_overlay.visible = false

	generate_question()

	battle_locked = false
	set_answer_buttons_locked(false)

#func int_to_binary(value: int, minimum_bits: int = 1) -> String:
	#var binary := String.num_int64(value, 2)
#
	#while binary.length() < minimum_bits:
		#binary = "0" + binary
#
	#return binary
	

func generate_question() -> void:
	reset_answer_buttons()

	var difficulty := 1

	if turn >= 4:
		difficulty = 2

	if turn >= 7:
		difficulty = 3

	var question := question_manager.generate_question(
		difficulty
	)

	operation_type.text = question["title"]

	number_a.text = question["line_a"]
	number_b.text = question["line_b"]

	question_mark.text = "?"

	correct_answer = question["correct_answer"]

	player_binary.text = question["player_display"]

	var answers: Array[String] = question["answers"]

	for i in range(answer_buttons.size()):
		answer_buttons[i].text = answers[i]

#func generate_answers(
	#correct_value: int,
	#bit_count: int
#) -> void:
#
	#var values: Array[int] = []
#
	#values.append(correct_value)
#
	#var variations: Array[int] = [
		#1,
		#-1,
		#2,
		#-2,
		#4,
		#-4,
		#8,
		#-8
	#]
#
	#variations.shuffle()
#
	#for variation in variations:
		#if values.size() >= 4:
			#break
#
		#var candidate := correct_value + variation
#
		#if candidate < 0:
			#continue
#
		#if candidate in values:
			#continue
#
		#values.append(candidate)
#
	#while values.size() < 4:
		#var candidate := rng.randi_range(
			#0,
			#31
		#)
#
		#if candidate not in values:
			#values.append(candidate)
#
	#values.shuffle()
#
	#for i in range(answer_buttons.size()):
		#answer_buttons[i].text = int_to_binary(
			#values[i],
			#bit_count
		#)

func _on_answer_pressed(
	button: Button
) -> void:

	if battle_locked:
		return

	if battle_over:
		return

	battle_locked = true
	set_answer_buttons_locked(true)

	if button.text == correct_answer:
		await handle_correct_answer(button)
	else:
		await handle_wrong_answer(button)
		

func set_answer_buttons_locked(
	locked: bool
) -> void:

	for button in answer_buttons:
		button.disabled = locked

func handle_correct_answer(
	button: Button
) -> void:

	button.modulate = COLOR_CORRECT

	combo += 1

	var points_received := 100 * combo
	score += points_received

	message_label.text = \
		"PROCESSAMENTO CORRETO!  +%d PTS" \
		% points_received

	await play_animation(
		"correct_answer"
	)

	await player_attack()

	var new_enemy_hp : int = max(
		enemy_hp - PLAYER_DAMAGE,
		0
	)

	await animate_hp(
		enemy_hp_bar,
		enemy_hp_label,
		enemy_hp,
		new_enemy_hp,
		ENEMY_MAX_HP
	)

	enemy_hp = new_enemy_hp

	update_interface()

	if enemy_hp <= 0:
		victory()
		return

	await get_tree().create_timer(
		AFTER_ATTACK_TIME
	).timeout

	next_turn()

func handle_wrong_answer(
	button: Button
) -> void:

	button.modulate = COLOR_WRONG

	combo = 0

	reveal_correct_answer()

	message_label.text = \
		"ERRO DE PROCESSAMENTO!"

	await play_animation(
		"wrong_answer"
	)

	await enemy_attack()

	var new_player_hp : int = max(
		player_hp - ENEMY_DAMAGE,
		0
	)

	await animate_hp(
		player_hp_bar,
		player_hp_label,
		player_hp,
		new_player_hp,
		PLAYER_MAX_HP
	)

	player_hp = new_player_hp

	update_interface()

	if player_hp <= 0:
		game_over()
		return

	await get_tree().create_timer(
		AFTER_ATTACK_TIME
	).timeout

	next_turn()

func reveal_correct_answer() -> void:
	for button in answer_buttons:
		if button.text == correct_answer:
			button.modulate = COLOR_CORRECT

func reset_answer_buttons() -> void:
	for button in answer_buttons:
		button.modulate = COLOR_NORMAL

func next_turn() -> void:
	turn += 1

	message_label.text = ""

	reset_combat_visuals()

	generate_question()

	update_interface()

	battle_locked = false
	set_answer_buttons_locked(false)

func reset_combat_visuals() -> void:
	player_fighter.scale = Vector2.ONE
	enemy_fighter.scale = Vector2.ONE

	player_fighter.modulate = Color.WHITE
	enemy_fighter.modulate = Color.WHITE

	question_panel.scale = Vector2.ONE
	question_panel.modulate = Color.WHITE

	message_label.scale = Vector2.ONE
	message_label.modulate = Color.WHITE

	attack_fx.visible = false

	reset_answer_buttons()

func update_interface() -> void:
	player_hp_bar.max_value = PLAYER_MAX_HP
	enemy_hp_bar.max_value = ENEMY_MAX_HP

	player_hp_bar.value = player_hp
	enemy_hp_bar.value = enemy_hp

	player_hp_label.text = \
		"%d / %d HP" % [
			player_hp,
			PLAYER_MAX_HP
		]

	enemy_hp_label.text = \
		"%d / %d HP" % [
			enemy_hp,
			ENEMY_MAX_HP
		]

	combo_label.text = \
		"COMBO x%d" % combo

	turn_label.text = \
		"TURNO %d" % turn

	score_label.text = \
		"%04d PTS" % score

func animate_hp(
	bar: ProgressBar,
	label: Label,
	old_value: int,
	new_value: int,
	max_hp: int
) -> void:

	var tween := create_tween()

	tween.set_trans(
		Tween.TRANS_QUAD
	)

	tween.set_ease(
		Tween.EASE_OUT
	)

	tween.tween_method(
		func(current_value: float) -> void:
			bar.value = current_value

			label.text = \
				"%d / %d HP" % [
					roundi(current_value),
					max_hp
				],
		float(old_value),
		float(new_value),
		0.45
	)

	await tween.finished

func launch_attack_packet(
	from_player: bool
) -> Tween:

	var bus_y := (
		arena.size.y * 0.50
	) - 14.0

	var start_position: Vector2
	var end_position: Vector2

	if from_player:
		attack_fx.text = "101101  ►►►"

		attack_fx.modulate = \
			COLOR_ATTACK_PLAYER

		start_position = Vector2(
			player_fighter.position.x
			+ player_fighter.size.x,
			bus_y
		)

		end_position = Vector2(
			enemy_fighter.position.x
			- 110.0,
			bus_y
		)

	else:
		attack_fx.text = "◄◄◄  ERROR"

		attack_fx.modulate = \
			COLOR_ATTACK_ENEMY

		start_position = Vector2(
			enemy_fighter.position.x
			- 110.0,
			bus_y
		)

		end_position = Vector2(
			player_fighter.position.x
			+ player_fighter.size.x,
			bus_y
		)

	attack_fx.position = start_position
	attack_fx.visible = true

	var tween := create_tween()

	tween.set_trans(
		Tween.TRANS_QUAD
	)

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.tween_property(
		attack_fx,
		"position",
		end_position,
		0.60
	)

	tween.tween_callback(
		func() -> void:
			attack_fx.visible = false
	)

	return tween

func player_attack() -> void:
	var packet_tween := launch_attack_packet(
		true
	)

	if animation_player.has_animation(
		"player_attack"
	):
		animation_player.play(
			"player_attack"
		)

	await packet_tween.finished
	
	shake_control(
		enemy_fighter,
		7.0,
		0.20
	)

	await enemy_glitch()


func enemy_attack() -> void:
	var packet_tween := launch_attack_packet(
		false
	)

	if animation_player.has_animation(
		"enemy_attack"
	):
		animation_player.play(
			"enemy_attack"
		)

	await packet_tween.finished

	shake_control(
		player_fighter,
		7.0,
		0.20
	)


func play_animation(
	animation_name: StringName
) -> void:

	if not animation_player.has_animation(
		animation_name
	):
		return

	animation_player.play(
		animation_name
	)

	await animation_player.animation_finished


func enemy_glitch() -> void:
	var original_text := enemy_binary.text

	var glitches: Array[String] = [
		"1?0!#01?",
		"ERR0R!!",
		"###101?!",
		"10??11!!"
	]

	for i in range(4):
		enemy_binary.text = glitches.pick_random()

		await get_tree().create_timer(
			0.045
		).timeout

	enemy_binary.text = original_text


func victory() -> void:
	battle_over = true
	battle_locked = true

	set_answer_buttons_locked(true)

	attack_fx.visible = false

	score += 500

	enemy_binary.text = "00000000"

	update_interface()

	message_label.text = "INIMIGO ELIMINADO!"

	await get_tree().create_timer(0.8).timeout

	show_result_screen(true)


func game_over() -> void:
	battle_over = true
	battle_locked = true

	set_answer_buttons_locked(true)

	attack_fx.visible = false

	player_binary.text = "00000000"

	message_label.text = "ULA DESATIVADA!"

	await get_tree().create_timer(0.8).timeout

	show_result_screen(false)
	


func show_result_screen(victory_result: bool) -> void:
	result_overlay.visible = true

	result_panel.scale = Vector2(
		0.85,
		0.85
	)

	result_panel.modulate.a = 0.0
	question_panel.modulate.a = 0.35

	if victory_result:
		result_title.text = "PROCESSO FINALIZADO"

		result_title.modulate = \
			COLOR_CORRECT

		result_subtitle.text = \
			"BIT INVERTIDO ELIMINADO"

		restart_button.text = \
			"LUTAR NOVAMENTE"

	else:
		result_title.text = \
			"ULA DESATIVADA"

		result_title.modulate = \
			COLOR_WRONG

		result_subtitle.text = \
			"PROCESSAMENTO INTERROMPIDO"

		restart_button.text = \
			"TENTAR NOVAMENTE"

	result_score.text = \
		"PONTUAÇÃO: %04d" % score

	result_turns.text = \
		"TURNOS PROCESSADOS: %d" % turn

	var tween := create_tween()

	tween.set_parallel(true)

	tween.set_trans(
		Tween.TRANS_BACK
	)

	tween.set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		result_panel,
		"scale",
		Vector2.ONE,
		0.35
	)

	tween.tween_property(
		result_panel,
		"modulate:a",
		1.0,
		0.25
	)

func shake_control(
	control: Control,
	strength: float = 8.0,
	duration: float = 0.25
) -> void:

	var original_position := control.position

	var tween := create_tween()

	var steps := 6

	for i in range(steps):
		var offset := Vector2(
			rng.randf_range(
				-strength,
				strength
			),
			rng.randf_range(
				-strength,
				strength
			)
		)

		tween.tween_property(
			control,
			"position",
			original_position + offset,
			duration / float(steps)
		)

	tween.tween_property(
		control,
		"position",
		original_position,
		0.05
	)
