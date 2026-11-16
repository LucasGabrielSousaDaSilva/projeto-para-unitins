extends Node2D
## Efeitos por cima de tudo: pacotes de dados viajando pelos barramentos,
## textos flutuantes ("+120", "MISS"), anéis de pulso e faíscas.

const Style = preload("res://Scripts/aoc1/Game03_Cache Rush/cache_style.gd")

var _packets: Array = []
var _popups: Array = []
var _rings: Array = []
var _sparks: Array = []


func _ready() -> void:
	z_index = 20


## Envia um pacote ao longo de uma polilinha.
func send(points: PackedVector2Array, duration: float, color: Color, label: String, is_data: bool) -> void:
	_packets.append({
		"pts": points, "len": Style.poly_length(points), "t": 0.0, "dur": maxf(duration, 0.05),
		"color": color, "label": label, "data": is_data,
	})


func popup(pos: Vector2, text: String, color: Color, size: int = 18) -> void:
	_popups.append({"pos": pos, "text": text, "color": color, "t": 0.0, "dur": 1.3, "size": size})


func ring(pos: Vector2, color: Color) -> void:
	_rings.append({"pos": pos, "color": color, "t": 0.0, "dur": 0.7})


func burst(pos: Vector2, color: Color, count: int = 14) -> void:
	for i in range(count):
		var ang: float = randf() * TAU
		var spd: float = randf_range(60.0, 200.0)
		_sparks.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "t": 0.0,
				"dur": randf_range(0.4, 0.8), "color": color})


func _process(delta: float) -> void:
	for i in range(_packets.size() - 1, -1, -1):
		_packets[i]["t"] += delta
		if _packets[i]["t"] >= _packets[i]["dur"]:
			_packets.remove_at(i)
	for i in range(_popups.size() - 1, -1, -1):
		_popups[i]["t"] += delta
		if _popups[i]["t"] >= _popups[i]["dur"]:
			_popups.remove_at(i)
	for i in range(_rings.size() - 1, -1, -1):
		_rings[i]["t"] += delta
		if _rings[i]["t"] >= _rings[i]["dur"]:
			_rings.remove_at(i)
	for i in range(_sparks.size() - 1, -1, -1):
		_sparks[i]["t"] += delta
		_sparks[i]["pos"] += _sparks[i]["vel"] * delta
		_sparks[i]["vel"] *= 0.94
		if _sparks[i]["t"] >= _sparks[i]["dur"]:
			_sparks.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for r in _rings:
		var k: float = r["t"] / r["dur"]
		var col: Color = r["color"]
		draw_arc(r["pos"], 10.0 + 60.0 * k, 0.0, TAU, 40, Color(col.r, col.g, col.b, 1.0 - k), 3.0, true)

	for s in _sparks:
		var a: float = 1.0 - s["t"] / s["dur"]
		var col2: Color = s["color"]
		draw_circle(s["pos"], 2.5 * a + 0.5, Color(col2.r, col2.g, col2.b, a))

	for p in _packets:
		var k2: float = clampf(p["t"] / p["dur"], 0.0, 1.0)
		var e: float = k2 * k2 * (3.0 - 2.0 * k2)  # smoothstep
		var pts: PackedVector2Array = p["pts"]
		var col3: Color = p["color"]
		# rastro
		for i in range(6):
			var back: float = maxf(0.0, e * float(p["len"]) - (i + 1) * 9.0)
			var tinfo: Dictionary = Style.point_at(pts, back)
			draw_circle(tinfo["pos"], 5.0 - i * 0.7, Color(col3.r, col3.g, col3.b, 0.30 - i * 0.045))
		var info: Dictionary = Style.point_at(pts, e * float(p["len"]))
		var pos: Vector2 = info["pos"]
		var w: float = 46.0
		var rect := Rect2(pos - Vector2(w * 0.5, 11), Vector2(w, 22))
		draw_style_box(Style.box(Color(col3.r * 0.25, col3.g * 0.25, col3.b * 0.25, 0.97), col3, 6, 2,
				Color(col3.r, col3.g, col3.b, 0.45), 10), rect)
		Style.text(self, p["label"], Vector2(rect.position.x, rect.position.y + 16), 12, Color.WHITE,
				Style.mono(), HORIZONTAL_ALIGNMENT_CENTER, w)

	for q in _popups:
		var k3: float = q["t"] / q["dur"]
		var col4: Color = q["color"]
		var alpha: float = clampf(minf(k3 * 8.0, (1.0 - k3) * 2.5), 0.0, 1.0)
		var pos2: Vector2 = q["pos"] + Vector2(0, -46.0 * k3)
		var txt: String = q["text"]
		var width: float = Style.text_width(txt, q["size"], Style.bold())
		Style.text(self, txt, pos2 + Vector2(1.5, 1.5) - Vector2(width * 0.5, 0), q["size"], Color(0, 0, 0, alpha * 0.7), Style.bold())
		Style.text(self, txt, pos2 - Vector2(width * 0.5, 0), q["size"], Color(col4.r, col4.g, col4.b, alpha), Style.bold())
