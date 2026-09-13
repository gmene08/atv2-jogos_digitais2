extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area_golpe: Area2D = $AreaGolpe

@export var dano_do_golpe: int = 2
@export var quadro_do_golpe: int = 3
var golpe_aplicado: bool = false

enum PlayerState{
	idle,
	walk,
	jump,
	hurt,
	attack
}

@export var tempo_hurt: float = 0.4
var tempo_no_hurt: float = 0.0

@export var vida_maxima: int = 5
var vida: int

var max_jump_count = 2
var jump_count = 0

var direction = 0
var status: PlayerState

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

func idle_state()->void:
	move()
	
	if(velocity.x != 0):
		go_to_walk_state()
		return
		
	if(Input.is_action_just_pressed("jump")):
		go_to_jump_state()
		return
	
	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return
	
func walk_state()-> void:
	move()
	
	if(velocity.x == 0):
		go_to_idle_state()
		return
	
	if(Input.is_action_just_pressed("jump")):
		go_to_jump_state()
		return
	
	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return
		
func jump_state()-> void:
	move()
	
	if Input.is_action_just_pressed("jump") and jump_count<max_jump_count:
		go_to_jump_state()
	
	if is_on_floor():
		jump_count = 0;
		
		if(velocity.x != 0):
			go_to_walk_state()
		else:
			go_to_idle_state()
		return

func hurt_state() -> void:
	tempo_no_hurt += get_physics_process_delta_time()
	if tempo_no_hurt >= tempo_hurt:
		go_to_idle_state()
		return

func attack_state() -> void:
	if not golpe_aplicado and animated_sprite_2d.frame >= quadro_do_golpe:
		golpe_aplicado = true
		for corpo in area_golpe.get_overlapping_bodies():
			if corpo != self and corpo.has_method("levar_dano"):
				corpo.levar_dano(dano_do_golpe)

	if not animated_sprite_2d.is_playing():
		area_golpe.monitoring = false
		go_to_idle_state()
		return

func go_to_idle_state()-> void:
	status = PlayerState.idle
	animated_sprite_2d.play("idle")
	animated_sprite_2d.modulate = Color(1, 1, 1)

func go_to_walk_state()-> void:
	status = PlayerState.walk
	animated_sprite_2d.play("walk")

func go_to_jump_state()-> void:
	jump_count += 1
	
	status = PlayerState.jump
	animated_sprite_2d.play("jump")
	velocity.y = JUMP_VELOCITY

func go_to_hurt_state() -> void:
	status = PlayerState.hurt
	animated_sprite_2d.play("hurt")
	area_golpe.monitoring = false
	tempo_no_hurt = 0.0
	velocity.x = 0
	animated_sprite_2d.modulate = Color(1, 0.4, 0.4)

func go_to_attack_state() -> void:
	status = PlayerState.attack
	animated_sprite_2d.play("attack")
	velocity.x = 0
	golpe_aplicado = false
	area_golpe.monitoring = true

func update_direction()-> void:
	direction = Input.get_axis("left", "right")
	if direction > 0:
			animated_sprite_2d.flip_h=false
			area_golpe.position.x = abs(area_golpe.position.x)
	elif direction < 0:
			animated_sprite_2d.flip_h=true
			area_golpe.position.x = -abs(area_golpe.position.x)

func move()-> void:
	update_direction()
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
func levar_dano(quantidade: int) -> void:
	if status == PlayerState.hurt:
		return
	vida -= quantidade
	print("vida: ", vida)
	if vida <= 0:
		morrer()
		return
	go_to_hurt_state()



func morrer() -> void:
	status = PlayerState.hurt
	animated_sprite_2d.play("death")
	velocity.x = 0
	set_physics_process(false)

func _ready() -> void:
	vida = vida_maxima
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match status:
		PlayerState.idle:
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.jump:
			jump_state()
		PlayerState.hurt:
			hurt_state()
		PlayerState.attack:
			attack_state()
	
	move_and_slide()
			

#func _physics_process(delta: float) -> void:
	#direction = Input.get_axis("left", "right")
	#
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
##
	### Handle jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
##
	### Get the input direction and handle the movement/deceleration.
	### As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("left", "right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
	#
	#if direction > 0:
			#animated_sprite_2d.flip_h=false
	#elif direction < 0:
			#animated_sprite_2d.flip_h=true
	#
	#if is_on_floor():
		#if direction != 0:
			#animated_sprite_2d.play("walk")
		#else:
			#animated_sprite_2d.play('idle')
	#else:
		#animated_sprite_2d.play("jump")
#
	#move_and_slide()
