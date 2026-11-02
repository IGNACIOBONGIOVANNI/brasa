class_name Player
extends CharacterBody2D
## Jugador. Lee el input (con buffer) y delega en su StateMachine: Move (caminar, apuntar,
## disparar, Pulso, bomba, recargar, cambiar de arma, usar el activo), Roll (rodar con i-frames),
## Charge (la embestida de los que esquivan embistiendo, CharacterData.Dodge.CHARGE) y Dead. Su personaje, stats, items y armas salen de RunState.
## Armazones (mechas): `board()` lo sube (lo llama ParkedMech al tocarlo). Mientras maneja, los golpes
## le sacan blindaje (`mech_armor`, el hurtbox apunta ahí) en vez de vida, camina a la velocidad del
## armazón, dispara su arma y no cambia de arma; rodar lo hace saltar afuera (`eject`: el armazón queda
## parado con lo que le quedaba) y si el blindaje llega a cero revienta, lastima a los enemigos cerca
## y lo deja invulnerable un momento.
## Se apunta con el último dispositivo usado: mover el mouse vuelve a la mira por mouse,
## inclinar el stick derecho la pasa al stick.

## Mantuvo el botón de cambiar de arma: abrir la rueda (WeaponWheel, en el HUD).
signal weapon_wheel_requested

## Subió o bajó de un armazón (null al bajar).
signal mech_changed(mech: MechData)

const GROUP: StringName = &"player"
const STICK_AIM_DEADZONE: float = 0.35
## Tocar el botón de cambiar de arma pasa a la siguiente; mantenerlo esto abre la rueda.
const WHEEL_HOLD_TIME: float = 0.22
## Teclas que equipan cada arma directo (1 a 9).
const WEAPON_KEYS: Array[StringName] = [&"weapon_1", &"weapon_2", &"weapon_3", &"weapon_4", &"weapon_5",
		&"weapon_6", &"weapon_7", &"weapon_8", &"weapon_9"]
