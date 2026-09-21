extends Area2D

signal player_entered(zone)
signal player_exited(zone)

@export var memory_name: String = "L1"
@export var points: int = 100
@export var memory_index: int = 0

@export_category("Text")
@export var subtitle_line_1: String = "Descricao1"
@export var subtitle_line_2: String = "Descricao2"

@export_category("Visual")
@export var panel_size: Vector2 = Vector2(180, 90)
@export var panel_color: Color = Color("#f4c542")

var contains_target: bool = false
var player_inside: bool = false

@onready var body_panel = $BodyPanel
@onready var title = $Title
@onready var subtitle = $Subtitle
@onready var status_label = $StatusLabel


func _ready():
	title.text = memory_name

	subtitle.text = (
		subtitle_line_1
		+ "\n"
		+ subtitle_line_2
	)

	_apply_visual()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _apply_visual():
	body_panel.size = panel_size

	var style := StyleBoxFlat.new()

	style.bg_color = panel_color
	
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	style.border_color = panel_color.lightened(0.25)

	body_panel.add_theme_stylebox_override("panel", style)

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
