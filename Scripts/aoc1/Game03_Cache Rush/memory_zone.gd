extends Area2D
## Um nível da hierarquia de memória (Registradores, L1, L2, L3, RAM ou SSD).
## Todo o visual é desenhado por código: cartão, ícone, linhas da cache
## (com a tag de cada dado), varredura da busca, hit/miss e substituição LRU.

signal player_entered(zone)
signal player_exited(zone)

const Style = preload("res://Scripts/aoc1/Game03_Cache Rush/cache_style.gd")

@export var memory_name: String = "CACHE L1"
@export var points: int = 100
@export var memory_index: int = 0

@export_category("Text")
@export var subtitle_line_1: String = "Descricao1"
@export var subtitle_line_2: String = "Descricao2"
@export var capacity_text: String = ""

@export_category("Visual")
@export var panel_size: Vector2 = Vector2(280, 112)
@export var panel_color: Color = Color("#56d6ff")

## Preenchidos pelo controlador da fase
var capacity: int = 0
var latency_cycles: int = 1
var slots: Array = []
var lru_slot: int = -1

var player_inside: bool = false
var is_next: bool = false
var busy: bool = false
var scan_progress: float = -1.0
var scan_tag: int = -1
var result: int = 0  # 0 = sem resultado, 1 = miss, 2 = hit
var result_slot: int = -1

var _time: float = 0.0
var _flash: float = 0.0
var _flash_color: Color = Color.WHITE
var _shake: float = 0.0
var _slot_fx: Dictionary = {}
var _ghosts: Array = []

const SLOT_X := 12.0
const SLOT_Y := 68.0
const SLOT_H_AREA := 36.0


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = panel_size
	var col: CollisionShape2D = $CollisionShape2D
	col.shape = shape
	col.position = panel_size * 0.5
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta * 1.6)
	_shake = maxf(0.0, _shake - delta * 3.0)
	for k in _slot_fx.keys():
		_slot_fx[k]["t"] -= delta
		if _slot_fx[k]["t"] <= 0.0:
			_slot_fx.erase(k)
	for i in range(_ghosts.size() - 1, -1, -1):
		_ghosts[i]["t"] -= delta
		if _ghosts[i]["t"] <= 0.0:
			_ghosts.remove_at(i)
	queue_redraw()


# ------------------------------------------------------------------ API ----

func set_slots(tags: Array, lru: int) -> void:
	slots = tags.duplicate()
	lru_slot = lru


func begin_scan(tag: int) -> void:
	busy = true
	scan_tag = tag
	scan_progress = 0.0


func set_scan_progress(p: float) -> void:
	scan_progress = p


func end_scan(found: bool, slot: int) -> void:
	busy = false
	scan_progress = -1.0
	result = 2 if found else 1
	result_slot = slot
	if found:
		flash(Style.GREEN, 1.0)
		if slot >= 0:
			pulse_slot(slot, Style.GREEN, 1.2)
	else:
		flash(Style.RED, 0.8)
		shake()


func pulse_slot(slot: int, color: Color, duration: float = 0.9) -> void:
	_slot_fx[slot] = {"t": duration, "dur": duration, "color": color}


func ghost(slot: int, tag: int) -> void:
	_ghosts.append({"slot": slot, "tag": tag, "t": 1.4})


func flash(color: Color, amount: float = 1.0) -> void:
	_flash = amount
	_flash_color = color


func shake() -> void:
	_shake = 1.0


func reset_round() -> void:
	result = 0
	result_slot = -1
	busy = false
	scan_progress = -1.0
	is_next = false
	_slot_fx.clear()


func center() -> Vector2:
	return global_position + panel_size * 0.5


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		player_entered.emit(self)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
		player_exited.emit(self)


# ----------------------------------------------------------------- draw ----

func _grid_cols() -> int:
	return 4 if capacity <= 4 or capacity == 8 else 6


func _cell_rect(i: int) -> Rect2:
	var cols: int = _grid_cols()
	var rows: int = int(ceil(float(capacity) / float(cols)))
	var gap := 5.0
	var avail: float = panel_size.x - SLOT_X * 2.0
	var cw: float = (avail - gap * (cols - 1)) / cols
	var ch: float = 22.0 if rows == 1 else 16.0
	var total_h: float = rows * ch + (rows - 1) * 4.0
	var y0: float = SLOT_Y + (SLOT_H_AREA - total_h) * 0.5
	var cx: int = i % cols
	var cy: int = i / cols
	return Rect2(SLOT_X + cx * (cw + gap), y0 + cy * (ch + 4.0), cw, ch)


