extends Control
## Cache Rush V2 — simulação didática de busca hierárquica, com política LRU.
## Projeto sem assets externos: toda a interface é desenhada com CanvasItem.
## Valores de latência são números ilustrativos, NÃO benchmarks reais.

@export_file("*.tscn") var laboratory_scene: String = ""

const VW: float = 1440.0
const VH: float = 810.0
const TOTAL_REQUESTS: int = 12
const MAX_LEVELS: int = 5
const PROBE_DURATION: float = 0.62
const RETURN_DURATION: float = 0.90
const CARD_X: Array[float] = [346.0, 560.0, 774.0, 988.0, 1202.0]
const CARD_Y: float = 240.0
const CARD_W: float = 194.0
const CARD_H: float = 355.0
const LEVEL_NAMES: Array[String] = ["CACHE L1", "CACHE L2", "CACHE L3", "MEMÓRIA RAM", "SSD / DISCO"]
const LEVEL_SHORT: Array[String] = ["L1", "L2", "L3", "RAM", "SSD"]
const CAPACITIES: Array[int] = [3, 6, 10, 16, 32]
const LATENCIES: Array[int] = [1, 4, 12, 70, 220]
const LEVEL_COLORS: Array[Color] = [Color("4ce9d4"), Color("57aeff"), Color("a38bff"), Color("ffc66b"), Color("ff8a65")]
const REQUESTS: Array[int] = [7, 15, 9, 12, 24, 7, 25, 12, 2, 9, 24, 7]
const COL_BG: Color = Color("07111f")
const COL_PANEL: Color = Color("101e31")
const COL_BORDER: Color = Color("2a405b")
const COL_TEXT: Color = Color("e9f5ff")
const COL_MUTE: Color = Color("92a7c1")
const COL_GOOD: Color = Color("5bf0aa")
const COL_BAD: Color = Color("ff7188")
const PHASE_CHOOSE: int = 0
const PHASE_PROBE: int = 1
const PHASE_RETURN: int = 2
const PHASE_RESULT: int = 3
const PHASE_END: int = 4

var font_main: Font
var style_cache: Dictionary = {} # Evita recriar centenas de StyleBoxFlat por segundo.
var memories: Array = [] # Índices 0..3: L1, L2, L3, RAM. Cada array está ordenado MRU -> LRU.
var request_number: int = 0
var address: int = 0
var predicted_level: int = -1
var actual_level: int = -1
var phase: int = PHASE_CHOOSE
var probe_index: int = 0
var visited_index: int = -1
var phase_clock: float = 0.0
var pulse_clock: float = 0.0
var hover_index: int = -1
var correct: int = 0
var score: int = 0
var cache_hits: int = 0
var accesses: int = 0
var accumulated_latency: int = 0
var last_evictions: Array[String] = []
var message_title: String = "ESCOLHA O DESTINO DA BUSCA"
var message_detail: String = "Preveja o PRIMEIRO nível que contém o endereço solicitado."
var message_extra: String = "A CPU pesquisa L1 → L2 → L3 → RAM → SSD, nesta ordem."

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	font_main = get_theme_default_font()
	if font_main == null:
		font_main = ThemeDB.fallback_font
	set_process(true)
	reset_game()

func reset_game() -> void:
	# L1 ⊆ L2 ⊆ L3 ⊆ RAM ⊆ SSD: configuração didática inclusiva.
	memories = [
		[7, 3, 11],
		[7, 3, 11, 15, 2, 5],
		[7, 3, 11, 15, 2, 5, 9, 14, 0, 18],
		[7, 3, 11, 15, 2, 5, 9, 14, 0, 18, 12, 1, 4, 6, 8, 16]
	]
	request_number = 0
	correct = 0
	score = 0
	cache_hits = 0
	accesses = 0
	accumulated_latency = 0
	last_evictions.clear()
	_prepare_request()
	queue_redraw()

