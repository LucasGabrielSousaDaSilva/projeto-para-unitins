@tool
class_name BusLines
extends Control
## Desenha o barramento ligando as colunas de slots (fase 1).
## O controle deve ter a mesma largura do HBoxContainer dos slots.

@export var columns := 3:
	set(v):
		columns = v
		queue_redraw()
@export var separation := 40.0:
	set(v):
		separation = v
		queue_redraw()
@export var color := Color(0.22, 0.66, 1.0):
	set(v):
		color = v
		queue_redraw()
@export var lanes := 3
@export var label := "BARRAMENTO  ·  DADOS  ·  ENDEREÇOS  ·  CONTROLE"


func _draw() -> void:
	var col_w := (size.x - separation * (columns - 1)) / columns
	var bus_y := size.y * 0.5
	var gap := 7.0
	var x0 := col_w * 0.5
	var x1 := size.x - col_w * 0.5

	# trilhas horizontais
	for l in lanes:
		var y := bus_y + (l - (lanes - 1) * 0.5) * gap
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(color, 0.6), 2.0)
		draw_circle(Vector2(x0, y), 2.5, color)
		draw_circle(Vector2(x1, y), 2.5, color)

	# descidas de cada slot ate o barramento
	for c in columns:
		var cx := c * (col_w + separation) + col_w * 0.5
		for l in lanes:
			var x := cx + (l - (lanes - 1) * 0.5) * gap
			var y_end := bus_y + (l - (lanes - 1) * 0.5) * gap
			draw_line(Vector2(x, 0), Vector2(x, y_end), Color(color, 0.6), 2.0)
			draw_circle(Vector2(x, y_end), 3.0, Color(1, 1, 1, 0.85))
		draw_rect(Rect2(cx - 14, -2, 28, 5), Color(0.95, 0.8, 0.35, 0.9))

	var font := ThemeDB.fallback_font
	var fs := 11
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var tx := (size.x - text_size.x) * 0.5
	draw_rect(Rect2(tx - 10, bus_y + 18, text_size.x + 20, 17), Color(0.035, 0.09, 0.15, 0.95))
	draw_string(font, Vector2(tx, bus_y + 30), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color, 0.8))