## Acciones que pasan por el InputBuffer.
const BUFFERED_ACTIONS: Array[StringName] = [
	&"shoot", &"dodge", &"blank", &"bomb", &"reload", &"use_active",
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
const STEP_DUST_SCENE: PackedScene = preload("res://fx/step_dust.tscn")
const LIGHT_FLASH_SCENE: PackedScene = preload("res://fx/light_flash.tscn")
## Bomba: tocar la pone a los pies; mantener más de BOMB_HOLD_TIME apunta (marca dónde cae) y al
## soltar la tira. Con el mouse cae donde apunta; con el stick, más lejos cuanto más se mantiene.
const BOMB_HOLD_TIME: float = 0.2
const BOMB_THROW_MIN: float = 32.0
const BOMB_THROW_MAX: float = 120.0
const BOMB_CHARGE_TIME: float = 0.6
## Cae a esta distancia de la pared o roca que se cruce.
const BOMB_WALL_MARGIN: float = 6.0
## Cada cuántos píxeles caminados se levanta polvo.
const STEP_DISTANCE: float = 14.0
## Cuánto se aviva la luz con cada disparo.
const FIRE_LIGHT_PULSE: float = 0.35
const PULSE_LIGHT_COLOR: Color = Color("bfe9ff")
const PARKED_MECH_SCENE: PackedScene = preload("res://entities/mechs/parked_mech.tscn")
## Arriba de un armazón los golpes empujan mucho menos.
const MECH_KNOCKBACK: float = 0.25
## Cuando el armazón revienta: radio y daño a los enemigos, e invulnerabilidad del jugador.
const MECH_BLAST_RADIUS: float = 40.0
const MECH_BLAST_DAMAGE: float = 12.0
const MECH_BREAK_IFRAMES: float = 1.2
const MECH_BREAK_TRAUMA: float = 0.8

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
## Cuánto hace que se mantiene el botón de cambiar de arma (-1 = suelto o ya resuelto).
var _swap_hold: float = -1.0
var _step_left: float = STEP_DISTANCE
## Segundos que se viene manteniendo el botón de bomba (negativo = no se está apretando).
var _bomb_hold: float = -1.0
## Regla de la sala Sin Pulso.
var _pulse_locked: bool = false
## El armazón que maneja (null = a pie).
var mech: MechData
## Viento que lo empuja este tick (Player.push) y en qué tick llegó.
var _wind: Vector2 = Vector2.ZERO
var _wind_tick: int = -10

@onready var visual: PlayerVisual = $Visual
@onready var weapon: WeaponComponent = $WeaponComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var flash: FlashComponent = $FlashComponent
@onready var machine: StateMachine = $StateMachine
@onready var hooks: ItemHookRunner = $ItemHookRunner
@onready var light: FlickerLight = $Light
@onready var bomb_aim: BombAim = $BombAim
@onready var mech_armor: HealthComponent = $MechArmor


func _ready() -> void:
	add_to_group(GROUP)
	weapon.fired.connect(_on_weapon_fired)
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	visual.look = RunState.character.look
	visual.set_body_color(RunState.character.body_color)
	RunState.weapons_changed.connect(_sync_weapon)
	RunState.stats_changed.connect(_on_stats_changed)
	EventBus.room_rule_changed.connect(_on_room_rule_changed)
	mech_armor.died.connect(_on_mech_destroyed)
	mech_armor.health_changed.connect(_on_mech_armor_changed)
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


func is_piloting() -> bool:
	return mech != null


## A pie, la de los stats; arriba de un armazón, la suya.
func move_speed() -> float:
	return mech.move_speed if mech != null else RunState.stats.move_speed


## Se sube a un armazón con `armor_left` de blindaje.
func board(data: MechData, armor_left: float) -> void:
	if mech != null or is_dead():
		return
	mech = data
	mech_armor.setup(data.armor, armor_left)
	hurtbox.health = mech_armor
	cancel_bomb()
	weapon.slot = WeaponSlot.new(data.weapon)
	visual.set_mech(data, mech_armor.current / mech_armor.max_health)
	visual.set_gun(data.weapon.gun_color, data.weapon.gun_length)
	AudioManager.play_sfx(&"mech_board")
	mech_changed.emit(data)


## Salta afuera (al rodar): el armazón queda parado acá con el blindaje que le quedaba.
func eject() -> void:
	if mech == null:
		return
	var parked := Fx.spawn(get_tree(), PARKED_MECH_SCENE, global_position, Fx.ENTITIES_GROUP) as ParkedMech
	parked.setup(mech, mech_armor.current, true)
	leave_mech()
	AudioManager.play_sfx(&"mech_eject")


## Baja del armazón sin dejarlo en ningún lado (cuando revienta o al morir).
func leave_mech() -> void:
	if mech == null:
		return
	mech = null
	hurtbox.health = health
	visual.set_mech(null, 0.0)
	_sync_weapon()
	mech_changed.emit(null)


func read_move_input() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


## Al caminar levanta polvo cada STEP_DISTANCE píxeles (solo visual).
func leave_steps(delta: float) -> void:
	_step_left -= move_velocity.length() * delta
	if _step_left <= 0.0:
		_step_left = STEP_DISTANCE
		Fx.spawn(get_tree(), STEP_DUST_SCENE, global_position + Vector2(0, 5), Fx.DECALS_GROUP)


## Acelera hacia `target_velocity` (o frena si es cero) y mueve el cuerpo.
func move_toward_velocity(target_velocity: Vector2, delta: float) -> void:
	var rate: float = acceleration if target_velocity != Vector2.ZERO else friction
	move_velocity = move_velocity.move_toward(target_velocity, rate * delta)
	apply_velocity()


## Mueve el cuerpo con move_velocity más el empujón de los golpes y el viento.
func apply_velocity() -> void:
	var wind: Vector2 = _wind if Engine.get_physics_frames() - _wind_tick <= 1 else Vector2.ZERO
	_wind = Vector2.ZERO
	velocity = move_velocity + knockback.velocity + wind
	move_and_slide()


## Viento (el Soplo, el Cierzo): lo empuja a `wind_velocity` px por segundo este tick. Se llama en
## cada tick que sopla; varios vientos del mismo tick se suman.
func push(wind_velocity: Vector2) -> void:
	var tick: int = Engine.get_physics_frames()
	if tick != _wind_tick:
		_wind = Vector2.ZERO
		_wind_tick = tick
	_wind += wind_velocity


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
	# Con el mouse se apunta a un punto (las granadas caen ahí); con el stick, solo a una dirección.
	var distance: float = (get_global_mouse_position() - weapon.global_position).length() if _aim_with_mouse else INF
	weapon.set_aim(aim_direction, distance)


## Dispara mientras se mantiene el botón, o si se apretó hace muy poco y el arma recién está lista.
func try_shoot(delta: float) -> void:
	if Input.is_action_pressed(&"shoot") or input_buffer.is_buffered(&"shoot"):
		if weapon.trigger(RunState.stats, aim_direction, delta):
			input_buffer.consume(&"shoot")
	else:
		weapon.idle(RunState.stats)


## Recargar, cambiar de arma (tocar: la siguiente; mantener: la rueda; 1 a 9: esa) y usar el activo.
func try_weapon_actions(delta: float) -> void:
	if input_buffer.consume(&"reload"):
		weapon.reload()
	_try_swap(delta)
	for i: int in WEAPON_KEYS.size():
		if Input.is_action_just_pressed(WEAPON_KEYS[i]) and not is_piloting() and RunState.select_weapon(i):
			AudioManager.play_sfx(&"weapon_swap")
	if input_buffer.consume(&"use_active"):
		_use_active()


func _try_swap(delta: float) -> void:
	if Input.is_action_just_pressed(&"swap_weapon"):
		_swap_hold = 0.0
	if _swap_hold < 0.0:
		return
	if Input.is_action_pressed(&"swap_weapon"):
		_swap_hold += delta
		if _swap_hold >= WHEEL_HOLD_TIME:
			_swap_hold = -1.0
			if not is_piloting() and RunState.weapons.size() > 1:
				weapon_wheel_requested.emit()
		return
	# Lo soltó enseguida (o fue la ruedita del mouse): la siguiente.
	_swap_hold = -1.0
	if not is_piloting() and RunState.select_next_weapon():
		AudioManager.play_sfx(&"weapon_swap")


func can_roll() -> bool:
	return _roll_cooldown_left <= 0.0


## `time` < 0 = el de rodar.
func start_roll_cooldown(time: float = -1.0) -> void:
	_roll_cooldown_left = roll_cooldown if time < 0.0 else time


## El estado de esquivar del personaje: rodar o embestir (arriba de un armazón, siempre rodar).
func dodge_state() -> StringName:
	if RunState.character.dodge == CharacterData.Dodge.CHARGE and not is_piloting():
		return &"Charge"
	return &"Roll"


## Si se apretó el botón y quedan cargas, usa un Pulso: borra todas las balas enemigas y empuja
## a los enemigos cercanos.
func try_pulse() -> void:
	if not input_buffer.consume(&"blank"):
		return
	if _pulse_locked or not RunState.use_blank():
		AudioManager.play_sfx(&"empty")
		return
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		var bullet := node as Bullet
		if bullet != null and bullet.is_hostile_to_player():
			bullet.destroy()
	for node: Node in get_tree().get_nodes_in_group(LobShell.GROUP):
		(node as LobShell).fizzle()
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() <= PULSE_PUSH_RADIUS:
			enemy.knockback.apply(offset, PULSE_PUSH_FORCE)
	Fx.spawn(get_tree(), PULSE_WAVE_SCENE, global_position)
	var glow := Fx.spawn(get_tree(), LIGHT_FLASH_SCENE, global_position) as LightFlash
	glow.color = PULSE_LIGHT_COLOR
	glow.texture_scale = 3.0
	glow.duration = 0.4
	EventBus.shake_requested.emit(PULSE_TRAUMA)
	AudioManager.play_sfx(&"pulse")


## Bomba: al tocar el botón la deja a los pies; si se mantiene, muestra dónde va a caer y al soltar
## la tira hasta ahí. Sin bombas, "clic".
func try_bomb(delta: float) -> void:
	if _bomb_hold < 0.0:
		if not input_buffer.consume(&"bomb"):
			return
		if RunState.bombs <= 0:
			AudioManager.play_sfx(&"empty")
			return
		_bomb_hold = 0.0
	if Input.is_action_pressed(&"bomb"):
		_bomb_hold += delta
		if _bomb_hold >= BOMB_HOLD_TIME:
			bomb_aim.show_at(global_position, bomb_target())
		return
	var thrown: bool = _bomb_hold >= BOMB_HOLD_TIME
	var target: Vector2 = bomb_target()
	cancel_bomb()
	if not RunState.use_bomb():
		AudioManager.play_sfx(&"empty")
		return
	var start: Vector2 = global_position + Vector2(0, 2)
	var bomb := Fx.spawn(get_tree(), BOMB_SCENE, start, Fx.ENTITIES_GROUP) as Bomb
	if thrown:
		bomb.launch(start, target)
		AudioManager.play_sfx(&"lob", 0.1)
	else:
		AudioManager.play_sfx(&"bomb_place")


## Deja de apuntar la bomba sin gastarla (al rodar o morir).
func cancel_bomb() -> void:
	_bomb_hold = -1.0
	bomb_aim.hide_aim()


## Dónde caería la bomba si se suelta ahora: hacia la mira, sin pasar paredes ni rocas.
func bomb_target() -> Vector2:
	var distance: float
	if _aim_with_mouse:
		distance = clampf(global_position.distance_to(get_global_mouse_position()), BOMB_THROW_MIN, BOMB_THROW_MAX)
	else:
		var charge: float = clampf((_bomb_hold - BOMB_HOLD_TIME) / BOMB_CHARGE_TIME, 0.0, 1.0)
		distance = lerpf(BOMB_THROW_MIN, BOMB_THROW_MAX, charge)
	var target: Vector2 = global_position + aim_direction * distance
	var query := PhysicsRayQueryParameters2D.create(global_position, target, PhysicsLayers.WALL)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		target = hit.position - aim_direction * BOMB_WALL_MARGIN
	return target


func _on_hurt(info: HitInfo) -> void:
	knockback.apply(info.direction, info.knockback * (MECH_KNOCKBACK if is_piloting() else 1.0))
	flash.flash(HURT_FLASH_TIME)
	if not health.is_dead():
		flash.blink((mech_armor if is_piloting() else health).invulnerability_after_hit)
	EventBus.shake_requested.emit(HURT_TRAUMA)
	EventBus.hitstop_requested.emit(HURT_HITSTOP)
	EventBus.player_damaged.emit(info.damage)
	AudioManager.play_sfx(&"player_hurt", 0.05)
	var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position + Vector2(0, -2)) as CPUParticles2D
	burst.color = HURT_BURST_COLOR
	burst.amount = 8


