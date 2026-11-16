extends Node2D
## Cache Rush — a CPU pede um dado e o jogador percorre a hierarquia de memória.
##
## Como funciona (espelha um acesso real a cache):
##  1. A CPU requisita um endereço (tag de 0x00 a 0xFF).
##  2. O jogador vai ao nível mais rápido (Registradores) e aperta E para consultar.
##     A busca leva tempo proporcional à latência do nível ("stall" da CPU).
##  3. MISS: o dado não está lá, ciclos são gastos e a busca desce ao próximo nível.
##  4. HIT: o dado é achado e volta à CPU, sendo COPIADO para todos os níveis mais
##     rápidos (cache fill). Se o nível estiver cheio, a linha menos usada (LRU) sai.
##  5. Por isso pedir o mesmo dado de novo (localidade temporal) fica muito mais rápido.

const Style = preload("res://Scripts/aoc1/Game03_Cache Rush/cache_style.gd")
const Sim = preload("res://Scripts/aoc1/Game03_Cache Rush/cache_sim.gd")

enum Phase { WAITING, SCANNING, RETURNING, SUMMARY, OVER }

## Número de rodadas da fase (0 = infinito)
@export var total_rounds: int = 10
## Onde o jogador aparece no início de cada rodada
@export var spawn_point: Vector2 = Vector2(640, 392)

const REQUEST_TRAVEL := 0.35  # tempo do pacote de requisição até o nível
const SCAN_TIME: Array = [0.20, 0.35, 0.60, 0.95, 1.50, 2.40]  # "latência" visual da busca
const RETURN_STEP := 0.32  # tempo de cada salto do dado de volta à CPU
const SUMMARY_TIME := 3.2

@onready var registers = $World/Registers
@onready var l1 = $World/CacheL1
@onready var l2 = $World/CacheL2
@onready var l3 = $World/CacheL3
@onready var ram = $World/RAM
@onready var storage = $World/Storage
@onready var player: CharacterBody2D = $World/PlayerAOC
@onready var bus = $Background/Bus
@onready var fx = $FX
@onready var hud = $HUD/Hud
@onready var back_button: Button = $HUD/BotaoVoltar

var sim = Sim.new()
var zones: Array = []
var current_zone = null
var scan_zone = null

var phase: int = Phase.WAITING
var target: int = 0
var next_level: int = 0
var hit_level: int = -1

var round_no: int = 0
var rounds_done: int = 0
var round_time: float = 0.0
var round_cycles: int = 0
var total_cycles: int = 0
var storage_cycles: int = 0
var score: int = 0
var streak: int = 0
var best_streak: int = 0
var cache_hits: int = 0
var cache_misses: int = 0

## 0 = pendente, 1 = consultando, 2 = miss, 3 = hit
var pipeline: Array = [0, 0, 0, 0, 0, 0]
var timer: float = 0.0
var ret_steps: Array = []
var ret_timer: float = 0.0
var ret_filled: Array = []
var ret_evicted: Array = []


func _ready() -> void:
	zones = [registers, l1, l2, l3, ram, storage]
	for i in range(zones.size()):
		var z = zones[i]
		z.memory_index = i
		z.capacity = Sim.CAPACITY[i]
		z.latency_cycles = Sim.CYCLES[i]
		z.player_entered.connect(_on_zone_entered)
		z.player_exited.connect(_on_zone_exited)
	bus.setup(zones)
	_setup_view()
	_style_back_button()
	sim.reset()
	_sync_zones()
	start_round()


func _exit_tree() -> void:
	# devolve a janela ao estado anterior para não afetar as outras salas
	var win := get_window()
	if win != null and _saved_scale_mode >= 0:
		win.content_scale_size = _saved_scale_size
		win.content_scale_mode = _saved_scale_mode as Window.ContentScaleMode
		win.content_scale_aspect = _saved_scale_aspect as Window.ContentScaleAspect


var _saved_scale_size: Vector2i = Vector2i.ZERO
var _saved_scale_mode: int = -1
var _saved_scale_aspect: int = 0


## A fase é desenhada para 1280x720 e inteira na tela: desliga a câmera que
## segue o jogador (zoom 2x) e escala a janela mantendo a proporção.
func _setup_view() -> void:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.enabled = false
	var win := get_window()
	if win != null:
		_saved_scale_size = win.content_scale_size
		_saved_scale_mode = win.content_scale_mode
		_saved_scale_aspect = win.content_scale_aspect
		win.content_scale_size = Vector2i(1280, 720)
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


