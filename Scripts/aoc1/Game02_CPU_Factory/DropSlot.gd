@tool
class_name DropSlot
extends PanelContainer

signal component_placed(slot: DropSlot, component_id: String)

@export var expected_component: String = ""

## Texto pequeno no topo do encaixe (ex.: "SLOT 01").
@export var slot_label: String = "":
	set(value):
		slot_label = value
		_refresh_labels()

## Cor do encaixe vazio / destacado.
@export var accent_color: Color = Color(0.22, 0.66, 1.0):
	set(value):
		accent_color = value
		if is_node_ready():
			_build_styles()
			_apply_style()

# Estilos opcionais. Se ficarem vazios, são gerados automaticamente.
@export var normal_style: StyleBoxFlat
@export var hover_style: StyleBoxFlat
@export var filled_style: StyleBoxFlat

var current_component: String = ""
var current_piece: DraggablePiece = null

var _custom_normal := false
var _custom_hover := false
var _custom_filled := false
var _hovering := false
var _fill_color := Color(0.3, 0.9, 0.55)


func _ready() -> void:
	_custom_normal = normal_style != null
	_custom_hover = hover_style != null
	_custom_filled = filled_style != null
	_build_styles()
	_apply_style()
	_refresh_labels()
	_refresh_icon()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# destaca o encaixe sob o mouse enquanto uma peça está sendo arrastada
	var over := false
	if get_viewport().gui_is_dragging():
		over = get_global_rect().has_point(get_global_mouse_position())
	if over != _hovering:
		_hovering = over
		_apply_style()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_hovering = false
		_apply_style()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("id")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return

	if not data.has("piece"):
		return

	var piece := data["piece"] as DraggablePiece

	if piece == null:
		return

	# Se já existia uma peça neste slot, devolve ela.
	if current_piece != null:
		current_piece.visible = true
		current_piece.locked = false

	current_component = str(data["id"])
	current_piece = piece

	piece.visible = false
	_fill_color = piece.accent_color
	_hovering = false

	_build_styles()
	_apply_style()
	_update_visual(piece.display_name)
	_refresh_icon()
	queue_redraw()

	component_placed.emit(self, current_component)


func _update_visual(component_name: String) -> void:
	var label := get_node_or_null("Label") as Label

	if label:
		label.text = component_name
		label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))


func is_correct() -> bool:
	return current_component == expected_component


func reset_slot() -> void:
	if current_piece:
		current_piece.visible = true
		current_piece.locked = false

	current_piece = null
	current_component = ""
	_hovering = false

	_apply_style()

	var label := get_node_or_null("Label") as Label

	if label:
		label.text = "?????"
		label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.72))

	_refresh_icon()
	queue_redraw()


# ------------------------------------------------------------------ visual

func _make_style(bg: Color, border: Color, width: int, glow: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(8)
	if glow > 0.0:
		sb.shadow_color = Color(border, 0.45)
		sb.shadow_size = int(glow)
	return sb


func _build_styles() -> void:
	if not _custom_normal:
		normal_style = _make_style(Color(0.04, 0.09, 0.16), Color(accent_color, 0.45), 2, 0.0)
	if not _custom_hover:
		hover_style = _make_style(Color(0.07, 0.17, 0.27), Color(accent_color, 1.0), 3, 14.0)
	if not _custom_filled:
		filled_style = _make_style(Color(_fill_color, 0.12).blend(Color(0.04, 0.09, 0.16)), Color(_fill_color, 0.95), 2, 8.0)


func _apply_style() -> void:
	var sb: StyleBoxFlat
	if _hovering and hover_style:
		sb = hover_style
	elif current_piece != null and filled_style:
		sb = filled_style
	else:
		sb = normal_style
	if sb:
		add_theme_stylebox_override("panel", sb)
	queue_redraw()


func _refresh_labels() -> void:
	var top := get_node_or_null("NameLabel2") as Label
	if top:
		top.text = slot_label if not slot_label.is_empty() else "SLOT"


func _refresh_icon() -> void:
	var icon := get_node_or_null("Icon") as ComponentIcon
	if icon == null:
		return
	if current_piece != null:
		icon.kind = StringName(current_component)
		icon.color = _fill_color
	else:
		icon.kind = &"empty"
		icon.color = Color(accent_color, 0.9)


func _draw() -> void:
	# marcas de canto (estilo soquete de processador)
	var c := Color(accent_color, 0.9) if current_piece == null else Color(_fill_color, 0.9)
	var m := 6.0
	var l := 12.0
	var w := 2.0
	var r := Rect2(Vector2(m, m), size - Vector2(m, m) * 2.0)
	for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var sx := 1.0 if corner.x <= r.position.x + 0.5 else -1.0
		var sy := 1.0 if corner.y <= r.position.y + 0.5 else -1.0
		draw_line(corner, corner + Vector2(l * sx, 0), c, w)
		draw_line(corner, corner + Vector2(0, l * sy), c, w)

	# furos de contato (soquete LGA) enquanto vazio
	if current_piece == null:
		var dots := Color(accent_color, 0.16)
		var x := 18.0
		while x < size.x - 12.0:
			var y := 18.0
			while y < size.y - 12.0:
				draw_circle(Vector2(x, y), 1.4, dots)
				y += 12.0
			x += 12.0
