extends PanelContainer

@export var item : Item:
	set(value):
		item = value
		if item: 
			$Icon.texture = item.icon
		else:
			$Icon.texture = null


func _on_mouse_entered() -> void:
	if item != null:
		owner.set_description(item)
