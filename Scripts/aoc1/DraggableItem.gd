extends TextureRect
class_name DraggableItem

@export var item_id: String = "CPU"
@export var display_name: String = "Processador"

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Cria a prévia visual que segue o cursor durante o arraste
	var preview := TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = size
	preview.modulate = Color(1, 1, 1, 0.7)
	
	var drag_container := Control.new()
	drag_container.add_child(preview)
	preview.position = -size / 2.0
	set_drag_preview(drag_container)
	
	# Retorna os dados que a zona de encaixe irá ler
	return {
		"id": item_id,
		"name": display_name,
		"texture": texture
	}
