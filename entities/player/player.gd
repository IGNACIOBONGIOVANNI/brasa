class_name Player
extends CharacterBody2D
## Jugador. Lee el input (con buffer) y delega en su StateMachine: Move (caminar, apuntar,
## disparar, Pulso, bomba, recargar, cambiar de arma, usar el activo), Roll (rodar con i-frames)
## y Dead. Su personaje, stats, items y armas salen de RunState.
## Se apunta con el último dispositivo usado: mover el mouse vuelve a la mira por mouse,
## inclinar el stick derecho la pasa al stick.

const GROUP: StringName = &"player"
const STICK_AIM_DEADZONE: float = 0.35
## Acciones que pasan por el InputBuffer.
const BUFFERED_ACTIONS: Array[StringName] = [
	&"shoot", &"dodge", &"blank", &"bomb", &"reload", &"swap_weapon", &"use_active",
]
const HURT_FLASH_TIME: float = 0.12
const HURT_TRAUMA: float = 0.6
const HURT_HITSTOP: float = 0.08
const HURT_BURST_COLOR: Color = Color("e0464e")
const PULSE_TRAUMA: float = 0.5
## El Pulso empuja a los enemigos que estén a esta distancia o menos.
const PULSE_PUSH_RADIUS: float = 90.0
const PULSE_PUSH_FORCE: float = 180.0
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const PULSE_WAVE_SCENE: PackedScene = preload("res://fx/pulse_wave.tscn")
const BOMB_SCENE: PackedScene = preload("res://entities/bomb/bomb.tscn")

@export var acceleration: float = 1000.0
@export var friction: float = 1200.0

@export_group("Rodar")
@export var roll_speed: float = 200.0
@export var roll_time: float = 0.32
## Espera después de rodar antes de poder volver a hacerlo.
@export var roll_cooldown: float = 0.3

var aim_direction: Vector2 = Vector2.RIGHT
## Velocidad que viene del input, sin el empujón de los golpes.
var move_velocity: Vector2 = Vector2.ZERO
var input_buffer: InputBuffer = InputBuffer.new()
var _aim_with_mouse: bool = true
var _roll_cooldown_left: float = 0.0

@onready var visual: PlayerVisual = $Visual
@onready var weapon: WeaponComponent = $WeaponComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var flash: FlashComponent = $FlashComponent
@onready var machine: StateMachine = $StateMachine
@onready var hooks: ItemHookRunner = $ItemHookRunner


func _ready() -> void:
	add_to_group(GROUP)
	weapon.fired.connect(_on_weapon_fired)
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	visual.set_body_color(RunState.character.body_color)
	RunState.weapons_changed.connect(_sync_weapon)
	RunState.stats_changed.connect(_on_stats_changed)
	_sync_weapon()
	_on_stats_changed(RunState.stats)
	machine.start()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_aim_with_mouse = true


func _physics_process(delta: float) -> void:
	input_buffer.advance(delta)
	for action: StringName in BUFFERED_ACTIONS:
		if Input.is_action_just_pressed(action):
			input_buffer.press(action)
	_roll_cooldown_left = maxf(0.0, _roll_cooldown_left - delta)
	machine.physics_update(delta)


func is_dead() -> bool:
	return health.is_dead()


func read_move_input() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


## Acelera hacia `target_velocity` (o frena si es cero) y mueve el cuerpo.
func move_toward_velocity(target_velocity: Vector2, delta: float) -> void:
	var rate: float = acceleration if target_velocity != Vector2.ZERO else friction
	move_velocity = move_velocity.move_toward(target_velocity, rate * delta)
	apply_velocity()


## Mueve el cuerpo con move_velocity más el empujón de los golpes.
func apply_velocity() -> void:
	velocity = move_velocity + knockback.velocity
	move_and_slide()


## Frena en seco (al aparecer en otra sala).
func stop_motion() -> void:
	move_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	knockback.velocity = Vector2.ZERO


