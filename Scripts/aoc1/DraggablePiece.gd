class_name DraggablePiece
extends PanelContainer

@export var component_id: String = ""
@export var display_name: String = ""

var locked: bool = false

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _get_drag_data(_at_position: Vector2) -> Variant:
	if locked:
		return null

	var preview := duplicate() as Control

	if preview:
		preview.modulate.a = 0.8
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_drag_preview(preview)

	return {
		"id": component_id,
		"name": display_name,
		"piece": self
	}