func _prepare_request() -> void:
	if request_number >= TOTAL_REQUESTS:
		phase = PHASE_END
		message_title = "SIMULAÇÃO FINALIZADA"
		message_detail = "Você completou %d buscas e acertou %d previsões." % [TOTAL_REQUESTS, correct]
		message_extra = "Reinicie para tentar melhorar seu resultado e observar o efeito da LRU."
		queue_redraw()
		return
	address = REQUESTS[request_number]
	predicted_level = -1
	actual_level = _find_first_hit(address)
	probe_index = 0
	visited_index = -1
	phase_clock = 0.0
	phase = PHASE_CHOOSE
	message_title = "REQUISIÇÃO %02d · O QUE ACONTECERÁ?" % (request_number + 1)
	message_detail = "A CPU pediu o bloco %s (dado %s)." % [_hex(address), _binary(_data_value(address))]
	message_extra = "Clique no primeiro nível onde ele será encontrado."
	queue_redraw()

func _find_first_hit(block: int) -> int:
	for i in range(4):
		if block in memories[i]:
			return i
	return 4 # Todos os blocos 0x00 a 0x1F existem no SSD do simulador.

func _choose(level: int) -> void:
	if phase != PHASE_CHOOSE:
		return
	predicted_level = level
	probe_index = 0
	visited_index = -1
	phase_clock = 0.0
	phase = PHASE_PROBE
	message_title = "BUSCANDO NA HIERARQUIA DE MEMÓRIA"
	message_detail = "A CPU está pesquisando cada camada, da mais rápida à mais lenta."
	message_extra = "O pacote iluminado mostra por onde a requisição está passando."
	queue_redraw()

func _process(delta: float) -> void:
	pulse_clock += delta
	if phase == PHASE_PROBE:
		phase_clock += delta
		if phase_clock >= PROBE_DURATION:
			visited_index = probe_index
			phase_clock = 0.0
			if probe_index == actual_level:
				phase = PHASE_RETURN
				message_title = "CACHE HIT!" if actual_level < 3 else "DADO LOCALIZADO"
				message_detail = "Encontrado em %s. O dado agora retorna à CPU." % LEVEL_SHORT[actual_level]
				message_extra = "O bloco será colocado nos níveis mais rápidos para os próximos acessos."
			else:
				probe_index += 1
	elif phase == PHASE_RETURN:
		phase_clock += delta
		if phase_clock >= RETURN_DURATION:
			_complete_request()
	queue_redraw()

func _complete_request() -> void:
	phase_clock = 0.0
	accesses += 1
	accumulated_latency += LATENCIES[actual_level]
	if actual_level < 3:
		cache_hits += 1
	var guessed_correctly: bool = predicted_level == actual_level
	if guessed_correctly:
		correct += 1
		score += 100
	last_evictions = _promote_to_cpu(address)
	var outcome: String = "PREVISÃO CORRETA" if guessed_correctly else "PREVISÃO INCORRETA"
	var category: String = "CACHE HIT" if actual_level < 3 else "CACHE MISS"
	message_title = "%s  ·  %s EM %s" % [outcome, category, LEVEL_SHORT[actual_level]]
	message_detail = "Busca em %s: %d ciclos didáticos. Dado %s entregue aos registradores." % [LEVEL_SHORT[actual_level], LATENCIES[actual_level], _binary(_data_value(address))]
	if last_evictions.is_empty():
		message_extra = "Bloco promovido / atualizado em L1, L2, L3 e RAM (política LRU)."
	else:
		message_extra = "Substituições LRU: %s" % ", ".join(last_evictions)
	phase = PHASE_RESULT

func _promote_to_cpu(block: int) -> Array[String]:
	var evictions: Array[String] = []
	# Em toda leitura, atualizamos o LRU de TODOS os níveis inclusivos.
	for tier in range(4):
		var storage: Array = memories[tier]
		if storage.has(block):
			storage.erase(block)
		storage.push_front(block)
		if storage.size() > CAPACITIES[tier]:
			var removed: int = int(storage.pop_back())
			evictions.append("%s removeu %s" % [LEVEL_SHORT[tier], _hex(removed)])
	return evictions

