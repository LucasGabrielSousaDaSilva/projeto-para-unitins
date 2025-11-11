extends CharacterBody2D
class_name Player

@onready var sprite: Sprite2D = $Boy
@onready var animate: AnimatedSprite2D = $Animated


const speed = 300.0
var is_dead = false
	

func _physics_process(_delta: float) -> void:
	if is_dead:
		$Animated.play("death")
		return
	
		# Modificar a velocidade
	read_input()
	move_and_slide()

func read_input() -> void:
	# Obter o input vector
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	
	input_vector = input_vector.normalized()
	velocity = input_vector * speed
	move_and_slide()
	
		# Controle de animações
	if input_vector == Vector2.ZERO:
		$Animated.play("idle")
	else:
		$Animated.play("run")
	
	if input_vector.x > 0:
		$Animated.flip_h = true
	elif input_vector.x < 0:
		$Animated.flip_h = false
	
func stop_caracter():
	velocity = Vector2.ZERO
	$Animated.play("stop")
		
	
func death_caracter():
	is_dead = true
	velocity = Vector2.ZERO
	$Animated.play("death")
	
