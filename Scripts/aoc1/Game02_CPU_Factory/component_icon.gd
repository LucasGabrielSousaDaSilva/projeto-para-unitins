@tool
class_name ComponentIcon
extends Control
## Ícones vetoriais dos componentes, desenhados por código (sem imagens).
## kind: memory, processor, peripherals, control, alu, registers, cache, empty

const GOLD := Color(1.0, 0.82, 0.35)

@export var kind: StringName = &"empty":
	set(value):
		kind = value
		queue_redraw()

@export var color: Color = Color(0.22, 0.66, 1.0):
	set(value):
		color = value
		queue_redraw()

var _s := 48.0
var _o := Vector2.ZERO
var _w := 2.0


func _init() -> void:
	custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _p(x: float, y: float) -> Vector2:
	return _o + Vector2(x, y) * _s


func _r(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(_p(x, y), Vector2(w, h) * _s)


func _draw() -> void:
	_s = minf(size.x, size.y)
	_o = (size - Vector2(_s, _s)) * 0.5
	_w = maxf(1.5, _s * 0.05)

	match kind:
		&"memory": _draw_memory()
		&"processor": _draw_processor()
		&"peripherals": _draw_peripherals()
		&"control": _draw_control()
		&"alu": _draw_alu()
		&"registers": _draw_registers()
		&"cache": _draw_cache()
		_: _draw_empty()


func _draw_memory() -> void:
	var body := _r(0.06, 0.2, 0.88, 0.5)
	draw_rect(body, Color(color, 0.16))
	draw_rect(body, color, false, _w)
	for i in 4:
		draw_rect(_r(0.14 + i * 0.2, 0.3, 0.14, 0.3), Color(color, 0.9))
	for i in 12:
		if i == 7:
			continue # chanfro de encaixe
		draw_rect(_r(0.09 + i * 0.07, 0.74, 0.04, 0.14), GOLD)


func _draw_processor() -> void:
	var r := _r(0.25, 0.25, 0.5, 0.5)
	draw_rect(r, Color(color, 0.18))
	draw_rect(r, color, false, _w)
	draw_rect(_r(0.36, 0.36, 0.28, 0.28), Color(color, 0.85))
	for i in 4:
		var t := 0.33 + i * 0.113
		draw_line(_p(t, 0.1), _p(t, 0.25), GOLD, _w * 0.8)
		draw_line(_p(t, 0.75), _p(t, 0.9), GOLD, _w * 0.8)
		draw_line(_p(0.1, t), _p(0.25, t), GOLD, _w * 0.8)
		draw_line(_p(0.75, t), _p(0.9, t), GOLD, _w * 0.8)
	draw_colored_polygon(PackedVector2Array([_p(0.25, 0.25), _p(0.36, 0.25), _p(0.25, 0.36)]), Color(1, 1, 1, 0.85))


func _draw_peripherals() -> void:
	var mon := _r(0.2, 0.06, 0.6, 0.42)
	draw_rect(mon, Color(color, 0.16))
	draw_rect(mon, color, false, _w)
	draw_rect(_r(0.26, 0.12, 0.48, 0.3), Color(color, 0.5))
	draw_line(_p(0.5, 0.48), _p(0.5, 0.57), color, _w)
	draw_line(_p(0.36, 0.57), _p(0.64, 0.57), color, _w)
	var kb := _r(0.08, 0.65, 0.84, 0.27)
	draw_rect(kb, Color(color, 0.16))
	draw_rect(kb, color, false, _w)
	for row in 2:
		for c in 7:
			draw_rect(_r(0.13 + c * 0.105, 0.7 + row * 0.1, 0.07, 0.06), Color(color, 0.85))


func _draw_control() -> void:
	var c := _p(0.5, 0.5)
	draw_circle(c, 0.17 * _s, Color(color, 0.18))
	draw_arc(c, 0.17 * _s, 0.0, TAU, 32, color, _w)
	draw_circle(c, 0.07 * _s, color)
	for i in 8:
		var a := i * TAU / 8.0
		var dir := Vector2.from_angle(a)
		var diagonal := i % 2 == 1
		var from := c + dir * 0.19 * _s
		var to := c + dir * (0.32 if diagonal else 0.36) * _s
		draw_line(from, to, color, _w)
		var node_size := (0.08 if diagonal else 0.11) * _s
		draw_rect(Rect2(to - Vector2(node_size, node_size) * 0.5, Vector2(node_size, node_size)), Color(color, 0.9))


func _draw_alu() -> void:
	var pts := PackedVector2Array([
		_p(0.08, 0.16), _p(0.38, 0.16), _p(0.5, 0.34), _p(0.62, 0.16),
		_p(0.92, 0.16), _p(0.74, 0.86), _p(0.26, 0.86)
	])
	draw_colored_polygon(pts, Color(color, 0.18))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, color, _w)
	draw_line(_p(0.42, 0.6), _p(0.58, 0.6), color, _w * 1.2)
	draw_line(_p(0.5, 0.52), _p(0.5, 0.68), color, _w * 1.2)
	draw_line(_p(0.4, 0.78), _p(0.6, 0.78), color, _w * 1.2)


func _draw_registers() -> void:
	var bits := [[1, 0, 1, 1], [0, 1, 0, 0], [1, 1, 0, 1]]
	for row in 3:
		for c in 4:
			var cell := _r(0.08 + c * 0.22, 0.16 + row * 0.26, 0.18, 0.2)
			var on: bool = bits[row][c] == 1
			draw_rect(cell, Color(color, 0.85 if on else 0.12))
			draw_rect(cell, color, false, _w * 0.7)


func _draw_cache() -> void:
	var bolt := PackedVector2Array([
		_p(0.58, 0.06), _p(0.24, 0.54), _p(0.46, 0.54),
		_p(0.38, 0.94), _p(0.78, 0.4), _p(0.55, 0.4)
	])
	draw_colored_polygon(bolt, Color(color, 0.85))
	var outline := bolt.duplicate()
	outline.append(bolt[0])
	draw_polyline(outline, Color(1, 1, 1, 0.7), _w * 0.6)
	draw_arc(_p(0.5, 0.5), 0.44 * _s, deg_to_rad(200), deg_to_rad(250), 8, Color(color, 0.5), _w)
	draw_arc(_p(0.5, 0.5), 0.44 * _s, deg_to_rad(20), deg_to_rad(70), 8, Color(color, 0.5), _w)


func _draw_empty() -> void:
	var c := Color(color, 0.55)
	var a := _p(0.12, 0.12)
	var b := _p(0.88, 0.12)
	var d := _p(0.88, 0.88)
	var e := _p(0.12, 0.88)
	draw_dashed_line(a, b, c, _w, 5.0)
	draw_dashed_line(b, d, c, _w, 5.0)
	draw_dashed_line(d, e, c, _w, 5.0)
	draw_dashed_line(e, a, c, _w, 5.0)
	draw_line(_p(0.5, 0.36), _p(0.5, 0.64), c, _w)
	draw_line(_p(0.36, 0.5), _p(0.64, 0.5), c, _w)
