extends RefCounted
## Paleta, fontes e helpers de desenho compartilhados pela fase Cache Rush.
## Uso: const Style = preload("res://Scripts/aoc1/Game03_Cache Rush/cache_style.gd")

const CYAN := Color("#56d6ff")
const GREEN := Color("#4cd98a")
const RED := Color("#ff5d6c")
const AMBER := Color("#ffc247")
const ORANGE := Color("#ff8c42")
const TEXT := Color("#e8f6ff")
const DIM := Color("#8fb4c4")
const PANEL := Color("#0d1a22")

## Cor de cada nível da hierarquia (Registradores → Armazenamento)
const LEVEL_COLORS := [
	Color("#f4c542"),
	Color("#56d6ff"),
	Color("#3aa1ff"),
	Color("#7868ff"),
	Color("#48c774"),
	Color("#ff8c42"),
]

static var _boxes: Dictionary = {}
static var _boxes_top: Dictionary = {}
static var _bold: Font = null
static var _mono: Font = null


static func ui() -> Font:
	return ThemeDB.fallback_font


static func bold() -> Font:
	if _bold == null:
		var fv := FontVariation.new()
		fv.base_font = ThemeDB.fallback_font
		fv.variation_embolden = 0.7
		_bold = fv
	return _bold


static func mono() -> Font:
	if _mono == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray([
			"Consolas", "Cascadia Mono", "Menlo", "DejaVu Sans Mono",
			"Liberation Mono", "Courier New", "monospace"
		])
		f.font_weight = 700
		_mono = f
	return _mono


## Caixa arredondada (com borda e brilho opcionais), em cache para não
## criar um StyleBox novo a cada frame.
static func box(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 8,
		border_w: int = 0, glow: Color = Color(0, 0, 0, 0), glow_size: int = 0) -> StyleBoxFlat:
	var key := "%s|%s|%d|%d|%s|%d" % [bg.to_html(true), border.to_html(true),
			radius, border_w, glow.to_html(true), glow_size]
	if _boxes.has(key):
		return _boxes[key]
	if _boxes.size() > 700:
		_boxes.clear()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_w)
	sb.border_color = border
	sb.shadow_color = glow
	sb.shadow_size = glow_size
	sb.anti_aliasing = true
	_boxes[key] = sb
	return sb


## Caixa só com os cantos de cima arredondados (faixa de cabeçalho).
static func box_top(bg: Color, radius: int = 8) -> StyleBoxFlat:
	var key := "%s|%d" % [bg.to_html(true), radius]
	if _boxes_top.has(key):
		return _boxes_top[key]
	if _boxes_top.size() > 300:
		_boxes_top.clear()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.anti_aliasing = true
	_boxes_top[key] = sb
	return sb


static func text(ci: CanvasItem, s: String, pos: Vector2, size: int, color: Color,
		font: Font = null, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		width: float = -1.0) -> void:
	if font == null:
		font = ui()
	ci.draw_string(font, pos, s, align, width, size, color)


static func text_width(s: String, size: int, font: Font = null) -> float:
	if font == null:
		font = ui()
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## 100000 -> "100.000"
static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	if n < 0:
		out = "-" + out
	return out


## 100000 -> "100k"
static func fmt_short(n: int) -> String:
	if n >= 1000:
		return "%dk" % int(n / 1000)
	return str(n)


static func hex(tag: int) -> String:
	return "0x%02X" % tag


## Posição e direção a uma certa distância ao longo de uma polilinha.
static func point_at(pts: PackedVector2Array, dist: float) -> Dictionary:
	var remaining := dist
	for i in range(pts.size() - 1):
		var seg := pts[i + 1] - pts[i]
		var l := seg.length()
		if l <= 0.001:
			continue
		if remaining <= l:
			return {"pos": pts[i] + seg * (remaining / l), "dir": seg / l}
		remaining -= l
	var last_dir := Vector2.RIGHT
	if pts.size() >= 2:
		last_dir = (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized()
	return {"pos": pts[pts.size() - 1], "dir": last_dir}


static func poly_length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total
