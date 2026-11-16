extends Control
## HUD do Cache Rush, todo desenhado por código:
## painel superior (endereço, score, sequência, hit rate, ciclos, tempo),
## trilha da hierarquia (REG → L1 → L2 → L3 → RAM → SSD) com o resultado de
## cada consulta, aviso inferior e tela final.

const Style = preload("res://Scripts/aoc1/Game03_Cache Rush/cache_style.gd")
const Sim = preload("res://Scripts/aoc1/Game03_Cache Rush/cache_sim.gd")

# Preenchidos pelo controlador da fase a cada frame
var target_text: String = "--"
var score: int = 0
var streak: int = 0
var multiplier: int = 1
var hit_rate: float = -1.0
var round_cycles: int = 0
var round_time: float = 0.0
var round_no: int = 1
var total_rounds: int = 0
var stalled: bool = true
## 0 = pendente, 1 = consultando, 2 = miss, 3 = hit
var pipeline: Array = [0, 0, 0, 0, 0, 0]

var over: bool = false
var over_data: Dictionary = {}

var _toast_title: String = ""
var _toast_lines: Array = []
var _toast_color: Color = Style.CYAN
var _toast_t: float = 0.0
var _toast_dur: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func toast(title: String, body: String, color: Color, duration: float = 0.0) -> void:
	_toast_title = title
	_toast_lines = body.split("\n") if body != "" else []
	_toast_color = color
	_toast_t = 0.0
	_toast_dur = duration


func clear_toast() -> void:
	_toast_title = ""
	_toast_lines = []


func _process(delta: float) -> void:
	_time += delta
	_toast_t += delta
	queue_redraw()


func _draw() -> void:
	_draw_top()
	_draw_toast()
	Style.text(self, "WASD mover   |   E consultar", Vector2(24, 706), 11, Color(0.55, 0.65, 0.7, 0.8))
	if over:
		_draw_over()


# ------------------------------------------------------------ painel topo ----

func _stat(x: float, label: String, value: String, color: Color = Color.WHITE, mono: bool = false, size: int = 20) -> void:
	Style.text(self, label, Vector2(x, 28), 10, Style.DIM)
	var f: Font = Style.mono() if mono else Style.bold()
	Style.text(self, value, Vector2(x, 53), size, color, f)


