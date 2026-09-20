extends Node

@export_node_path("Label") var terminal_path: NodePath
@onready var terminal_label: Label = get_node(terminal_path)

func _on_power_button_pressed() -> void:
	var slots := get_tree().get_nodes_in_group("slots")
	
	for slot in slots:
		var slot_node = slot as SlotZone
		
		# 1. Verifica slots vazios
		if slot_node.current_item_data.is_empty():
			_update_terminal("FALHA DE HARDWARE\nCircuito incompleto: Encaixe ausente em '%s'." % slot_node.slot_name, false)
			return
		
		# 2. Verifica se a peça posicionada está incorreta
		if slot_node.current_item_data["id"] != slot_node.expected_item_id:
			var wrong_piece: String = slot_node.current_item_data["name"]
			var destination: String = slot_node.slot_name
			_update_terminal("FALHA DE HARDWARE\nA peça '%s' não pode ocupar o lugar de '%s'." % [wrong_piece, destination], false)
			return

	# 3. Sucesso total
	_update_terminal("BOOT CONCLUÍDO\nCPU operacional.", true)

func _update_terminal(message: String, is_success: bool) -> void:
	terminal_label.text = message
	terminal_label.modulate = Color.GREEN if is_success else Color.RED
