extends Node2D

@onready var registers = $World/Registers
@onready var l1 = $World/CacheL1
@onready var l2 = $World/CacheL2
@onready var l3 = $World/CacheL3
@onready var ram = $World/RAM
@onready var storage = $World/Storage

@onready var player = $World/PlayerAOC

@onready var target_label = $HUD/TopPanel/TargetLabel
@onready var score_label = $HUD/TopPanel/ScoreLabel
@onready var time_label = $HUD/TopPanel/TimeLabel
@onready var streak_label = $HUD/TopPanel/StreakLabel

@onready var message_panel = $HUD/MessagePanel
@onready var message_label = $HUD/MessagePanel/MessageLabel

@onready var message_timer = $MessageTimer

var next_allowed_memory: int = 0

var memory_zones = []

var current_zone = null

var target_data: String = ""
var target_memory_index: int = 0

var score: int = 0
var streak: int = 0

var round_time: float = 0.0

var round_active := false


func _ready():
	memory_zones = [
		registers,
		l1,
		l2,
		l3,
		ram,
		storage
	]

	for zone in memory_zones:
		zone.player_entered.connect(_on_zone_entered)
		zone.player_exited.connect(_on_zone_exited)

	message_timer.timeout.connect(_hide_message)

	start_round()

func generate_data() -> String:
	var value = randi_range(0, 255)

	return "%02X" % value
	

func start_round():
	round_active = true

	next_allowed_memory = 0

	round_time = 0.0

	target_data = generate_data()

	for zone in memory_zones:
		zone.set_target(false)

	target_memory_index = randi_range(0, memory_zones.size() - 1)

	memory_zones[target_memory_index].set_target(true)

	target_label.text = "CPU PRECISA DO DADO: " + target_data

	update_hud()

	show_message(
		"NOVA REQUISIÇÃO\nProcure o dado " + target_data
	)

func _process(delta):
	if round_active:
		round_time += delta

	time_label.text = "TEMPO: %.1f s" % round_time

	if Input.is_action_just_pressed("interact"):
		if current_zone != null:
			check_memory(current_zone)
			

func _on_zone_entered(zone):
	current_zone = zone

	show_message(
		"PRESSIONE E PARA VERIFICAR\n" +
		zone.memory_name
	)

func _on_zone_exited(zone):
	if current_zone == zone:
		current_zone = null

func check_memory(zone):
	if not round_active:
		return

	if zone.memory_index != next_allowed_memory:
		show_message(
			"ACESSO INVÁLIDO!\n" +
			"Verifique " +
			memory_zones[next_allowed_memory].memory_name +
			" primeiro."
		)

		return

	if zone.contains_target:
		cache_hit(zone)
	else:
		cache_miss(zone)

func cache_hit(zone):
	round_active = false

	var gained_points = zone.points

	var time_bonus = calculate_time_bonus()

	gained_points += time_bonus

	var multiplier = get_multiplier()

	gained_points *= multiplier

	score += gained_points
	streak += 1

	show_message(
		"CACHE HIT!\n\n" +
		target_data +
		" encontrado em " +
		zone.memory_name +
		"\n+" +
		str(gained_points) +
		" pontos",
		2.5
	)

	update_hud()

	await get_tree().create_timer(2.5).timeout

	start_round()

func calculate_time_bonus() -> int:
	if round_time <= 3.0:
		return 50

	elif round_time <= 5.0:
		return 25

	elif round_time <= 8.0:
		return 10

	return 0

func cache_miss(zone):
	streak = 0

	next_allowed_memory += 1

	if next_allowed_memory < memory_zones.size():
		var next_zone = memory_zones[next_allowed_memory]

		show_message(
			"CACHE MISS!\n\n" +
			target_data +
			" não está em " +
			zone.memory_name +
			"\nProcure em " +
			next_zone.memory_name,
			2.0
		)

	update_hud()

func update_hud():
	score_label.text = "SCORE: " + str(score)

	streak_label.text = "SEQUÊNCIA: x" + str(streak)

func show_message(text: String, duration: float = 2.0):
	message_panel.show()

	message_label.text = text

	message_timer.wait_time = duration
	message_timer.start()



func _hide_message():
	message_panel.hide()

func get_multiplier() -> int:

	if streak >= 10:
		return 5

	elif streak >= 5:
		return 3

	elif streak >= 3:
		return 2

	return 1
