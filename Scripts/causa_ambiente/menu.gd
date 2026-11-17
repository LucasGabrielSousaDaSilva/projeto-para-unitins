extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Missoes.voltar_ao_menu()


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func _on_start_pressed() -> void:
	Missoes.iniciar_nova_partida()
	get_tree().change_scene_to_file("res://Scenes/unitins.tscn")


func _on_option_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit()
