class_name DropSlot
extends PanelContainer

signal component_placed(slot: DropSlot, component_id: String)

@export var expected_component: String = ""

@export var normal_style: StyleBoxFlat
@export var hover_style: StyleBoxFlat
@export var filled_style: StyleBoxFlat

var current_component: String = ""
var current_piece: DraggablePiece = null


func _ready() -> void:
	if normal_style:
		add_theme_stylebox_override("panel", normal_style)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary and data.has("id"):
		if hover_style:
			add_theme_stylebox_override("panel", hover_style)

		return true

	return false


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

	if filled_style:
		add_theme_stylebox_override("panel", filled_style)

	_update_visual(piece.display_name)

	component_placed.emit(self, current_component)


func _update_visual(component_name: String) -> void:
	var label := get_node_or_null("Label") as Label

	if label:
		label.text = component_name


func is_correct() -> bool:
	return current_component == expected_component


func reset_slot() -> void:
	if current_piece:
		current_piece.visible = true
		current_piece.locked = false

	current_piece = null
	current_component = ""

	if normal_style:
		add_theme_stylebox_override("panel", normal_style)

	var label := get_node_or_null("Label") as Label

	if label:
		label.text = "?????"