func _hex(value: int) -> String:
	return "0x%02X" % value

func _binary(value: int) -> String:
	var output: String = ""
	for bit in range(7, -1, -1):
		output += "1" if ((value >> bit) & 1) != 0 else "0"
	return output

func _data_value(block: int) -> int:
	return (block * 37 + 94) % 256

func _scale_and_offset() -> Array:
	var s: float = minf(size.x / VW, size.y / VH)
	return [s, (size - Vector2(VW, VH) * s) * 0.5]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var coords: Array = _scale_and_offset()
		var p: Vector2 = (event.position - coords[1]) / maxf(float(coords[0]), 0.001)
		hover_index = -1
		for i in MAX_LEVELS:
			if Rect2(CARD_X[i], CARD_Y, CARD_W, CARD_H).has_point(p):
				hover_index = i
				break
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var coords: Array = _scale_and_offset()
			var p: Vector2 = (event.position - coords[1]) / maxf(float(coords[0]), 0.001)
			for i in MAX_LEVELS:
				if Rect2(CARD_X[i], CARD_Y, CARD_W, CARD_H).has_point(p):
					_choose(i)
					accept_event()
					return
			if Rect2(1016, 714, 174, 54).has_point(p):
				reset_game()
				accept_event()
				return
			if Rect2(1202, 714, 196, 54).has_point(p):
				if phase == PHASE_RESULT:
					request_number += 1
					_prepare_request()
				elif phase == PHASE_END:
					reset_game()
				accept_event()
				return
			if laboratory_scene != "" and Rect2(1220, 24, 176, 40).has_point(p):
				if ResourceLoader.exists(laboratory_scene):
					get_tree().change_scene_to_file(laboratory_scene)
				accept_event()
				return

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		_choose(int(event.keycode - KEY_1))
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		if phase == PHASE_RESULT:
			request_number += 1
			_prepare_request()
		elif phase == PHASE_END:
			reset_game()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_R:
		reset_game()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COL_BG)
	var placement: Array = _scale_and_offset()
	draw_set_transform(placement[1], 0.0, Vector2.ONE * float(placement[0]))
	_draw_background()
	_draw_header()
	_draw_request()
	_draw_bus()
	_draw_cpu()
	for i in MAX_LEVELS:
		_draw_level_card(i)
	_draw_packet()
	_draw_footer()
	if phase == PHASE_END:
		_draw_end_overlay()

func _box(r: Rect2, fill: Color, border: Color = Color.TRANSPARENT, radius: int = 12, line: int = 1) -> void:
	var key: String = "%s|%s|%d|%d" % [fill.to_html(), border.to_html(), radius, line]
	if not style_cache.has(key):
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = border
		style.set_border_width_all(line if border.a > 0.0 else 0)
		style.set_corner_radius_all(radius)
		style.anti_aliasing = true
		style_cache[key] = style
	draw_style_box(style_cache[key], r)

func _text(s: String, x: float, y: float, sz: int = 16, color: Color = COL_TEXT) -> void:
	draw_string(font_main, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, sz, color)

func _center(s: String, cx: float, y: float, sz: int = 16, color: Color = COL_TEXT) -> void:
	var w: float = font_main.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, sz).x
	_text(s, cx - w * 0.5, y, sz, color)

func _draw_background() -> void:
	# Grade de microcircuitos e pontos de referência.
	for x in range(0, 1441, 42):
		draw_line(Vector2(x, 0), Vector2(x, VH), Color("11203388"), 1.0)
	for y in range(0, 811, 42):
		draw_line(Vector2(0, y), Vector2(VW, y), Color("11203388"), 1.0)
	for x in range(28, 1440, 84):
		for y in range(22, 810, 84):
			draw_circle(Vector2(x, y), 1.3, Color("24435d"))
	_box(Rect2(14, 12, 1412, 786), Color("091627ef"), Color("2c5366"), 20)

