@tool
class_name DraggablePiece
extends PanelContainer

@export var component_id: String = "":
	set(value):
		component_id = value
		_refresh()
## Nome completo (aparece no encaixe depois de colocado).
@export var display_name: String = ""
## Título curto mostrado na peça. Se vazio, usa display_name em maiúsculas.
@export var title_text: String = "":
	set(value):
		title_text = value
		_refresh()
@export var detail_text: String = "":
	set(value):
		detail_text = value
		_refresh()
@export var accent_color: Color = Color(0.22, 0.66, 1.0):
	set(value):
		accent_color = value
		_refresh()

var locked: bool = false

var _normal: StyleBoxFlat
var _hover: StyleBoxFlat


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0


func _on_mouse_entered() -> void:
	if _hover and not locked:
		add_theme_stylebox_override("panel", _hover)


func _on_mouse_exited() -> void:
	if _normal:
		add_theme_stylebox_override("panel", _normal)


func _refresh() -> void:
	if not is_node_ready():
		return

	_normal = _make_style(Color(0.055, 0.12, 0.2), Color(accent_color, 0.8), 2, 0)
	_hover = _make_style(Color(0.09, 0.19, 0.3), accent_color, 3, 12)
	add_theme_stylebox_override("panel", _normal)

	var icon := get_node_or_null("Margin/VBox/Icon") as ComponentIcon
	if icon:
		icon.kind = StringName(component_id)
		icon.color = accent_color

	var title := get_node_or_null("Margin/VBox/NameLabel") as Label
	if title:
		title.text = title_text if not title_text.is_empty() else display_name.to_upper()
		title.add_theme_color_override("font_color", Color(0.93, 0.97, 1.0))

	var detail := get_node_or_null("Margin/VBox/DetailLabel") as Label
	if detail:
		detail.text = detail_text
		detail.add_theme_color_override("font_color", Color(accent_color, 0.9))


func _make_style(bg: Color, border: Color, width: int, glow: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(10)
	if glow > 0:
		sb.shadow_color = Color(border, 0.4)
		sb.shadow_size = glow
	return sb


func _get_drag_data(_at_position: Vector2) -> Variant:
	if locked:
		return null

	# prévia centralizada no cursor
	var preview := duplicate() as Control
	var holder := Control.new()

	if preview:
		preview.modulate.a = 0.9
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.size = size
		preview.position = -size * 0.5
		holder.add_child(preview)
		set_drag_preview(holder)

	modulate.a = 0.35

	return {
		"id": component_id,
		"name": display_name,
		"piece": self
	}