func _draw_top() -> void:
	var panel := Rect2(16, 8, 1248, 96)
	draw_style_box(Style.box(Color(0.035, 0.08, 0.11, 0.93), Color(Style.CYAN, 0.35), 12, 1,
			Color(0, 0, 0, 0.5), 10), panel)

	_stat(34, "ENDEREÇO REQUISITADO", target_text, Style.CYAN, true, 24)
	_stat(240, "SCORE", str(score))
	var seq: String = "x%d" % streak
	_stat(360, "SEQUÊNCIA", seq, Style.AMBER if multiplier > 1 else Color.WHITE)
	if multiplier > 1:
		Style.text(self, "×%d pontos" % multiplier, Vector2(360 + Style.text_width(seq, 20, Style.bold()) + 8, 52), 11,
				Style.AMBER, Style.bold())
	var hr: String = "--" if hit_rate < 0.0 else "%d%%" % int(round(hit_rate * 100.0))
	var hr_col: Color = Color.WHITE
	if hit_rate >= 0.0:
		hr_col = Style.GREEN if hit_rate >= 0.6 else (Style.AMBER if hit_rate >= 0.4 else Style.RED)
	_stat(520, "HIT RATE", hr, hr_col)
	_stat(650, "CICLOS NA RODADA", Style.fmt(round_cycles), Color.WHITE)
	_stat(850, "TEMPO", "%.1f s" % round_time)
	var rd: String = str(round_no) if total_rounds <= 0 else "%d / %d" % [mini(round_no, total_rounds), total_rounds]
	_stat(960, "RODADA", rd)

	# estado da CPU
	var accent: Color = Style.AMBER if stalled else Style.GREEN
	var blink: float = 0.5 + 0.5 * sin(_time * 6.0) if stalled else 1.0
	draw_circle(Vector2(1100, 40), 4.5, Color(accent.r, accent.g, accent.b, blink))
	Style.text(self, "CPU EM STALL" if stalled else "CPU LIVRE", Vector2(1112, 44), 12, accent, Style.bold())

	# trilha da hierarquia
	Style.text(self, "HIERARQUIA", Vector2(34, 85), 10, Style.DIM)
	var x0: float = 130.0
	var cw: float = 144.0
	var gap: float = 20.0
	var max_log: float = log(float(Sim.CYCLES[5]) + 1.0)
	for i in range(6):
		var x: float = x0 + i * (cw + gap)
		var lc: Color = Style.LEVEL_COLORS[i]
		var st: int = pipeline[i]
		var bg := Color(0.04, 0.09, 0.12, 0.9)
		var br := Color(lc.r, lc.g, lc.b, 0.22)
		var glow := Color(0, 0, 0, 0)
		var gs := 0
		match st:
			1:
				var p: float = 0.5 + 0.5 * sin(_time * 5.0)
				br = Color(lc.r, lc.g, lc.b, 0.8 + 0.2 * p)
				bg = Color(lc.r, lc.g, lc.b, 0.12)
				glow = Color(lc.r, lc.g, lc.b, 0.25 * p)
				gs = 8
			2:
				bg = Color(Style.RED.r, Style.RED.g, Style.RED.b, 0.14)
				br = Color(Style.RED, 0.8)
			3:
				bg = Color(Style.GREEN.r, Style.GREEN.g, Style.GREEN.b, 0.16)
				br = Color(Style.GREEN, 0.95)
				glow = Color(Style.GREEN.r, Style.GREEN.g, Style.GREEN.b, 0.3)
				gs = 8
		var chip := Rect2(x, 66, cw, 30)
		draw_style_box(Style.box(bg, br, 8, 1, glow, gs), chip)
		_status_icon(Vector2(x + 14, 79), st, lc)
		var name_col: Color = Color(1, 1, 1, 0.95) if st != 0 else Color(1, 1, 1, 0.55)
		Style.text(self, Sim.SHORT[i], Vector2(x + 28, 84), 12, name_col, Style.mono())
		var cyc: int = Sim.CYCLES[i]
		Style.text(self, "%s %s" % [Style.fmt_short(cyc), "ciclo" if cyc == 1 else "ciclos"], Vector2(x + 28, 84), 10,
				Color(0.75, 0.9, 1.0, 0.7), Style.ui(), HORIZONTAL_ALIGNMENT_RIGHT, cw - 38)
		# barra de latência (escala logarítmica)
		var frac: float = log(float(Sim.CYCLES[i]) + 1.0) / max_log
		draw_rect(Rect2(x + 8, 91, cw - 16, 2), Color(1, 1, 1, 0.08))
		draw_rect(Rect2(x + 8, 91, (cw - 16) * frac, 2), Color(lc.r, lc.g, lc.b, 0.9))
		# seta até o próximo chip
		if i < 5:
			var ax: float = x + cw + 6
			var ac: Color = Color(Style.RED, 0.8) if st == 2 else Color(1, 1, 1, 0.25)
			draw_polyline(PackedVector2Array([Vector2(ax, 74), Vector2(ax + 7, 81), Vector2(ax, 88)]), ac, 2.0, true)

	# legenda LRU
	draw_rect(Rect2(1112, 79, 14, 3), Style.ORANGE)
	Style.text(self, "LRU = próxima linha a sair", Vector2(1132, 84), 10, Style.DIM)


func _status_icon(c: Vector2, st: int, lc: Color) -> void:
	match st:
		1:
			var p: float = 0.5 + 0.5 * sin(_time * 5.0)
			draw_circle(c, 3.0 + 1.5 * p, lc)
		2:
			draw_line(c + Vector2(-4, -4), c + Vector2(4, 4), Style.RED, 2.5, true)
			draw_line(c + Vector2(-4, 4), c + Vector2(4, -4), Style.RED, 2.5, true)
		3:
			draw_polyline(PackedVector2Array([c + Vector2(-5, 0), c + Vector2(-1.5, 4), c + Vector2(5, -4)]), Style.GREEN, 2.5, true)
		_:
			draw_circle(c, 2.5, Color(1, 1, 1, 0.2))


# ------------------------------------------------------------------ toast ----