func _on_died() -> void:
	# Un item (Segunda chispa) puede salvarlo justo antes de morir.
	if hooks.try_cheat_death():
		return
	machine.transition_to(&"Dead")


func _on_weapon_fired(direction: Vector2) -> void:
	visual.play_fire()
	light.pulse(FIRE_LIGHT_PULSE)
	hooks.on_shoot(direction)


func _use_active() -> void:
	if not RunState.is_active_ready():
		AudioManager.play_sfx(&"empty")
		return
	if hooks.use_active():
		RunState.spend_active()
		AudioManager.play_sfx(&"active_use")


func _sync_weapon() -> void:
	if is_piloting():
		return
	weapon.slot = RunState.current_weapon_slot()
	visual.set_gun(weapon.weapon().gun_color, weapon.weapon().gun_length)


## Sin blindaje el armazón revienta: lastima a los enemigos cerca y el jugador queda a pie, invulnerable
## un momento.
func _on_mech_destroyed() -> void:
	var color: Color = mech.accent_color if mech != null else Color.WHITE
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() <= MECH_BLAST_RADIUS and not enemy.is_hidden():
			enemy.hurtbox.receive_hit(HitInfo.create(MECH_BLAST_DAMAGE, offset, PULSE_PUSH_FORCE))
	var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position + Vector2(0, -4)) as CPUParticles2D
	burst.color = color
	burst.amount = 24
	var glow := Fx.spawn(get_tree(), LIGHT_FLASH_SCENE, global_position) as LightFlash
	glow.color = color
	glow.texture_scale = 3.0
	EventBus.shake_requested.emit(MECH_BREAK_TRAUMA)
	AudioManager.play_sfx(&"mech_break")
	leave_mech()
	health.grant_invulnerability(MECH_BREAK_IFRAMES)
	flash.blink(MECH_BREAK_IFRAMES)


func _on_mech_armor_changed(current: float, max_value: float) -> void:
	if is_piloting():
		visual.set_mech(mech, current / max_value if max_value > 0.0 else 0.0)


## Regla de la sala: Frágil (más daño) y Sin Pulso. null al terminar el combate.
func _on_room_rule_changed(rule: RoomRule) -> void:
	hurtbox.damage_multiplier = rule.damage_taken_mult if rule != null else 1.0
	_pulse_locked = rule != null and rule.no_pulse


## Un item de vida máxima agranda (y llena) los contenedores.
func _on_stats_changed(stats: StatBlock) -> void:
	health.set_max(stats.max_health)
