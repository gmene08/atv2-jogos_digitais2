extends CharacterBody2D
enum ZumbiState { idle, chase, attack, hurt, death }

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_ataque: Area2D = $AreaAtaque


@export var vida_maxima: int = 3
@export var velocidade: float = 40.0
@export var dano: int = 1
@export var distancia_de_ataque: float = 60.0
@export var distancia_de_visao: float = 130.0
@export var animacao_de_andar: String = "walk"
@export var tempo_entre_ataques: float = 1.2
@export var quadro_do_golpe: int = 5
@export var tempo_hurt: float = 0.7


var tempo_no_hurt: float = 0.0
var golpe_aplicado: bool = false
var tempo_do_ataque: float = 0.0

var vida: int
var status: ZumbiState

func _ready() -> void:
	vida = vida_maxima
	go_to_idle_state()



func go_to_idle_state() -> void:
	status = ZumbiState.idle
	animated_sprite_2d.play("idle")
	velocity.x = 0
	
func go_to_chase_state() -> void:
	status = ZumbiState.chase
	animated_sprite_2d.play(animacao_de_andar)

func go_to_attack_state() -> void:
	golpe_aplicado = false
	status = ZumbiState.attack
	animated_sprite_2d.play("attack")
	velocity.x = 0
	tempo_do_ataque = 0.0
	area_ataque.monitoring = true

func go_to_hurt_state() -> void:
	status = ZumbiState.hurt
	animated_sprite_2d.play("hurt")
	velocity.x = 0
	tempo_no_hurt = 0.0
	area_ataque.monitoring = false

func go_to_death_state() -> void:
	status = ZumbiState.death
	animated_sprite_2d.play("death")
	velocity.x = 0
	area_ataque.monitoring = false
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)
	await animated_sprite_2d.animation_finished
	queue_free()

func idle_state() -> void:
	var p := alvo()
	if p == null:
		return
	if global_position.distance_to(p.global_position) <= distancia_de_visao:
		go_to_chase_state()
		return

func chase_state() -> void:
	var p := alvo()
	if p == null:
		go_to_idle_state()
		return
		
	var distancia := global_position.distance_to(p.global_position)
	if distancia > distancia_de_visao:
		go_to_idle_state()
		return
	
	if distancia <= distancia_de_ataque:
		go_to_attack_state()
		return
	
	var lado := signf(p.global_position.x - global_position.x)
	velocity.x = lado * velocidade
	animated_sprite_2d.flip_h = lado < 0
	area_ataque.position.x = abs(area_ataque.position.x) * lado

func attack_state() -> void:
	tempo_do_ataque += get_physics_process_delta_time()
	if not golpe_aplicado and animated_sprite_2d.frame >= quadro_do_golpe:
		golpe_aplicado = true
		for corpo in area_ataque.get_overlapping_bodies():
			if corpo != self and corpo.is_in_group("player") and corpo.has_method("levar_dano"):
				corpo.levar_dano(dano)
	
	if tempo_do_ataque >= tempo_entre_ataques:
		area_ataque.monitoring = false
		var p := alvo()
		
		if p != null and global_position.distance_to(p.global_position) <= distancia_de_ataque:
			go_to_attack_state()
		else:
			go_to_chase_state()
			return

func hurt_state() -> void:
	tempo_no_hurt += get_physics_process_delta_time()
	if tempo_no_hurt >= tempo_hurt:
		go_to_chase_state()
		return
		
func levar_dano(quantidade: int) -> void:
	if status == ZumbiState.death or status == ZumbiState.hurt:
		return
	vida -= quantidade
	if vida <= 0:
		go_to_death_state()
		return
	go_to_hurt_state()

func alvo() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match status:
		ZumbiState.idle:
			idle_state()
		ZumbiState.chase:
			chase_state()
		ZumbiState.attack:
			attack_state()
		ZumbiState.hurt:
			hurt_state()
		ZumbiState.death:
			pass
			
	move_and_slide()
