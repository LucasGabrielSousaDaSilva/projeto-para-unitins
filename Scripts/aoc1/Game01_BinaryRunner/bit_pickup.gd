extends Area2D
## Cada estação recebe dois itens: um zero e um um.
signal picked_up(pickup: Area2D, slot_index: int, bit_value: int)

@export_range(0, 1, 1) var bit_value: int = 0
@export_range(0, 3, 1) var slot_index: int = 0

var used: bool = false

func _ready() -> void:
	$BitLabel.text = str(bit_value)
	if bit_value == 0:
		$Glow.color = Color("145d83")
		$Core.color = Color("50ddff")
		$BitLabel.add_theme_color_override("font_color", Color("062436"))
	else:
		$Glow.color = Color("766521")
		$Core.color = Color("ffdd6a")
		$BitLabel.add_theme_color_override("font_color", Color("362a05"))
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if used or not body.is_in_group("player"):
		return
	used = true
	set_deferred("monitoring", false)
	picked_up.emit(self, slot_index, bit_value)
	var pulse: Tween = create_tween()
	pulse.tween_property(self, "scale", Vector2(1.4, 1.4), 0.10)
	pulse.tween_property(self, "scale", Vector2.ZERO, 0.17)
	pulse.tween_callback(queue_free)
