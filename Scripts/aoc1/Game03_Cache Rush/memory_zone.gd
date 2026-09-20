extends Area2D

signal player_entered(zone)
signal player_exited(zone)

@export var memory_name: String = "L1"
@export var points: int = 100
@export var memory_index: int = 0
@export var subtitle_text: String = "Descrição"

var contains_target: bool = false
var player_inside: bool = false

@onready var body_panel = $BodyPanel
@onready var title = $Title
@onready var subtitle = $Subtitle
@onready var status_label = $StatusLabel


func _ready():
	title.text = memory_name
	subtitle.text = subtitle_text

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		status_label.text = "PRESSIONE E"
		player_entered.emit(self)


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		status_label.text = ""
		player_exited.emit(self)


func set_target(value: bool):
	contains_target = value
