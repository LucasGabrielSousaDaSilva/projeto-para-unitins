extends PanelContainer
class_name SlotZone

@export var expected_item_id: String = ""
@export var slot_name: String = "Slot"

var current_item_data: Dictionary = {}
var icon_display: TextureRect

func _ready() -> void:
	add_to_group("slots")
	
	# Verifica se já existe o nó filho; se não existir, cria um automaticamente
	if has_node("IconDisplay"):
		icon_display = $IconDisplay
	else:
		icon_display = TextureRect.new()
		icon_display.name = "IconDisplay"
		icon_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(icon_display)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	current_item_data = data
	if icon_display:
		icon_display.texture = data["texture"]
		icon_display.visible = true

func clear_slot() -> void:
	current_item_data.clear()
	if icon_display:
		icon_display.texture = null
		icon_display.visible = false
