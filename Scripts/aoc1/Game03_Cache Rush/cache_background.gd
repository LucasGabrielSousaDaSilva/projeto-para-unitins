extends Node2D
## Cenário do Cache Rush. O mesmo script serve a dois nós:
##  - mode 0 ("Piso"): placa de circuito estática (grade, trilhas, arena, vinheta);
##  - mode 1 ("Barramentos"): chip da CPU e barramentos animados entre os níveis.
##
## Barramento k liga o nó (k-1) ao nó k; o nó -1 é a CPU.
## (Este nó e o FX ficam na origem da cena, então coordenadas locais = globais.)

const Style = preload("res://Scripts/aoc1/Game03_Cache Rush/cache_style.gd")

@export_enum("Piso", "Barramentos") var mode: int = 0

const SCREEN := Vector2(1280, 720)
const CPU_RECT := Rect2(440, 110, 400, 70)

# estados de um barramento
const LINK_IDLE := 0
const LINK_MISS := 1
const LINK_ACTIVE := 2
const LINK_RETURN := 3

var zones: Array = []
var active_link: int = -1
var link_state: Array = [0, 0, 0, 0, 0, 0]
var cpu_req: String = "--"
var cpu_state: int = 0  # 0 = esperando o dado (stall), 1 = dado recebido

var _links: Array = []
var _t: float = 0.0


func _ready() -> void:
	if mode == 0:
		queue_redraw()


func setup(zone_list: Array) -> void:
	zones = zone_list
	_links.clear()
	var cpu_left := Vector2(CPU_RECT.position.x, CPU_RECT.position.y + CPU_RECT.size.y * 0.5)
	var first: Rect2 = _zone_rect(0)
	var reg_top := Vector2(first.get_center().x, first.position.y)
	_links.append(PackedVector2Array([cpu_left, Vector2(reg_top.x, cpu_left.y), reg_top]))
	for k in range(1, zones.size()):
		var a: Rect2 = _zone_rect(k - 1)
		var b: Rect2 = _zone_rect(k)
		var ac: Vector2 = a.get_center()
		var bc: Vector2 = b.get_center()
		var pts := PackedVector2Array()
		if absf(ac.x - bc.x) < 1.0:
			if b.position.y > a.position.y:
				pts = PackedVector2Array([Vector2(ac.x, a.end.y), Vector2(bc.x, b.position.y)])
			else:
				pts = PackedVector2Array([Vector2(ac.x, a.position.y), Vector2(bc.x, b.end.y)])
		else:
			if b.position.x > a.position.x:
				pts = PackedVector2Array([Vector2(a.end.x, ac.y), Vector2(b.position.x, bc.y)])
			else:
				pts = PackedVector2Array([Vector2(a.position.x, ac.y), Vector2(b.end.x, bc.y)])
		_links.append(pts)


func _zone_rect(i: int) -> Rect2:
	var z = zones[i]
	return Rect2(z.global_position, z.panel_size)


func link_points(k: int) -> PackedVector2Array:
	return _links[k]


func cpu_center() -> Vector2:
	return CPU_RECT.get_center()


func reset_links() -> void:
	for i in range(link_state.size()):
		link_state[i] = LINK_IDLE


func set_link_state(k: int, s: int) -> void:
	if k >= 0 and k < link_state.size():
		link_state[k] = s


func _process(delta: float) -> void:
	if mode == 1:
		_t += delta
		queue_redraw()


func _draw() -> void:
	if mode == 0:
		_draw_floor()
	else:
		for k in range(_links.size()):
			_draw_link(k)
		_draw_cpu()


# ------------------------------------------------------------------ piso ----