func update_aim() -> void:
	var stick: Vector2 = Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	if stick.length() > STICK_AIM_DEADZONE:
		_aim_with_mouse = false
		aim_direction = stick.normalized()
	elif _aim_with_mouse:
		var to_mouse: Vector2 = get_global_mouse_position() - weapon.global_position
		if to_mouse.length() > 1.0:
			aim_direction = to_mouse.normalized()
	visual.set_aim(aim_direction)


## Dispara mientras se mantiene el botón, o si se apretó hace muy poco y el arma recién está lista.
func try_shoot(delta: float) -> void:
	if Input.is_action_pressed(&"shoot") or input_buffer.is_buffered(&"shoot"):
		if weapon.trigger(RunState.stats, aim_direction, delta):
			input_buffer.consume(&"shoot")
	else:
		weapon.idle(RunState.stats)


## Recargar, cambiar de arma y usar el activo.
func try_weapon_actions() -> void:
	if input_buffer.consume(&"reload"):
		weapon.reload()
	if input_buffer.consume(&"swap_weapon") and RunState.select_next_weapon():
		AudioManager.play_sfx(&"weapon_swap")
	if input_buffer.consume(&"use_active"):
		_use_active()


func can_roll() -> bool:
	return _roll_cooldown_left <= 0.0


func start_roll_cooldown() -> void:
	_roll_cooldown_left = roll_cooldown


## Si se apretó el botón y quedan cargas, usa un Pulso: borra todas las balas enemigas y empuja
## a los enemigos cercanos.
func try_pulse() -> void:
	if not input_buffer.consume(&"blank"):
		return
	if not RunState.use_blank():
		AudioManager.play_sfx(&"empty")
		return
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		var bullet := node as Bullet
		if bullet != null and bullet.is_hostile_to_player():
			bullet.destroy()
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() <= PULSE_PUSH_RADIUS:
			enemy.knockback.apply(offset, PULSE_PUSH_FORCE)
	Fx.spawn(get_tree(), PULSE_WAVE_SCENE, global_position)
	EventBus.shake_requested.emit(PULSE_TRAUMA)
	AudioManager.play_sfx(&"pulse")


## Si se apretó el botón y quedan bombas, deja una a los pies.
func try_bomb() -> void:
	if not input_buffer.consume(&"bomb"):
		return
	if not RunState.use_bomb():
		AudioManager.play_sfx(&"empty")
		return
	Fx.spawn(get_tree(), BOMB_SCENE, global_position + Vector2(0, 2), Fx.ENTITIES_GROUP)
	AudioManager.play_sfx(&"bomb_place")


func _on_hurt(info: HitInfo) -> void:
	knockback.apply(info.direction, info.knockback)
	flash.flash(HURT_FLASH_TIME)
	if not health.is_dead():
		flash.blink(health.invulnerability_after_hit)
	EventBus.shake_requested.emit(HURT_TRAUMA)
	EventBus.hitstop_requested.emit(HURT_HITSTOP)
	EventBus.player_damaged.emit(info.damage)
	AudioManager.play_sfx(&"player_hurt", 0.05)
	var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position + Vector2(0, -2)) as CPUParticles2D
	burst.color = HURT_BURST_COLOR
	burst.amount = 8


func _on_died() -> void:
	machine.transition_to(&"Dead")


func _on_weapon_fired(direction: Vector2) -> void:
	visual.play_fire()
	hooks.on_shoot(direction)


func _use_active() -> void:
	if not RunState.is_active_ready():
		AudioManager.play_sfx(&"empty")
		return
	if hooks.use_active():
		RunState.spend_active()
		AudioManager.play_sfx(&"active_use")


func _sync_weapon() -> void:
	weapon.slot = RunState.current_weapon_slot()
	visual.set_gun(weapon.weapon().gun_color, weapon.weapon().gun_length)


## Un item de vida máxima agranda (y llena) los contenedores.
func _on_stats_changed(stats: StatBlock) -> void:
	health.set_max(stats.max_health)
