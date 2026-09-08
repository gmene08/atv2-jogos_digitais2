extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

enum PlayerState{
	idle,
	walk,
	jump,
	duck
}

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
	
	if(Input.is_action_just_pressed("duck")):
		go_to_duck_state()
		return
	
func walk_state()-> void:
	move()
	
	if(velocity.x == 0):
		go_to_idle_state()
		return
	
	if(Input.is_action_just_pressed("jump")):
		go_to_jump_state()
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

func duck_state()->void:
	update_direction()
	
	if(Input.is_action_just_released("duck")):
		go_to_idle_state()
		exit_from_duck_state()

func go_to_idle_state()-> void:
	status = PlayerState.idle
	animated_sprite_2d.play("idle")

func go_to_walk_state()-> void:
	status = PlayerState.walk
	animated_sprite_2d.play("walk")

func go_to_jump_state()-> void:
	jump_count += 1
	
	status = PlayerState.jump
	animated_sprite_2d.play("jump")
	velocity.y = JUMP_VELOCITY

func go_to_duck_state()-> void:
	status = PlayerState.duck
	animated_sprite_2d.play("duck")
	
	collision_shape.shape.radius=5
	collision_shape.shape.height=10
	collision_shape.position.y=2
	
func exit_from_duck_state()-> void:
	collision_shape.shape.radius=6
	collision_shape.shape.height=16
	collision_shape.position.y=0
	
func update_direction()-> void:
	if direction > 0:
			animated_sprite_2d.flip_h=false
	elif direction < 0:
			animated_sprite_2d.flip_h=true

func move()-> void:
	update_direction()
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	
			

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	direction = Input.get_axis("left", "right")
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match status:
		PlayerState.idle:
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.jump:
			jump_state()
		PlayerState.duck:
			duck_state()
	
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