# ------------------------------------------------------------- rodadas ----

func start_round() -> void:
	round_no += 1
	target = sim.next_request()
	next_level = 0
	hit_level = -1
	round_time = 0.0
	round_cycles = 0
	timer = 0.0
	for i in range(pipeline.size()):
		pipeline[i] = 0
	pipeline[0] = 1
	for z in zones:
		z.reset_round()
	_update_next_marker()
	bus.reset_links()
	bus.active_link = 0
	bus.cpu_req = Style.hex(target)
	bus.cpu_state = 0
	_sync_zones()
	player.global_position = spawn_point
	player.velocity = Vector2.ZERO
	fx.ring(spawn_point, Style.CYAN)
	phase = Phase.WAITING
	hud.toast(
		"NOVA REQUISIÇÃO · %s" % Style.hex(target),
		"A CPU precisa deste dado e está parada (stall) até recebê-lo.\n"
		+ "Comece pelo nível mais rápido: %s. Chegue perto e aperte E." % Sim.NAMES[0],
		Style.CYAN)


func _try_lookup(zone) -> void:
	if zone.memory_index != next_level:
		zone.shake()
		hud.toast(
			"ACESSO FORA DE ORDEM",
			"A CPU sempre consulta do nível mais rápido para o mais lento.\nPróximo da fila: %s." % Sim.NAMES[next_level],
			Style.AMBER, 2.6)
		return
	phase = Phase.SCANNING
	scan_zone = zone
	timer = 0.0
	zone.begin_scan(target)
	fx.send(bus.link_points(zone.memory_index), REQUEST_TRAVEL, Style.CYAN, Style.hex(target), false)
	hud.toast(
		"CONSULTANDO %s" % zone.memory_name,
		"Comparando a tag %s com o conteúdo do nível...\nLatência: %s ciclos." % [Style.hex(target), Style.fmt(Sim.CYCLES[zone.memory_index])],
		Style.CYAN)


func _resolve_lookup() -> void:
	var idx: int = scan_zone.memory_index
	var found: bool = sim.has(idx, target)
	var slot: int = sim.slot_of(idx, target)
	var cost: int = Sim.CYCLES[idx]
	round_cycles += cost
	scan_zone.end_scan(found, slot)
	var top: Vector2 = scan_zone.center() + Vector2(0, -40)

	if found:
		sim.touch(idx, target)
		scan_zone.set_slots(sim.slots[idx], sim.lru_slot(idx))
		pipeline[idx] = 3
		hit_level = idx
		fx.popup(top, "HIT!", Style.GREEN, 24)
		fx.burst(scan_zone.center(), Style.GREEN)
		hud.toast(
			"HIT em %s" % scan_zone.memory_name,
			"Tag %s encontrada (+%s ciclos).\nO dado volta à CPU e é copiado para os níveis mais rápidos..." % [Style.hex(target), Style.fmt(cost)],
			Style.GREEN)
		_begin_return()
	else:
		pipeline[idx] = 2
		bus.set_link_state(idx, bus.LINK_MISS)
		next_level = idx + 1
		pipeline[next_level] = 1
		bus.active_link = next_level
		_update_next_marker()
		fx.popup(top, "MISS", Style.RED, 22)
		hud.toast(
			"MISS em %s" % scan_zone.memory_name,
			"Tag %s não está aqui (+%s ciclos perdidos).\nA requisição desce para %s, que é maior porém mais lento." % [Style.hex(target), Style.fmt(cost), Sim.NAMES[next_level]],
			Style.RED)
		phase = Phase.WAITING


func _begin_return() -> void:
	ret_steps.clear()
	ret_filled.clear()
	ret_evicted.clear()
	for j in range(hit_level - 1, -2, -1):
		ret_steps.append(j)
	phase = Phase.RETURNING
	_start_return_step()


func _start_return_step() -> void:
	var j: int = ret_steps[0]
	ret_timer = 0.0
	var link: int = j + 1
	var pts: PackedVector2Array = bus.link_points(link)
	var rev := PackedVector2Array()
	for i in range(pts.size() - 1, -1, -1):
		rev.append(pts[i])
	fx.send(rev, RETURN_STEP, Style.GREEN, Style.hex(target), true)
	bus.set_link_state(link, bus.LINK_RETURN)
	bus.active_link = -1