func _draw_header() -> void:
	_box(Rect2(26, 22, 1388, 90), Color("14243a"), COL_BORDER, 16)
	_box(Rect2(42, 38, 48, 56), Color("143f53"), Color("42d9e6"), 12)
	_chip_icon(Vector2(66, 66), Color("4ce9d4"), 0.65)
	_text("CACHE RUSH", 105, 63, 27, COL_TEXT)
	_text("//  MEMORY PIPELINE", 302, 63, 17, Color("4ce9d4"))
	_text("LABORATÓRIO DE ARQUITETURA  ·  SIMULADOR DE HIERARQUIA", 107, 91, 12, COL_MUTE)
	_stat(692, "PONTOS", str(score), Color("ffcd76"))
	_stat(833, "PREVISÕES", "%d/%d" % [correct, accesses], Color("66e8ac"))
	_stat(980, "HITS L1–L3", str(cache_hits), Color("68c9ff"))
	_stat(1117, "LATÊNCIA MÉDIA", "%d c" % (int(round(float(accumulated_latency) / float(maxi(accesses, 1))))), Color("b3a5ff"))
	if laboratory_scene != "":
		_box(Rect2(1220, 33, 176, 42), Color("19334a"), Color("42728a"), 8)
		_center("← LABORATÓRIO", 1308, 59, 14, COL_TEXT)

func _stat(x: float, label: String, value: String, accent: Color) -> void:
	_text(label, x, 53, 12, COL_MUTE)
	_text(value, x, 86, 25, accent)

func _draw_request() -> void:
	_box(Rect2(26, 127, 1388, 77), Color("12283a"), Color("265974"), 14)
	_text("REQUISIÇÃO", 49, 159, 13, COL_MUTE)
	_text("%02d / %02d" % [mini(request_number + 1, TOTAL_REQUESTS), TOTAL_REQUESTS], 49, 188, 24, Color("ebf9ff"))
	_box(Rect2(215, 143, 177, 48), Color("073e4e"), Color("48d1e1"), 9)
	_center("END. " + _hex(address), 304, 173, 20, Color("79fff3"))
	_text("DADO (8 BITS)", 415, 156, 12, COL_MUTE)
	_text(_binary(_data_value(address)), 413, 187, 25, Color("f1d28a"))
	_text("OBJETIVO", 735, 155, 12, COL_MUTE)
	_text("Descubra em qual camada ocorrerá o PRIMEIRO HIT.", 735, 185, 19, COL_TEXT)

func _draw_bus() -> void:
	_box(Rect2(28, 218, 1382, 391), Color("0b1b2c"), Color("243951"), 17)
	for i in range(8):
		var y: float = 412 + i * 6.0
		draw_line(Vector2(274, y), Vector2(1394, y), Color("14435a"), 2.0)
	# Movimento contínuo de pulsos digitais no barramento.
	for j in range(19):
		var px: float = 324 + fposmod(float(j) * 61.0 + pulse_clock * 20.0, 1060.0)
		draw_rect(Rect2(px, 421, 7, 14), Color("348ea383"))
	_text("BARRAMENTO  ·  DADOS / ENDEREÇOS / CONTROLE", 341, 231, 11, Color("64b3c8"))
	for j in range(5):
		var start: float = 318.0 if j == 0 else CARD_X[j - 1] + CARD_W
		var end: float = CARD_X[j]
		draw_line(Vector2(start, 424), Vector2(end, 424), Color("48d1df"), 3.0, true)
		draw_line(Vector2(start, 438), Vector2(end, 438), Color("2c7e99"), 1.0, true)

