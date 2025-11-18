extends CanvasLayer

@onready var resume_btn: Button = $overlay/menu/resume_btn
@onready var option_btn: Button = $overlay/menu/option_btn
@onready var quit_btn: Button = $overlay/menu/quit_btn

@onready var animator: AnimationPlayer = $overlay/animator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Necessário para permitir clique durante o pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	option_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	
	visible = false



## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
	# Se já estiver pausado, não abre de novo
		if get_tree().paused == false:
			visible = true
			animator.play("pause_game")
			get_tree().paused = true
			resume_btn.grab_focus() # teclado
		else:
			_on_resume_btn_pressed()


func _on_resume_btn_pressed() -> void:
	animator.play("resume_game")
	get_tree().paused = false
	await animator.animation_finished
	visible = false
	


func _on_option_btn_pressed() -> void:
	print("Options ainda não implementado")


func _on_quit_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Prefabs/Menu.tscn")
