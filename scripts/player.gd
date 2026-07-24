extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var direcao = "none"

func _physics_process(delta: float) -> void:
	player_movement(delta)
	
func player_movement(delta: float) -> void:
	
	if Input.is_action_pressed("ui_right"):
		direcao = "right"
		animacao(1)
		velocity.x = SPEED
		velocity.y = 0
		
	elif Input.is_action_pressed("ui_left"):
		direcao = "left"
		animacao(1)
		velocity.x = -SPEED
		velocity.y = 0
	
	elif Input.is_action_pressed("ui_up"):
		direcao = "up"
		animacao(1)
		velocity.x = 0
		velocity.y = -SPEED
		
	elif Input.is_action_pressed("ui_down"):
		direcao = "down"
		animacao(1)
		velocity.x = 0
		velocity.y = SPEED
	else:
		animacao(0)
		velocity.x = 0
		velocity.y = 0
	
	move_and_slide()

func animacao(mov):
	var dir_atual = direcao
	
	if direcao == "right":
		animated_sprite_2d.flip_h = false
		if mov == 1:
			animated_sprite_2d.play("walk_side")
		elif mov == 0:
			animated_sprite_2d.play("idle_side")
	
	if direcao == "left":
		animated_sprite_2d.flip_h = true
		if mov == 1:
			animated_sprite_2d.play("walk_side")
		elif mov == 0:
			animated_sprite_2d.play("idle_side")
	
	if direcao == "up":
		animated_sprite_2d.flip_h = false
		if mov == 1:
			animated_sprite_2d.play("walk_back")
		elif mov == 0:
			animated_sprite_2d.play("idle_back")
	
	if direcao == "down":
		animated_sprite_2d.flip_h = false
		if mov == 1:
			animated_sprite_2d.play("walk_front")
		elif mov == 0:
			animated_sprite_2d.play("idle_front")