func _chip_icon(center_pt: Vector2, c: Color, scale_factor: float = 1.0) -> void:
	var r: Rect2 = Rect2(center_pt - Vector2(18, 18) * scale_factor, Vector2(36, 36) * scale_factor)
	_box(r, Color("12384b"), c, 5)
	for i in range(4):
		var pin_x: float = r.position.x + (i + 1) * r.size.x / 5.0
		draw_line(Vector2(pin_x, r.position.y - 7.0 * scale_factor), Vector2(pin_x, r.position.y), c, 2)
		draw_line(Vector2(pin_x, r.end.y), Vector2(pin_x, r.end.y + 7.0 * scale_factor), c, 2)
	for i in range(3):
		var pin_y: float = r.position.y + (i + 1) * r.size.y / 4.0
		draw_line(Vector2(r.position.x - 7.0 * scale_factor, pin_y), Vector2(r.position.x, pin_y), c, 2)
		draw_line(Vector2(r.end.x, pin_y), Vector2(r.end.x + 7.0 * scale_factor, pin_y), c, 2)
	draw_rect(Rect2(r.position + r.size * 0.33, r.size * 0.34), c)

func _draw_cpu() -> void:
	_box(Rect2(43, 244, 274, 340), Color("13283b"), Color("3b7c9a"), 16, 2)
	_text("01  /  PROCESSADOR", 63, 272, 12, Color("6daabe"))
	_center("CPU CORE", 180, 312, 25, COL_TEXT)
	for i in range(9):
		var ix: float = 74.0 + i * 25.5
		draw_line(Vector2(ix, 338), Vector2(ix, 346), Color("78bbd6"), 3.0)
		draw_line(Vector2(ix, 487), Vector2(ix, 494), Color("78bbd6"), 3.0)
	_box(Rect2(66, 349, 226, 136), Color("103b50"), Color("56b9cf"), 9, 2)
	_box(Rect2(80, 364, 101, 45), Color("16546b"), Color("4dd7e0"), 5)
	_center("ULA", 130, 395, 18, COL_TEXT)
	_box(Rect2(190, 364, 88, 45), Color("16475c"), Color("369ebc"), 5)
	_center("UC", 234, 395, 18, COL_TEXT)
	_box(Rect2(80, 418, 198, 50), Color("103044"), Color("39819c"), 6)
	_center("REGISTRADORES", 179, 438, 12, COL_MUTE)
	if accesses > 0:
		_center(_binary(_data_value(REQUESTS[accesses - 1])), 179, 459, 16, Color("74fff0"))
	else:
		_center("--------", 179, 459, 16, COL_MUTE)
	_center("REQUISIÇÃO →", 176, 531, 17, Color("69e6dc"))
	_center("LER  " + _hex(address), 176, 557, 20, COL_TEXT)
	_text("Buscas começam na L1; só avançam após um MISS.", 51, 601, 13, COL_MUTE)

