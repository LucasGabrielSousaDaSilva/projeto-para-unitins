extends Area2D
## Cartão de resposta utilizado nas fases 3, 4 e Boss.
signal picked_up(pickup: Area2D, slot_index: int, answer: String)

@export var option_text: String = "22"
@export_range(0, 7, 1) var slot_index: int = 0
var disabled: bool = false
var touching: bool = false

func _ready() -> void:
	$AnswerLabel.text = option_text
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if disabled or touching or not body.is_in_group("player"):
		return
	touching = true
	picked_up.emit(self, slot_index, option_text)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		touching = false

func consume() -> void:
	disabled = true
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.16)
	tw.tween_callback(queue_free)