func _draw_floor() -> void:
	# fundo em degradê
	var top := Color("#082028")
	var bot := Color("#030b0f")
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(SCREEN.x, 0), SCREEN, Vector2(0, SCREEN.y)]),
			PackedColorArray([top, top, bot, bot]))

	# grade fina
	var grid := Color(0.35, 0.85, 0.9, 0.035)
	for x in range(0, int(SCREEN.x) + 1, 32):
		draw_line(Vector2(x, 0), Vector2(x, SCREEN.y), grid, 1.0)
	for y in range(0, int(SCREEN.y) + 1, 32):
		draw_line(Vector2(0, y), Vector2(SCREEN.x, y), grid, 1.0)

	# trilhas de circuito decorativas
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var dirs: Array = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
			Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	for i in range(34):
		var p := Vector2(rng.randi_range(0, 40) * 32, rng.randi_range(0, 22) * 32)
		var pts := PackedVector2Array([p])
		for s in range(rng.randi_range(3, 6)):
			var d: Vector2 = dirs[rng.randi() % dirs.size()]
			p += d * 32.0 * rng.randi_range(1, 4)
			pts.append(p)
		draw_polyline(pts, Color(0.25, 0.85, 0.85, 0.09), 2.0, true)
		draw_arc(pts[0], 4.0, 0.0, TAU, 12, Color(0.25, 0.85, 0.85, 0.20), 1.5, true)
		draw_arc(pts[pts.size() - 1], 4.0, 0.0, TAU, 12, Color(0.25, 0.85, 0.85, 0.20), 1.5, true)

	# arena central (onde o jogador anda)
	var arena := Rect2(330, 196, 620, 426)
	draw_style_box(Style.box(Color(0.04, 0.16, 0.15, 0.50), Color(0.3, 0.85, 0.75, 0.22), 16, 1,
			Color(0.1, 0.8, 0.7, 0.05), 24), arena)
	var inner := arena.grow(-10)
	draw_style_box(Style.box(Color(0, 0, 0, 0), Color(0.3, 0.85, 0.75, 0.08), 12, 1), inner)
	# cantoneiras
	var cc := Color(0.4, 0.95, 0.85, 0.5)
	for corner in [arena.position, Vector2(arena.end.x, arena.position.y),
			Vector2(arena.position.x, arena.end.y), arena.end]:
		var sx: float = 1.0 if corner.x < arena.get_center().x else -1.0
		var sy: float = 1.0 if corner.y < arena.get_center().y else -1.0
		draw_line(corner + Vector2(sx * 4, sy * 4), corner + Vector2(sx * 24, sy * 4), cc, 2.0)
		draw_line(corner + Vector2(sx * 4, sy * 4), corner + Vector2(sx * 4, sy * 24), cc, 2.0)
	Style.text(self, "BARRAMENTO DE DADOS  ·  a requisição desce do mais rápido ao mais lento",
			Vector2(arena.position.x, arena.end.y - 10), 10, Color(0.5, 0.9, 0.85, 0.35),
			Style.ui(), HORIZONTAL_ALIGNMENT_CENTER, arena.size.x)

	# vinheta
	var dark := Color(0, 0, 0, 0.55)
	var clear := Color(0, 0, 0, 0)
	var e := 110.0
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(SCREEN.x, 0), Vector2(SCREEN.x, e), Vector2(0, e)]),
			PackedColorArray([dark, dark, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, SCREEN.y - e), Vector2(SCREEN.x, SCREEN.y - e), SCREEN, Vector2(0, SCREEN.y)]),
			PackedColorArray([clear, clear, dark, dark]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(e, 0), Vector2(e, SCREEN.y), Vector2(0, SCREEN.y)]),
			PackedColorArray([dark, clear, clear, dark]))
	draw_polygon(PackedVector2Array([Vector2(SCREEN.x - e, 0), Vector2(SCREEN.x, 0), SCREEN, Vector2(SCREEN.x - e, SCREEN.y)]),
			PackedColorArray([clear, dark, dark, clear]))


# ----------------------------------------------------------- barramentos ----

func _draw_link(k: int) -> void:
	var pts: PackedVector2Array = _links[k]
	var st: int = link_state[k]
	if k == active_link and st == LINK_IDLE:
		st = LINK_ACTIVE

	var col := Color(0.30, 0.75, 0.85, 0.40)
	var width := 2.0
	match st:
		LINK_MISS:
			col = Color(1.0, 0.42, 0.40, 0.65)
		LINK_ACTIVE:
			col = Color(0.45, 0.95, 1.0, 1.0)
			width = 3.0
		LINK_RETURN:
			col = Color(0.45, 1.0, 0.65, 0.95)
			width = 3.0

	# trilha (fundo)
	draw_polyline(pts, Color("#143846"), 11.0, true)
	draw_polyline(pts, Color("#07151c"), 7.0, true)
	if st == LINK_ACTIVE or st == LINK_RETURN:
		var pulse: float = 0.5 + 0.5 * sin(_t * 5.0)
		draw_polyline(pts, Color(col.r, col.g, col.b, 0.10 + 0.12 * pulse), 12.0, true)
	draw_polyline(pts, col, width, true)

	# setas fluindo no sentido da requisição (ou voltando, quando é retorno de dado)
	var length: float = Style.poly_length(pts)
	var spacing := 34.0
	var speed := 70.0 if st == LINK_ACTIVE else 36.0
	var n: int = int(length / spacing) + 1
	var flow_alpha := 0.9 if (st == LINK_ACTIVE or st == LINK_RETURN) else 0.22
	for i in range(n):
		var d: float = fmod(_t * speed + i * spacing, maxf(length, 1.0))
		if st == LINK_RETURN:
			d = length - d
		var info: Dictionary = Style.point_at(pts, d)
		var dir: Vector2 = info["dir"]
		if st == LINK_RETURN:
			dir = -dir
		_chevron(info["pos"], dir, Color(col.r, col.g, col.b, flow_alpha))

	# ponta de seta no destino
	var end_info: Dictionary = Style.point_at(pts, length)
	var ed: Vector2 = end_info["dir"]
	var ep: Vector2 = end_info["pos"]
	var perp := Vector2(-ed.y, ed.x)
	draw_colored_polygon(PackedVector2Array([ep + ed * 1.0, ep - ed * 11.0 + perp * 7.0, ep - ed * 11.0 - perp * 7.0]),
			Color(col.r, col.g, col.b, 0.9))
	# "porta" na origem
	draw_circle(pts[0], 4.5, Color("#07151c"))
	draw_arc(pts[0], 4.5, 0.0, TAU, 14, col, 1.5, true)


