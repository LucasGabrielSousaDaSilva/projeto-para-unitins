extends Area2D
signal player_entered

var activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if activated or not body.is_in_group("player"):
		return
	activated = true
	player_entered.emit()

func show_success() -> void:
	$Frame.color = Color("2fdbac")
	$GateLabel.text = "ACESSO\nLIBERADO"

func show_failure() -> void:
	$Frame.color = Color("ff4f73")
	$GateLabel.text = "ACESSO\nNEGADO"