func _draw_toast() -> void:
	if _toast_title == "":
		return
	var alpha: float = clampf(_toast_t / 0.15, 0.0, 1.0)
	if _toast_dur > 0.0:
		alpha = minf(alpha, clampf((_toast_dur - _toast_t) / 0.4, 0.0, 1.0))
		if _toast_t >= _toast_dur:
			return
	var slide: float = (1.0 - clampf(_toast_t / 0.2, 0.0, 1.0)) * 10.0
	var col: Color = _toast_color
	var r := Rect2(250, 632 + slide, 780, 82)
	draw_style_box(Style.box(Color(0.035, 0.07, 0.10, 0.95 * alpha), Color(col.r, col.g, col.b, 0.8 * alpha), 12, 2,
			Color(col.r, col.g, col.b, 0.22 * alpha), 12), r)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 12, 5, r.size.y - 24), Color(col.r, col.g, col.b, alpha))
	Style.text(self, _toast_title, Vector2(r.position.x + 24, r.position.y + 24), 16,
			Color(col.r, col.g, col.b, alpha), Style.bold())
	var y: float = r.position.y + 43
	for line in _toast_lines:
		Style.text(self, line, Vector2(r.position.x + 24, y), 12, Color(0.88, 0.96, 1.0, alpha * 0.95))
		y += 16.5


# --------------------------------------------------------------- fim de fase ----

func _draw_over() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.72))
	var p := Rect2(310, 110, 660, 500)
	draw_style_box(Style.box(Color(0.04, 0.08, 0.11, 0.98), Color(Style.CYAN, 0.8), 16, 2,
			Color(Style.CYAN, 0.25), 24), p)
	Style.text(self, "FASE CONCLUÍDA", Vector2(p.position.x, p.position.y + 54), 30, Style.CYAN,
			Style.bold(), HORIZONTAL_ALIGNMENT_CENTER, p.size.x)
	Style.text(self, "Resultado da hierarquia de memória", Vector2(p.position.x, p.position.y + 78), 13,
			Style.DIM, Style.ui(), HORIZONTAL_ALIGNMENT_CENTER, p.size.x)

	var grade: String = over_data.get("grade", "C")
	var gcol: Color = Style.GREEN if grade in ["S", "A"] else (Style.AMBER if grade == "B" else Style.RED)
	draw_style_box(Style.box(Color(gcol, 0.12), Color(gcol, 0.9), 14, 2, Color(gcol, 0.3), 16),
			Rect2(p.position.x + 40, p.position.y + 110, 110, 110))
	Style.text(self, grade, Vector2(p.position.x + 40, p.position.y + 187), 68, gcol, Style.bold(),
			HORIZONTAL_ALIGNMENT_CENTER, 110)
	Style.text(self, "NOTA", Vector2(p.position.x + 40, p.position.y + 132), 10, Style.DIM, Style.ui(),
			HORIZONTAL_ALIGNMENT_CENTER, 110)

	var rows: Array = [
		["SCORE", Style.fmt(int(over_data.get("score", 0)))],
		["HIT RATE (Reg/L1/L2/L3)", "%d%%" % int(round(float(over_data.get("hit_rate", 0.0)) * 100.0))],
		["MAIOR SEQUÊNCIA", "x%d" % int(over_data.get("best_streak", 0))],
		["CICLOS POR ACESSO", Style.fmt(int(over_data.get("avg_cycles", 0)))],
	]
	var y: float = p.position.y + 128
	for row in rows:
		Style.text(self, row[0], Vector2(p.position.x + 190, y), 11, Style.DIM)
		Style.text(self, row[1], Vector2(p.position.x + 190, y + 20), 18, Color.WHITE, Style.bold())
		y += 38

	var insight: String = over_data.get("insight", "")
	var lines: PackedStringArray = insight.split("\n")
	var ly: float = p.position.y + 300
	draw_style_box(Style.box(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.10), 10, 1),
			Rect2(p.position.x + 30, ly - 22, p.size.x - 60, 120))
	Style.text(self, "O QUE A HIERARQUIA MOSTROU", Vector2(p.position.x + 46, ly - 4), 11, Style.AMBER, Style.bold())
	ly += 18
	for line in lines:
		Style.text(self, line, Vector2(p.position.x + 46, ly), 12, Color(0.9, 0.97, 1.0, 0.95))
		ly += 18

	var pulse: float = 0.6 + 0.4 * sin(_time * 4.0)
	Style.text(self, "[E] Jogar novamente        [ESC] Voltar ao laboratório",
			Vector2(p.position.x, p.end.y - 28), 14, Color(Style.CYAN, pulse), Style.bold(),
			HORIZONTAL_ALIGNMENT_CENTER, p.size.x)