func _chevron(p: Vector2, dir: Vector2, color: Color) -> void:
	var perp := Vector2(-dir.y, dir.x)
	draw_polyline(PackedVector2Array([p - dir * 4.0 + perp * 4.0, p + dir * 2.0, p - dir * 4.0 - perp * 4.0]),
			color, 2.0, true)


func _draw_cpu() -> void:
	var r: Rect2 = CPU_RECT
	var cyan: Color = Style.CYAN
	var pulse: float = 0.5 + 0.5 * sin(_t * 3.0)
	var waiting: bool = cpu_state == 0
	var accent: Color = Style.AMBER if waiting else Style.GREEN

	# pinos do encapsulamento
	var pin := Color(0.78, 0.84, 0.88, 0.55)
	for i in range(18):
		var x: float = r.position.x + 18.0 + i * (r.size.x - 36.0) / 17.0
		draw_rect(Rect2(x - 2, r.position.y - 7, 4, 8), pin)
		draw_rect(Rect2(x - 2, r.end.y - 1, 4, 8), pin)
	for i in range(5):
		var y: float = r.position.y + 12.0 + i * (r.size.y - 24.0) / 4.0
		draw_rect(Rect2(r.position.x - 7, y - 2, 8, 4), pin)
		draw_rect(Rect2(r.end.x - 1, y - 2, 8, 4), pin)

	# corpo
	draw_style_box(Style.box(Color("#0e2a36"), Color(cyan, 0.85), 10, 2,
			Color(cyan.r, cyan.g, cyan.b, 0.18 + 0.12 * pulse), 16), r)
	var die := r.grow(-8)
	draw_style_box(Style.box(Color("#081a22"), Color(cyan, 0.30), 6, 1), die)

	Style.text(self, "CPU CORE", Vector2(r.position.x + 22, r.position.y + 29), 20, Color.WHITE, Style.bold())
	Style.text(self, "Origem das requisições de dados", Vector2(r.position.x + 22, r.position.y + 44), 11,
			Color(0.72, 0.92, 1.0, 0.85))
	# estado (stall x dado recebido)
	var blink: float = 0.55 + 0.45 * sin(_t * 6.0) if waiting else 1.0
	draw_circle(Vector2(r.position.x + 27, r.position.y + 57), 3.5, Color(accent.r, accent.g, accent.b, blink))
	var status: String = "STALL · aguardando o dado" if waiting else "dado recebido"
	Style.text(self, status, Vector2(r.position.x + 36, r.position.y + 61), 10, Color(accent.r, accent.g, accent.b, 0.95),
			Style.bold())

	# registrador do endereço requisitado
	var rr := Rect2(r.end.x - 172, r.position.y + 12, 152, 46)
	draw_style_box(Style.box(Color("#04121a"), Color(accent.r, accent.g, accent.b, 0.55 + 0.35 * pulse), 6, 1), rr)
	Style.text(self, "ENDEREÇO REQUISITADO", Vector2(rr.position.x, rr.position.y + 12), 9, Color(0.6, 0.8, 0.9, 0.8),
			Style.ui(), HORIZONTAL_ALIGNMENT_CENTER, rr.size.x)
	Style.text(self, cpu_req, Vector2(rr.position.x, rr.position.y + 37), 24, Color.WHITE,
			Style.mono(), HORIZONTAL_ALIGNMENT_CENTER, rr.size.x)