func _draw() -> void:
	var w: float = panel_size.x
	var h: float = panel_size.y
	var c: Color = panel_color
	var pulse: float = 0.5 + 0.5 * sin(_time * 4.0)

	if _shake > 0.0:
		draw_set_transform(Vector2(sin(_time * 70.0) * 5.0 * _shake, 0.0))

	# --- cartão ---
	var glow := Color(0, 0, 0, 0.45)
	var glow_size := 8
	var border := Color(c.r, c.g, c.b, 0.55)
	var fill := Color(0.055, 0.10, 0.135, 0.97)
	if is_next and not busy and result == 0:
		glow = Color(c.r, c.g, c.b, 0.25 + 0.30 * pulse)
		glow_size = 12 + int(6.0 * pulse)
		border = Color(c.r, c.g, c.b, 0.9)
	elif result == 2:
		border = Color(Style.GREEN, 0.85)
	elif result == 1:
		border = Color(Style.RED, 0.75)
	if _flash > 0.0:
		glow = Color(_flash_color.r, _flash_color.g, _flash_color.b, 0.75 * _flash)
		glow_size = 22
		fill = fill.lerp(_flash_color, 0.14 * _flash)
	draw_style_box(Style.box(fill, border, 10, 2, glow, glow_size), Rect2(0, 0, w, h))

	# --- cabeçalho ---
	draw_style_box(Style.box_top(Color(c.r, c.g, c.b, 0.20), 8), Rect2(2, 2, w - 4, 28))
	draw_line(Vector2(2, 30), Vector2(w - 2, 30), Color(c.r, c.g, c.b, 0.35), 1.0)
	_draw_icon(Vector2(9, 4))
	Style.text(self, memory_name, Vector2(42, 21), 16, Color.WHITE, Style.bold())

	# selos: PRÓXIMO / HIT / MISS
	if result == 2:
		_pill("HIT", Style.GREEN, Vector2(w - 12 - 50, 7), 50)
	elif result == 1:
		_pill("MISS", Style.RED, Vector2(w - 12 - 50, 7), 50)
	elif is_next and not busy:
		_pill("PRÓXIMO", c, Vector2(w - 12 - 72, 7), 72, pulse)

	# --- textos ---
	var dim := Color(0.80, 0.94, 1.0, 0.78)
	Style.text(self, subtitle_line_1, Vector2(12, 46), 11, dim)
	Style.text(self, subtitle_line_2, Vector2(12, 60), 11, dim)
	if capacity_text != "":
		Style.text(self, capacity_text, Vector2(w - 12 - 120, 46), 11, Color(c.r, c.g, c.b, 1.0),
				Style.mono(), HORIZONTAL_ALIGNMENT_RIGHT, 120.0)
	var lat: String = "%s ciclo%s" % [Style.fmt(latency_cycles), "" if latency_cycles == 1 else "s"]
	Style.text(self, lat, Vector2(w - 12 - 120, 60), 11, Color(0.8, 0.94, 1.0, 0.9),
			Style.mono(), HORIZONTAL_ALIGNMENT_RIGHT, 120.0)

	# --- linhas da cache ---
	if capacity > 0:
		_draw_slots()
	else:
		_draw_storage_body()

	# --- varredura da busca ---
	if scan_progress >= 0.0 and busy:
		var area_w: float = w - SLOT_X * 2.0
		var bx: float = SLOT_X + area_w * scan_progress
		draw_rect(Rect2(bx - 6, SLOT_Y - 4, 12, SLOT_H_AREA + 8), Color(1, 1, 1, 0.07))
		draw_rect(Rect2(bx - 1, SLOT_Y - 4, 2, SLOT_H_AREA + 8), Color(1, 1, 1, 0.95))
		draw_rect(Rect2(8, h - 6, (w - 16) * scan_progress, 3), Color(c.r, c.g, c.b, 0.95))

	# --- prompt de interação ---
	if player_inside:
		var label := "[E] CONSULTAR"
		var col := Style.CYAN
		if busy:
			label = "COMPARANDO TAG %s" % Style.hex(scan_tag)
			col = Style.AMBER
		elif not is_next:
			label = "AINDA NÃO"
			col = Style.DIM
		var pw: float = Style.text_width(label, 10, Style.bold()) + 22.0
		_pill(label, col, Vector2((w - pw) * 0.5, h - 9), pw)

	draw_set_transform(Vector2.ZERO)


func _pill(label: String, color: Color, pos: Vector2, width: float, pulse: float = 1.0) -> void:
	var bg := Color(0.03, 0.08, 0.11, 0.96)
	var br := Color(color.r, color.g, color.b, 0.55 + 0.45 * pulse)
	draw_style_box(Style.box(bg, br, 9, 1), Rect2(pos, Vector2(width, 18)))
	Style.text(self, label, Vector2(pos.x, pos.y + 13), 10, Color(color.r, color.g, color.b, 0.7 + 0.3 * pulse),
			Style.bold(), HORIZONTAL_ALIGNMENT_CENTER, width)


