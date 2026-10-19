extends Node2D
## Fundo sem imagens externas; pode ser substituído por TileMapLayer posteriormente.

func _draw() -> void:
	var bg: Color = Color("081226")
	draw_rect(Rect2(0, 0, 3400, 720), bg)
	var grid_color: Color = Color("102c41")
	for x in range(0, 3401, 80):
		draw_line(Vector2(x, 0), Vector2(x, 720), grid_color, 1.0)
	for y in range(0, 721, 80):
		draw_line(Vector2(0, y), Vector2(3400, y), grid_color, 1.0)

	for i in range(20):
		var start_x: float = 55.0 + i * 169.0
		var start_y: float = 190.0 + float(i % 3) * 68.0
		var trace: PackedVector2Array = PackedVector2Array([
			Vector2(start_x, start_y),
			Vector2(start_x + 40.0, start_y),
			Vector2(start_x + 70.0, start_y + 30.0),
			Vector2(start_x + 128.0, start_y + 30.0)
		])
		draw_polyline(trace, Color("16566f"), 4.0, true)
		draw_circle(trace[0], 5.0, Color("2ca8c1"))
		draw_circle(trace[3], 5.0, Color("2ca8c1"))

	for i in range(16):
		var x: float = 80.0 + i * 204.0
		draw_rect(Rect2(x, 610, 80, 9), Color("0b6383"))
		draw_circle(Vector2(x + 40.0, 615.0), 4.0, Color("45e4f8"))
