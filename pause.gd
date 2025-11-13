extends CanvasLayer

@onready var resume_btn: Button = $overlay/menu/resume_btn
@onready var option_btn: Button = $overlay/menu/option_btn
@onready var quit_btn: Button = $overlay/menu/quit_btn

@onready var animator: AnimationPlayer = $overlay/animator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		visible= true
		animator.play("pause_game")
		get_tree().paused = true
		resume_btn.grab_focus()


func _on_resume_btn_pressed() -> void:
	animator.play("resume_game")
	get_tree().paused = false
	await animator.animation_finished
	visible = false
	


func _on_option_btn_pressed() -> void:
	pass # Replace with function body.


func _on_quit_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu.tscn")
