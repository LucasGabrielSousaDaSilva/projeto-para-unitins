@tool
class_name PCBArt
extends Control
## Arte de placa de circuito desenhada por código.
##  - MOTHERBOARD: trilhas, vias, furos de fixação (fase 1)
##  - DIE: encapsulamento do processador com pinos + barramento interno (fase 2)
##  - BACKGROUND: grade discreta de fundo
## Use set_state() para reagir ao jogo: idle, boot, ok, error.

enum Mode { MOTHERBOARD, DIE, BACKGROUND }

const GOLD := Color(1.0, 0.82, 0.35)
const STATE_COLORS := {
	&"idle": Color(0.16, 0.5, 0.72, 0.5),
	&"boot": Color(0.35, 0.85, 1.0, 0.8),
	&"ok": Color(0.28, 0.95, 0.58, 0.85),
	&"error": Color(1.0, 0.33, 0.36, 0.85),
}

@export var mode: Mode = Mode.MOTHERBOARD:
	set(v):
		mode = v
		_build()
@export var seed_value := 7:
	set(v):
		seed_value = v
		_build()
@export var trace_count := 34:
	set(v):
		trace_count = v
		_build()
@export_group("Die (fase 2)")
@export var package_rect := Rect2(120, 38, 520, 288)
@export var die_inset := 30.0
@export var grid_padding := 12.0
@export var grid_gap := Vector2(48, 24)
@export var die_title := "NÚCLEO DA CPU"

var state: StringName = &"idle"
var _cur_color: Color = STATE_COLORS[&"idle"]
var _time := 0.0
var _traces: Array[PackedVector2Array] = []
var _lengths: Array[float] = []


func _ready() -> void:
	resized.connect(_build)
	_build()


func set_state(new_state: StringName) -> void:
	state = new_state
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var target: Color = STATE_COLORS.get(state, STATE_COLORS[&"idle"])
	var changing := not _cur_color.is_equal_approx(target)
	if changing:
		_cur_color = _cur_color.lerp(target, clampf(delta * 6.0, 0.0, 1.0))
	if state != &"idle" or changing:
		_time += delta
		queue_redraw()


# ------------------------------------------------------------------ geração

func _build() -> void:
	_traces.clear()
	_lengths.clear()
	if size.x < 40.0 or size.y < 40.0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var g := 20.0
	var cols := int(size.x / g)
	var rows := int(size.y / g)
	var count := trace_count if mode != Mode.BACKGROUND else int(trace_count * 0.6)
	var axes := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

	for i in count:
		var p := Vector2(rng.randi_range(1, cols - 1), rng.randi_range(1, rows - 1)) * g
		var axis: Vector2 = axes[rng.randi_range(0, 3)]
		var perp := Vector2(-axis.y, axis.x)
		var pts := PackedVector2Array([p])
		for s in rng.randi_range(2, 3):
			p += axis * g * rng.randi_range(3, 9)
			pts.append(_clamp_pt(p, g))
			var jog := rng.randi_range(1, 3)
			var sign_ := 1.0 if rng.randf() < 0.5 else -1.0
			p += (axis + perp * sign_) * g * jog
			pts.append(_clamp_pt(p, g))

		# alguns viram feixes de trilhas paralelas
		var bundle := rng.randi_range(1, 4) if rng.randf() < 0.45 else 1
		for k in bundle:
			var shifted := PackedVector2Array()
			for pt in pts:
				shifted.append(pt + perp * 7.0 * k)
			_traces.append(shifted)
			_lengths.append(_poly_length(shifted))


func _clamp_pt(p: Vector2, margin: float) -> Vector2:
	return Vector2(clampf(p.x, margin, size.x - margin), clampf(p.y, margin, size.y - margin))


func _poly_length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
	return total


func _point_at(pts: PackedVector2Array, dist: float) -> Vector2:
	var remaining := dist
	for i in range(1, pts.size()):
		var seg := pts[i].distance_to(pts[i - 1])
		if remaining <= seg:
			return pts[i - 1].lerp(pts[i], remaining / maxf(seg, 0.001))
		remaining -= seg
	return pts[pts.size() - 1]


# ------------------------------------------------------------------ desenho

func _draw() -> void:
	match mode:
		Mode.BACKGROUND:
			_draw_dots(0.07, 32.0)
			_draw_traces(0.35)
		Mode.MOTHERBOARD:
			_draw_dots(0.1, 20.0)
			_draw_traces(1.0)
			_draw_mount_holes()
			_draw_silk("AOC-1 · PLACA-MÃE · REV 2.0", Vector2(size.x - 48, size.y - 12), true)
		Mode.DIE:
			_draw_dots(0.1, 20.0)
			_draw_traces(0.8)
			_draw_package()
			_draw_mount_holes()


func _trace_color(alpha_scale: float) -> Color:
	var c := _cur_color if not Engine.is_editor_hint() else STATE_COLORS[&"idle"]
	return Color(c, c.a * alpha_scale)


func _draw_dots(alpha: float, step: float) -> void:
	var c := Color(0.4, 0.7, 1.0, alpha)
	var x := step
	while x < size.x:
		var y := step
		while y < size.y:
			draw_rect(Rect2(x - 1, y - 1, 2, 2), c)
			y += step
		x += step