func _draw_level_card(index: int) -> void:
	var x: float = CARD_X[index]
	var c: Color = LEVEL_COLORS[index]
	var active: bool = phase == PHASE_PROBE and probe_index == index
	var found: bool = (phase == PHASE_RETURN or phase == PHASE_RESULT) and actual_level == index
	var completed_miss: bool = (phase == PHASE_PROBE and visited_index >= index and actual_level != index) or ((phase == PHASE_RETURN or phase == PHASE_RESULT) and index < actual_level)
	var over: bool = hover_index == index and phase == PHASE_CHOOSE
	var border: Color = c if active or found or over else Color("324e65")
	var fill: Color = Color("172c42") if active or over or found else Color("122235")
	if found:
		border = COL_GOOD
	_box(Rect2(x, CARD_Y, CARD_W, CARD_H), fill, border, 14, 3 if active or found or over else 1)
	_box(Rect2(x + 10, CARD_Y + 10, CARD_W - 20, 57), Color(c.r * 0.17, c.g * 0.17, c.b * 0.17, 1), Color.TRANSPARENT, 9)
	_center(LEVEL_NAMES[index], x + CARD_W * 0.5, 273, 17, c)
	_center("%d ciclos  ·  %d blocos" % [LATENCIES[index], CAPACITIES[index]], x + CARD_W * 0.5, 297, 12, COL_TEXT)
	_text("CONTEÚDO (MRU → LRU)", x + 15, 334, 11, COL_MUTE)
	var storage: Array = memories[index] if index < 4 else []
	if index == 4:
		# O SSD contém todos os 32 endereços (0x00..0x1F).
		_center("00  01  02  ...", x + CARD_W * 0.5, 375, 16, COL_TEXT)
		_center("0F  10  11  ...", x + CARD_W * 0.5, 412, 16, COL_TEXT)
		_center("1D  1E  1F", x + CARD_W * 0.5, 449, 16, COL_TEXT)
		_text("32 BLOCOS PERSISTENTES", x + 15, 466, 10, COL_MUTE)
	else:
		# Todos os TAGs são visíveis: o exercício depende de observar a memória,
		# e não de adivinhar blocos ocultos.
		for n in range(storage.size()):
			var col_index: int = n % 4
			var row_index: int = int(n / 4)
			var chip_x: float = x + 14 + float(col_index) * 42.0
			var chip_y: float = 349 + float(row_index) * 30.0
			var is_request: bool = int(storage[n]) == address
			_box(Rect2(chip_x, chip_y, 38, 25), Color("204654") if is_request else Color("1b3548"), Color("59d4d1") if is_request else Color("3c6179"), 5)
			_center(_hex(int(storage[n])).substr(2), chip_x + 19, chip_y + 17, 13, Color("74f5e0") if is_request else COL_TEXT)
		_text("%d / %d BLOCOS" % [storage.size(), CAPACITIES[index]], x + 15, 468, 11, COL_MUTE)
	draw_line(Vector2(x + 12, 474), Vector2(x + CARD_W - 12, 474), Color("31495e"), 1.0)
	var indicator: String = "1–5: SELECIONE"
	var badge_c: Color = Color("2c6f8b")
	if active:
		indicator = "PROCURANDO..."
		badge_c = c
	elif found:
		indicator = "HIT ✓"
		badge_c = COL_GOOD
	elif completed_miss:
		indicator = "MISS ✕"
		badge_c = COL_BAD
	elif phase == PHASE_CHOOSE and over:
		indicator = "CLIQUE PARA PREVER"
		badge_c = c
	elif phase == PHASE_PROBE or phase == PHASE_RETURN:
		indicator = "AGUARDANDO"
	elif phase == PHASE_RESULT:
		indicator = "NÃO CONSULTADO"
	_box(Rect2(x + 14, 494, CARD_W - 28, 40), Color(badge_c.r * 0.16, badge_c.g * 0.18, badge_c.b * 0.18, 1.0), badge_c, 7)
	_center(indicator, x + CARD_W * 0.5, 521, 14, badge_c)
	_center("[%d] %s" % [index + 1, LEVEL_SHORT[index]], x + CARD_W * 0.5, 561, 18, COL_TEXT)
	_center("↓ MAIS LENTO / MAIOR" if index < 4 else "MEMÓRIA NÃO VOLÁTIL", x + CARD_W * 0.5, 582, 10, COL_MUTE)

