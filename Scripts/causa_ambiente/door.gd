extends Area2D

@export var next_level : String = ""
@export var destination_point : String = ""
@export var transition_controller : CanvasLayer
@onready var transition_animator := transition_controller.get_node("anim")

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body is Player:
		transition_animator.play("fade_in")
		await transition_animator.animation_finished
		Global.destination_level = get_parent().name
		Global.destination_point = destination_point
		get_tree().call_deferred("change_scene_to_file", next_level)
