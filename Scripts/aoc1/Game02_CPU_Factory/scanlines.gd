@tool
extends Control
## Linhas horizontais finas para dar aspecto de monitor CRT.

@export var spacing := 3.0
@export var line_color := Color(0, 0, 0, 0.22)


func _draw() -> void:
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), line_color, 1.0)
		y += spacing