func _draw_traces(alpha_scale: float) -> void:
	var col := _trace_color(alpha_scale)
	for i in _traces.size():
		var pts := _traces[i]
		draw_polyline(pts, col, 2.0)
		var end := pts[pts.size() - 1]
		var start := pts[0]
		draw_arc(end, 4.5, 0.0, TAU, 14, col, 1.6)
		draw_circle(end, 1.8, col)
		draw_circle(start, 2.2, col)

	# pulsos de dados viajando pelas trilhas
	if state != &"idle" and not Engine.is_editor_hint():
		var speed := 0.35 if state == &"boot" else 0.2
		for i in _traces.size():
			if i % 2 != 0:
				continue
			var t := fposmod(_time * speed + i * 0.173, 1.0)
			var d := t * _lengths[i]
			var head := _point_at(_traces[i], d)
			var tail := _point_at(_traces[i], maxf(d - 18.0, 0.0))
			var bright := Color(1, 1, 1, 0.9)
			draw_line(tail, head, Color(_cur_color, 0.8), 3.0)
			draw_circle(head, 3.0, bright)


func _draw_mount_holes() -> void:
	for c in [Vector2(24, 24), Vector2(size.x - 24, 24), Vector2(24, size.y - 24), Vector2(size.x - 24, size.y - 24)]:
		draw_circle(c, 11.0, Color(0.55, 0.45, 0.2, 0.55))
		draw_circle(c, 7.5, Color(0.02, 0.05, 0.09, 1.0))
		draw_arc(c, 11.0, 0.0, TAU, 20, GOLD, 2.0)


func _draw_silk(text: String, pos: Vector2, align_right: bool) -> void:
	var font := ThemeDB.fallback_font
	var fs := 10
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := pos.x - width if align_right else pos.x
	draw_string(font, Vector2(x, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.6, 0.8, 1.0, 0.4))


func _draw_package() -> void:
	var accent := Color(0.22, 0.66, 1.0)
	if state == &"ok":
		accent = Color(0.28, 0.95, 0.58)
	elif state == &"error":
		accent = Color(1.0, 0.33, 0.36)

	# encapsulamento (substrato do chip)
	var pkg := StyleBoxFlat.new()
	pkg.bg_color = Color(0.055, 0.12, 0.2)
	pkg.border_color = Color(accent, 0.9)
	pkg.set_border_width_all(3)
	pkg.set_corner_radius_all(14)
	pkg.shadow_color = Color(accent, 0.28)
	pkg.shadow_size = 18
	draw_style_box(pkg, package_rect)

	# pinos dourados em duas fileiras por lado
	var pr := package_rect
	var pin := Color(GOLD, 0.62)
	var x := pr.position.x + 36.0
	while x < pr.end.x - 30.0:
		for off in [9.0, 21.0]:
			draw_rect(Rect2(x, pr.position.y + off, 5, 5), pin)
			draw_rect(Rect2(x, pr.end.y - off - 5, 5, 5), pin)
		x += 12.0
	var y := pr.position.y + 36.0
	while y < pr.end.y - 30.0:
		for off in [9.0, 21.0]:
			draw_rect(Rect2(pr.position.x + off, y, 5, 5), pin)
			draw_rect(Rect2(pr.end.x - off - 5, y, 5, 5), pin)
		y += 12.0

	# marcador do pino 1
	var o := pr.position
	draw_colored_polygon(PackedVector2Array([o + Vector2(8, 8), o + Vector2(26, 8), o + Vector2(8, 26)]), Color(1, 1, 1, 0.85))

	# pastilha de silício (die)
	var die := package_rect.grow(-die_inset)
	var die_box := StyleBoxFlat.new()
	die_box.bg_color = Color(0.03, 0.075, 0.13)
	die_box.border_color = Color(accent, 0.7)
	die_box.set_border_width_all(2)
	die_box.set_corner_radius_all(6)
	draw_style_box(die_box, die)

	var grid := die.grow(-grid_padding)
	# malha fina dentro do die
	var gx := die.position.x + 8.0
	while gx < die.end.x:
		draw_line(Vector2(gx, die.position.y + 3), Vector2(gx, die.end.y - 3), Color(accent, 0.06), 1.0)
		gx += 10.0

	# barramento interno nos vãos entre os slots
	var cell := (grid.size - grid_gap) / 2.0
	var vx := grid.position.x + cell.x + grid_gap.x * 0.5
	var hy := grid.position.y + cell.y + grid_gap.y * 0.5
	var bus := Color(accent, 0.85)
	for off in [-10.0, 0.0, 10.0]:
		draw_line(Vector2(vx + off, die.position.y + 2), Vector2(vx + off, die.end.y - 2), bus, 2.0)
	for off in [-4.0, 4.0]:
		draw_line(Vector2(grid.position.x - 8, hy + off), Vector2(grid.end.x + 8, hy + off), bus, 2.0)
	for off in [-10.0, 0.0, 10.0]:
		draw_circle(Vector2(vx + off, hy - 4), 2.6, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(vx + off, hy + 4), 2.6, Color(1, 1, 1, 0.9))

	# pulsos no barramento interno enquanto a placa trabalha
	if state != &"idle" and not Engine.is_editor_hint():
		var t := fposmod(_time * 0.6, 1.0)
		var px := lerpf(die.position.y, die.end.y, t)
		draw_circle(Vector2(vx, px), 3.5, Color(1, 1, 1, 0.95))
		var qx := lerpf(grid.position.x, grid.end.x, fposmod(_time * 0.5 + 0.3, 1.0))
		draw_circle(Vector2(qx, hy), 3.5, Color(1, 1, 1, 0.95))

	_draw_silk(die_title, Vector2(die.position.x + 6, die.position.y + 9), false)
	_draw_silk("AOC-1 · DIE 0", Vector2(die.end.x - 6, die.end.y - 3), true)