func _finish_return_step() -> void:
	var j: int = ret_steps.pop_front()
	if j >= 0:
		var res: Dictionary = sim.fill(j, target)
		var z = zones[j]
		z.set_slots(sim.slots[j], sim.lru_slot(j))
		if int(res["slot"]) >= 0:
			z.pulse_slot(int(res["slot"]), Style.CYAN, 1.1)
		z.flash(Style.CYAN, 0.7)
		ret_filled.append(Sim.SHORT[j])
		if int(res["evicted"]) >= 0:
			z.ghost(int(res["slot"]), int(res["evicted"]))
			ret_evicted.append("%s removeu %s" % [Sim.SHORT[j], Style.hex(int(res["evicted"]))])
			fx.popup(z.center() + Vector2(0, -40), "LRU saiu: %s" % Style.hex(int(res["evicted"])), Style.ORANGE, 14)
		else:
			fx.popup(z.center() + Vector2(0, -40), "cópia %s" % Style.hex(target), Style.CYAN, 14)
	else:
		bus.cpu_state = 1
		fx.ring(bus.cpu_center(), Style.GREEN)
		fx.burst(bus.cpu_center(), Style.GREEN, 18)

	if ret_steps.is_empty():
		_enter_summary()
	else:
		_start_return_step()


func _enter_summary() -> void:
	phase = Phase.SUMMARY
	timer = 0.0
	rounds_done += 1
	var zone = zones[hit_level]

	var mult: int = get_multiplier()
	var gained: int = (int(zone.points) + calculate_time_bonus()) * mult
	score += gained

	var cache_hit: bool = hit_level <= 3
	if cache_hit:
		cache_hits += 1
		streak += 1
		best_streak = maxi(best_streak, streak)
	else:
		cache_misses += 1
		streak = 0
	total_cycles += round_cycles
	if hit_level == Sim.SSD:
		storage_cycles += Sim.CYCLES[Sim.SSD]

	var title: String = "CACHE HIT em %s" % zone.memory_name
	var col: Color = Style.GREEN
	if hit_level == 4:
		title = "ACESSO À RAM · todas as caches deram miss"
		col = Style.AMBER
	elif hit_level == 5:
		title = "ACESSO AO ARMAZENAMENTO · o mais lento de todos"
		col = Style.ORANGE
	elif hit_level == 0:
		title = "HIT NO REGISTRADOR · o melhor caso possível"

	var line1: String = "%s achado em %s · %s ciclos no total (o ideal seria 1)  ·  +%d pts%s" % [
		Style.hex(target), zone.memory_name, Style.fmt(round_cycles), gained,
		"  (×%d)" % mult if mult > 1 else ""]

	var line2: String = ""
	if hit_level == 0:
		line2 = "Já estava no registrador: nenhum nível precisou ser copiado."
	else:
		line2 = "Copiado para: %s." % ", ".join(ret_filled)
		if not ret_evicted.is_empty():
			line2 += "  LRU: " + "; ".join(ret_evicted) + "."
	hud.toast(title, line1 + "\n" + line2 + "\n" + get_learning_message(zone.memory_name), col, SUMMARY_TIME)


func _after_summary() -> void:
	if total_rounds > 0 and rounds_done >= total_rounds:
		_finish()
	else:
		start_round()


func _finish() -> void:
	phase = Phase.OVER
	hud.clear_toast()
	var rate: float = float(cache_hits) / float(maxi(rounds_done, 1))
	var avg: int = int(float(total_cycles) / float(maxi(rounds_done, 1)))
	var grade: String = "C"
	if rate >= 0.85:
		grade = "S"
	elif rate >= 0.70:
		grade = "A"
	elif rate >= 0.50:
		grade = "B"
	var ssd_pct: int = 0
	if total_cycles > 0:
		ssd_pct = int(round(100.0 * float(storage_cycles) / float(total_cycles)))
	var insight: String = "Dados reutilizados ficaram nas caches e foram servidos em poucos ciclos (localidade temporal).\n"
	if ssd_pct >= 50:
		insight += "Apenas os acessos ao armazenamento consumiram %d%% de todos os ciclos: um único miss\nali custa mais que centenas de hits em L1. Por isso a hierarquia existe." % ssd_pct
	else:
		insight += "Acessos ao armazenamento consumiram %d%% dos ciclos. Cada nível a mais que a CPU\nprecisa descer custa muito mais caro que o anterior." % ssd_pct
	hud.over_data = {
		"score": score, "hit_rate": rate, "best_streak": best_streak,
		"avg_cycles": avg, "grade": grade, "insight": insight,
	}
	hud.over = true