func _draw_slots() -> void:
	var c: Color = panel_color
	var scan_x: float = -1.0
	if busy and scan_progress >= 0.0:
		scan_x = SLOT_X + (panel_size.x - SLOT_X * 2.0) * scan_progress
	for i in range(capacity):
		var r: Rect2 = _cell_rect(i)
		var tag: int = -1
		if i < slots.size():
			tag = slots[i]
		var filled: bool = tag >= 0
		var bg := Color(0.03, 0.06, 0.09, 0.95)
		var br := Color(c.r, c.g, c.b, 0.18)
		var tc := Color(0.45, 0.58, 0.65, 0.55)
		var label := "--"
		if filled:
			bg = Color(c.r, c.g, c.b, 0.16)
			br = Color(c.r, c.g, c.b, 0.55)
			tc = Color(0.95, 0.99, 1.0, 1.0)
			label = "%02X" % tag
		# varredura: células já comparadas ganham contorno; a atual acende
		if scan_x >= 0.0:
			if scan_x >= r.position.x + r.size.x:
				br = Color(1, 1, 1, 0.45)
			elif scan_x >= r.position.x:
				bg = Color(1, 1, 1, 0.22)
				br = Color(1, 1, 1, 0.95)
		# efeitos pontuais (hit, cópia nova)
		if _slot_fx.has(i):
			var fx: Dictionary = _slot_fx[i]
			var a: float = clampf(float(fx["t"]) / float(fx["dur"]), 0.0, 1.0)
			var fc: Color = fx["color"]
			bg = bg.lerp(Color(fc.r, fc.g, fc.b, 0.75), a)
			br = br.lerp(Color(fc.r, fc.g, fc.b, 1.0), a)
			tc = tc.lerp(Color.WHITE, a)
		draw_style_box(Style.box(bg, br, 4, 1), r)
		Style.text(self, label, Vector2(r.position.x, r.position.y + r.size.y * 0.5 + 4.5), 12, tc,
				Style.mono(), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		# marca de LRU: próxima linha a ser substituída
		if i == lru_slot and filled:
			draw_rect(Rect2(r.position.x + 4, r.position.y + r.size.y - 3, r.size.x - 8, 2), Style.ORANGE)
	# fantasmas de linhas removidas (substituição LRU)
	for g in _ghosts:
		var r2: Rect2 = _cell_rect(int(g["slot"]))
		var a2: float = clampf(float(g["t"]) / 1.4, 0.0, 1.0)
		draw_style_box(Style.box(Color(Style.RED, 0.35 * a2), Color(Style.RED, a2), 4, 1), r2)
		var off := Vector2(0, -10.0 * (1.0 - a2))
		Style.text(self, "%02X" % int(g["tag"]), r2.position + Vector2(0, r2.size.y * 0.5 + 4.5) + off, 12,
				Color(1.0, 0.8, 0.82, a2), Style.mono(), HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)


func _draw_storage_body() -> void:
	var c: Color = panel_color
	var area := Rect2(SLOT_X, SLOT_Y + 2, panel_size.x - SLOT_X * 2.0, SLOT_H_AREA - 4)
	draw_style_box(Style.box(Color(c.r, c.g, c.b, 0.10), Color(c.r, c.g, c.b, 0.45), 4, 1), area)
	# "trilhas" do disco
	for i in range(5):
		var y: float = area.position.y + 5.0 + i * 5.5
		draw_line(Vector2(area.position.x + 6, y), Vector2(area.end.x - 6, y), Color(c.r, c.g, c.b, 0.12), 1.0)
	Style.text(self, "00  01  02  ···  FD  FE  FF", Vector2(area.position.x, area.position.y + 14), 12,
			Color(0.95, 0.99, 1.0, 0.85), Style.mono(), HORIZONTAL_ALIGNMENT_CENTER, area.size.x)
	Style.text(self, "guarda TODOS os endereços", Vector2(area.position.x, area.position.y + 27), 10,
			Color(c.r, c.g, c.b, 0.95), Style.ui(), HORIZONTAL_ALIGNMENT_CENTER, area.size.x)


func _draw_icon(p: Vector2) -> void:
	var c: Color = panel_color
	draw_style_box(Style.box(Color(c.r, c.g, c.b, 0.22), Color(c.r, c.g, c.b, 0.85), 6, 1), Rect2(p, Vector2(24, 24)))
	match memory_index:
		0:
			for ix in range(2):
				for iy in range(2):
					draw_rect(Rect2(p + Vector2(5 + ix * 8, 5 + iy * 8), Vector2(6, 6)), c)
		1, 2, 3:
			for i in range(memory_index):
				draw_rect(Rect2(p + Vector2(5, 17 - i * 6), Vector2(14, 4)), c)
		4:
			draw_rect(Rect2(p + Vector2(3, 6), Vector2(18, 11)), c)
			for i in range(3):
				draw_rect(Rect2(p + Vector2(5 + i * 5.5, 8), Vector2(4, 5)), Color(0.05, 0.1, 0.12))
			for i in range(5):
				draw_rect(Rect2(p + Vector2(4 + i * 3.5, 18), Vector2(2, 3)), c)
		_:
			draw_rect(Rect2(p + Vector2(4, 6), Vector2(16, 12)), c)
			draw_rect(Rect2(p + Vector2(6, 8), Vector2(8, 3)), Color(0.05, 0.1, 0.12))
			draw_circle(p + Vector2(16, 14), 1.8, Color(0.05, 0.1, 0.12))
