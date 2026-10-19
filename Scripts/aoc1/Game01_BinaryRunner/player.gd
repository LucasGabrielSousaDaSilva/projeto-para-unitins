extends CharacterBody2D
## Jogador controlado por A/D ou setas; W, seta para cima ou Espaço para pular.
signal damaged

@export var move_speed: float = 320.0
@export var jump_velocity: float = -540.0
@export var gravity_force: float = 1080.0

var controls_enabled: bool = true
var invulnerable: bool = false

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		return

	if not is_on_floor():
		velocity.y += gravity_force * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed
	move_and_slide()
	position.x = clampf(position.x, 30.0, 3260.0)

func take_damage() -> void:
	if invulnerable or not controls_enabled:
		return
	invulnerable = true
	damaged.emit()
	if not controls_enabled:
		return

	var flash: Tween = create_tween()
	for i in range(4):
		flash.tween_property(self, "modulate", Color(1.0, 0.35, 0.4, 0.55), 0.10)
		flash.tween_property(self, "modulate", Color.WHITE, 0.10)
	await flash.finished
	invulnerable = false

func stop_player() -> void:
	controls_enabled = false
	velocity = Vector2.ZERO
