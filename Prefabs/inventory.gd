extends CanvasLayer

@export var animation : AnimationPlayer

@export var description : NinePatchRect

var is_open := false

func _ready() -> void:
	visible = false
	


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Clique_TAB"):
		_toggle_inventory()
		get_viewport().set_input_as_handled() # impede que o jogo receba TAB

func _toggle_inventory() -> void:
	if is_open:
		_close_inventory()
	else:
		_open_inventory()

func _open_inventory() -> void:
	is_open = true
	visible = true
	animation.play("Start_inventory")  # animação de entrada
	

func _close_inventory() -> void:
	is_open = false
	animation.play("hide_inventory")  # sua animação de saída
	await animation.animation_finished
	visible = false

func set_description(item : Item):
	description.find_child("Name").text = item.title
	description.find_child("Icon").texture = item.icon
	description.find_child("Descricao").text = item.description