func _draw_packet() -> void:
	if phase != PHASE_PROBE and phase != PHASE_RETURN:
		return
	var start: Vector2 = Vector2(290, 430)
	var p: Vector2 = Vector2.ZERO
	var end: Vector2 = Vector2(0, 430)
	if phase == PHASE_PROBE:
		if probe_index > 0:
			start = Vector2(CARD_X[probe_index - 1] + CARD_W * 0.5, 430)
		end = Vector2(CARD_X[probe_index] + CARD_W * 0.5, 430)
		p = start.lerp(end, clampf(phase_clock / PROBE_DURATION, 0.0, 1.0))
	else:
		start = Vector2(CARD_X[actual_level] + CARD_W * 0.5, 430)
		end = Vector2(270, 430)
		p = start.lerp(end, clampf(phase_clock / RETURN_DURATION, 0.0, 1.0))
	var aura: Color = Color("6afbf1") if phase == PHASE_PROBE else Color("fbd37a")
	draw_circle(p, 26.0, Color(aura.r, aura.g, aura.b, 0.13))
	draw_circle(p, 16.0, Color(aura.r, aura.g, aura.b, 0.32))
	_box(Rect2(p.x - 23, p.y - 12, 46, 24), Color("102f43"), aura, 6, 2)
	_center("%02X" % address, p.x, p.y + 5, 13, aura)

func _draw_footer() -> void:
	_box(Rect2(26, 625, 1388, 160), Color("122236"), COL_BORDER, 15)
	var accent: Color = Color("5ff1e0")
	if phase == PHASE_RESULT:
		accent = COL_GOOD if predicted_level == actual_level else COL_BAD
	_box(Rect2(43, 641, 6, 82), accent, Color.TRANSPARENT, 3)
	_text(message_title, 65, 669, 20, accent)
	_text(message_detail, 65, 698, 15, COL_TEXT)
	_text(message_extra, 65, 723, 13, COL_MUTE)
	_text("TECLAS 1–5: prever  ·  ESPAÇO: avançar  ·  R: reiniciar", 48, 759, 12, Color("7895ad"))
	_box(Rect2(1016, 714, 174, 54), Color("1d344a"), Color("4a667f"), 11)
	_center("↺  REINICIAR", 1103, 748, 16, COL_TEXT)
	var next_ok: bool = phase == PHASE_RESULT or phase == PHASE_END
	var next_c: Color = Color("42dbc7") if next_ok else Color("315061")
	_box(Rect2(1202, 714, 196, 54), Color("174a52") if next_ok else Color("1a2e41"), next_c, 11, 2)
	_center("PRÓXIMA  →" if phase == PHASE_RESULT else ("JOGAR DE NOVO" if phase == PHASE_END else "AGUARDE"), 1300, 748, 16, next_c)
	if phase == PHASE_CHOOSE:
		_text("Clique em um cartão para iniciar a simulação da busca.", 749, 664, 13, Color("82c5de"))
	elif phase == PHASE_PROBE:
		_text("PASSO %d/%d" % [probe_index + 1, actual_level + 1], 854, 665, 14, Color("8dded7"))
	elif phase == PHASE_RETURN:
		_text("RETORNO DE DADOS", 826, 665, 14, Color("f1cb7b"))

func _draw_end_overlay() -> void:
	# Janela de fim sem perder a visibilidade da arquitetura abaixo.
	draw_rect(Rect2(22, 215, 1396, 397), Color("04101dd4"))
	_box(Rect2(417, 260, 606, 306), Color("182a41"), Color("62dccc"), 22, 2)
	_center("MISSÃO CONCLUÍDA", 720, 314, 31, Color("78f8e5"))
	_center("12 REQUISIÇÕES EXECUTADAS", 720, 351, 15, COL_MUTE)
	_box(Rect2(455, 379, 247, 104), Color("12394b"), Color("477d96"), 12)
	_box(Rect2(737, 379, 247, 104), Color("133d3e"), Color("4b957e"), 12)
	_center("PONTUAÇÃO", 578, 414, 14, COL_MUTE)
	_center(str(score), 578, 460, 36, Color("ffd780"))
	_center("PREVISÕES CORRETAS", 861, 414, 14, COL_MUTE)
	_center("%d / %d" % [correct, TOTAL_REQUESTS], 861, 460, 35, Color("6beeb4"))
	_center("Pressione R ou clique em JOGAR DE NOVO para repetir.", 720, 528, 16, COL_TEXT)