func _restart() -> void:
	sim.reset()
	round_no = 0
	rounds_done = 0
	total_cycles = 0
	storage_cycles = 0
	score = 0
	streak = 0
	best_streak = 0
	cache_hits = 0
	cache_misses = 0
	hud.over = false
	start_round()


# ------------------------------------------------------------- frame ----

func _process(delta: float) -> void:
	match phase:
		Phase.WAITING:
			round_time += delta
		Phase.SCANNING:
			round_time += delta
			timer += delta
			var dur: float = SCAN_TIME[scan_zone.memory_index]
			scan_zone.set_scan_progress(clampf((timer - REQUEST_TRAVEL) / dur, 0.0, 1.0))
			if timer >= REQUEST_TRAVEL + dur:
				_resolve_lookup()
		Phase.RETURNING:
			ret_timer += delta
			if ret_timer >= RETURN_STEP:
				_finish_return_step()
		Phase.SUMMARY:
			timer += delta
			if timer >= SUMMARY_TIME:
				_after_summary()

	if Input.is_action_just_pressed("interact"):
		match phase:
			Phase.WAITING:
				if current_zone != null:
					_try_lookup(current_zone)
			Phase.SUMMARY:
				if timer > 0.7:
					_after_summary()
			Phase.OVER:
				_restart()

	_push_hud()


func _push_hud() -> void:
	hud.target_text = Style.hex(target)
	hud.score = score
	hud.streak = streak
	hud.multiplier = get_multiplier()
	hud.hit_rate = -1.0 if rounds_done == 0 else float(cache_hits) / float(rounds_done)
	hud.round_cycles = round_cycles
	hud.round_time = round_time
	hud.round_no = round_no
	hud.total_rounds = total_rounds
	hud.stalled = phase == Phase.WAITING or phase == Phase.SCANNING or phase == Phase.RETURNING and bus.cpu_state == 0
	hud.pipeline = pipeline


func _sync_zones() -> void:
	for i in range(zones.size()):
		zones[i].set_slots(sim.slots[i], sim.lru_slot(i))


func _update_next_marker() -> void:
	for i in range(zones.size()):
		zones[i].is_next = i == next_level


func _on_zone_entered(zone) -> void:
	current_zone = zone


func _on_zone_exited(zone) -> void:
	if current_zone == zone:
		current_zone = null


# ----------------------------------------------------------- pontuação ----

func calculate_time_bonus() -> int:
	if round_time <= 5.0:
		return 50
	elif round_time <= 8.0:
		return 25
	elif round_time <= 12.0:
		return 10
	return 0


func get_multiplier() -> int:
	if streak >= 10:
		return 5
	elif streak >= 5:
		return 3
	elif streak >= 3:
		return 2
	return 1


func get_learning_message(zone_name: String) -> String:
	match zone_name:
		"REGISTRADORES":
			return "Registradores ficam dentro da CPU: é o acesso mais rápido, mas guardam pouquíssimos dados."
		"CACHE L1":
			return "Localidade temporal: o que foi usado há pouco tende a ser usado de novo. Por isso ele fica na L1."
		"CACHE L2":
			return "A L2 é maior que a L1, porém mais lenta. Ao dar hit aqui, o dado sobe para L1 e registrador."
		"CACHE L3":
			return "A L3 costuma ser compartilhada entre os núcleos. É a última barreira antes da RAM."
		"RAM":
			return "A RAM guarda os programas em execução. Cerca de 50x mais lenta que a L1."
		"ARMAZENAMENTO":
			return "SSD/HD tem enorme capacidade, mas é milhares de vezes mais lento: evite chegar até aqui."
		_:
			return ""


# --------------------------------------------------------------- UI ----

func _style_back_button() -> void:
	var normal := Style.box(Color(0.04, 0.08, 0.11, 0.92), Color(Style.CYAN, 0.5), 8, 1)
	var hover := Style.box(Color(0.08, 0.2, 0.26, 0.98), Color(Style.CYAN, 1.0), 8, 2)
	back_button.add_theme_stylebox_override("normal", normal)
	back_button.add_theme_stylebox_override("hover", hover)
	back_button.add_theme_stylebox_override("pressed", hover)
	back_button.add_theme_stylebox_override("focus", normal)
	back_button.add_theme_color_override("font_color", Style.TEXT)
	back_button.add_theme_color_override("font_hover_color", Color.WHITE)
	back_button.add_theme_font_size_override("font_size", 13)


func _on_botao_voltar_pressed() -> void:
	GameManager.voltar_laboratorio()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		GameManager.voltar_laboratorio()
