class_name Enemy
extends CharacterBody2D
## Enemigo genérico configurado por un EnemyData. Todos comparten los mismos estados:
## Idle (aparece) → Move → Telegraph → Attack → Recover → Move. Muere al quedarse sin vida.
## Los estados leen el movimiento y los ataques de `behavior`: para un enemigo común es su data;
## para un jefe es la de la fase actual, que cambia cuando la vida baja de cada umbral.
## Los enemigos que crea otro (las babosas al dividirse, las crías de un nido) se avisan con
## `spawned` en el acto, aunque entran al árbol diferidos: así la sala los cuenta antes de enterarse
## (con `killed`) de que murió el que los creó.

## Murió (después de avisar a sus hijos con `spawned`).
signal killed
## Creó otro enemigo (todavía no está en el árbol: entra al final del frame).
signal spawned(child: Enemy)

const GROUP: StringName = &"enemies"
const HIT_FLASH_TIME: float = 0.07
const DEATH_TRAUMA: float = 0.35
const DEATH_HITSTOP: float = 0.05
const BOSS_DEATH_TRAUMA: float = 1.0
const BOSS_DEATH_HITSTOP: float = 0.3
const PHASE_FLASH_TIME: float = 0.35
const PHASE_TRAUMA: float = 0.6
## Variación del cooldown entre ataques (±25 %), para que no ataquen todos sincronizados.
const COOLDOWN_JITTER: float = 0.25
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const STAIN_SCENE: PackedScene = preload("res://fx/floor_stain.tscn")
const SPARKS_SCENE: PackedScene = preload("res://fx/spark_swarm.tscn")
const LIGHT_FLASH_SCENE: PackedScene = preload("res://fx/light_flash.tscn")
## Chispas que suelta al morir (las de un jefe, muchas más).
const DEATH_SPARKS: int = 3
const BOSS_DEATH_SPARKS: int = 16
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
## Empujón con el que salen disparados los hijos (al dividirse o al nacer).
const CHILD_PUSH: float = 140.0
## Alfa del dibujo mientras es fantasma (PHASE).
const GHOST_ALPHA: float = 0.3

@export var data: EnemyData

## Multiplicadores del piso (los pone la sala antes de agregarlo al árbol).
var health_multiplier: float = 1.0
var bullet_speed_multiplier: float = 1.0
## Movimiento y ataques actuales.
var behavior: EnemyData
## Fase actual (jefes).
var phase: int = 0
var target: Player
## Velocidad propia del enemigo, sin el empujón de los golpes.
var move_velocity: Vector2 = Vector2.ZERO
var _attack_count: int = 0
var _dead: bool = false
## Dirección del empujón con el que nace (si lo creó otro enemigo).
var _birth_push: Vector2 = Vector2.ZERO
## Bajo tierra (BURROW) o fantasma (PHASE): ni recibe ni hace daño.
var _hidden: bool = false
## Hijos que creó, por id (para el tope de SUMMON). Se guardan ids y no nodos: un nodo liberado no se
## puede leer como Enemy.
var _children: Array[int] = []
## BEAM: por dónde va el rayo (lo apunta el aviso y queda fijo al disparar).
var beam_direction: Vector2 = Vector2.DOWN

@onready var visual: EnemyVisual = $Visual
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var flash: FlashComponent = $FlashComponent
@onready var emitter: BulletEmitter = $BulletEmitter
@onready var beam: EnemyBeam = $Beam
@onready var machine: StateMachine = $StateMachine
@onready var _body_shape: CollisionShape2D = $CollisionShape2D
@onready var _hurtbox_shape: CollisionShape2D = $HurtboxComponent/CollisionShape2D
@onready var _hitbox_shape: CollisionShape2D = $HitboxComponent/CollisionShape2D


func _ready() -> void:
	assert(data != null, "Enemy: falta asignar data (EnemyData)")
	add_to_group(GROUP)
	behavior = data.phases[0].behavior if is_boss() else data
	health.setup(data.max_health * health_multiplier)
	health.died.connect(_die)
	hurtbox.hurt.connect(_on_hurt)
	hitbox.damage = data.contact_damage
	knockback.resistance = data.knockback_resistance
	emitter.speed_multiplier = bullet_speed_multiplier
	_set_radius(_body_shape, data.body_radius)
	_set_radius(_hurtbox_shape, data.hurtbox_radius)
	_set_radius(_hitbox_shape, data.body_radius)
	visual.configure(data)
	if data.move_style == EnemyData.MoveStyle.FLY:
		# Vuela: los fosos no lo frenan.
		collision_mask &= ~PhysicsLayers.PIT
	if _birth_push != Vector2.ZERO:
		knockback.apply(_birth_push, CHILD_PUSH)
	machine.start()
	if is_boss():
		EventBus.boss_spawned.emit(self)


func _physics_process(delta: float) -> void:
	machine.physics_update(delta)
	_update_guard()


func is_boss() -> bool:
	return not data.phases.is_empty()


## true si hay un jugador vivo. Si todavía no lo tenía (aparece después, reinicio), lo busca.
func has_target() -> bool:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(Player.GROUP) as Player
	return is_instance_valid(target) and not target.is_dead()


## Vector hasta el jugador, o cero si no hay jugador vivo.
func to_target() -> Vector2:
	return target.global_position - global_position if has_target() else Vector2.ZERO


func look_at_target() -> void:
	var offset: Vector2 = to_target()
	if offset != Vector2.ZERO:
		visual.set_look(offset.normalized())


## Acelera hacia `target_velocity` (o frena si es cero) y mueve el cuerpo.
func move_toward_velocity(target_velocity: Vector2, delta: float) -> void:
	move_velocity = move_velocity.move_toward(target_velocity, behavior.acceleration * delta)
	apply_velocity()


## Mueve el cuerpo con move_velocity más el empujón de los golpes.
func apply_velocity() -> void:
	velocity = move_velocity + knockback.velocity
	move_and_slide()


## Segundos hasta el próximo ataque, con un poco de azar del stream de combate.
func roll_attack_cooldown(factor: float = 1.0) -> float:
	var jitter: float = GameRNG.stream(RngStreams.COMBAT).randf_range(-COOLDOWN_JITTER, COOLDOWN_JITTER)
	return behavior.attack_cooldown * factor * (1.0 + jitter)


## Patrón del próximo ataque (SHOOT): recorre behavior.patterns en orden. null si no tiene.
func next_pattern() -> BulletPatternData:
	if behavior.patterns.is_empty():
		return null
	var pattern: BulletPatternData = behavior.patterns[_attack_count % behavior.patterns.size()]
	_attack_count += 1
	return pattern


## Crea otro enemigo de `child_data` en `at` (global), empujado desde acá. Avisa con `spawned` en el
## acto y lo agrega al árbol diferido (puede pasar en un callback de física, al morir).
func spawn_child(child_data: EnemyData, at: Vector2) -> Enemy:
	var child := ENEMY_SCENE.instantiate() as Enemy
	child.data = child_data
	child.health_multiplier = health_multiplier
	child.bullet_speed_multiplier = bullet_speed_multiplier
	var offset: Vector2 = at - global_position
	child._birth_push = offset.normalized() if offset != Vector2.ZERO else Vector2.DOWN
	_children.append(child.get_instance_id())
	spawned.emit(child)
	_attach_child.call_deferred(get_parent().get_instance_id(), child, at)
	return child


## Hijos que siguen vivos (los muertos o liberados se descartan).
func living_children() -> int:
	var alive: Array[int] = []
	for id: int in _children:
		var child := instance_from_id(id) as Enemy
		if child != null and not child.is_queued_for_deletion() and not child._dead:
			alive.append(id)
	_children = alive
	return alive.size()


## De dónde sale el rayo (BEAM): el borde del cuerpo, hacia donde apunta.
func beam_origin() -> Vector2:
	return global_position + Vector2(0, -2) + beam_direction * data.body_radius


func is_hidden() -> bool:
	return _hidden


## Bajo tierra o fantasma: sin hurtbox ni daño por contacto; el dibujo cambia.
func set_hidden(hide_it: bool) -> void:
	if hide_it == _hidden:
		return
	_hidden = hide_it
	_hurtbox_shape.set_deferred(&"disabled", hide_it)
	hitbox.active = not hide_it
	match data.move_style:
		EnemyData.MoveStyle.BURROW:
			visual.set_burrowed(hide_it)
		_:
			visual.modulate.a = GHOST_ALPHA if hide_it else 1.0


## Si el contenedor ya no está (fin de la run), el hijo se libera sin entrar. Se pasa el id porque un
## objeto liberado no se puede pasar como argumento tipado.
static func _attach_child(container_id: int, child: Enemy, at: Vector2) -> void:
	var container := instance_from_id(container_id) as Node2D
	if container == null or not container.is_inside_tree():
		child.free()
		return
	child.position = container.to_local(at)
	container.add_child(child)


## El escudo mira al jugador mientras camina o avisa; al atacar (y después) baja la guardia.
func _update_guard() -> void:
	if behavior.shield_degrees <= 0.0:
		return
	var state: StringName = machine.get_state_name()
	var guarding: bool = state == &"Move" or state == &"Telegraph"
	hurtbox.guard_direction = visual.look_direction if guarding else Vector2.ZERO
	hurtbox.guard_cos = cos(deg_to_rad(behavior.shield_degrees * 0.5))
	visual.set_guarding(guarding)


func _set_radius(shape_node: CollisionShape2D, radius: float) -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape_node.shape = circle


func _on_hurt(info: HitInfo) -> void:
	knockback.apply(info.direction, info.knockback)
	flash.flash(HIT_FLASH_TIME)
	visual.play_hit()
	AudioManager.play_sfx(&"enemy_hit", 0.12)
	EventBus.enemy_hit.emit(self, info)
	if is_boss() and not health.is_dead():
		_update_phase()


## Si la vida bajó de un umbral, pasa a la fase siguiente: destello, sacudón, sonido y una pausa
## (Recover) antes de seguir atacando con lo nuevo.
func _update_phase() -> void:
	var thresholds: Array[float] = []
	for boss_phase: BossPhase in data.phases:
		thresholds.append(boss_phase.health_fraction)
	var next: int = PhaseMath.phase_for(health.current / health.max_health, thresholds)
	if next <= phase:
		return
	phase = next
	behavior = data.phases[phase].behavior
	_attack_count = 0
	emitter.stop()
	flash.flash(PHASE_FLASH_TIME)
	EventBus.shake_requested.emit(PHASE_TRAUMA)
	AudioManager.play_sfx(&"boss_phase")
	machine.transition_to(&"Recover")


func _die() -> void:
	if _dead:
		return
	_dead = true
	if data.split_into != null:
		for i: int in data.split_count:
			var angle: float = TAU * i / data.split_count + PI * 0.25
			spawn_child(data.split_into, global_position + Vector2.from_angle(angle) * data.body_radius)
	EventBus.enemy_killed.emit(self)
	var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position + Vector2(0, -2)) as CPUParticles2D
	burst.color = data.body_color.lightened(0.2)
	var stain := Fx.spawn(get_tree(), STAIN_SCENE, global_position + Vector2(0, 3), Fx.DECALS_GROUP) as FloorStain
	stain.color = data.body_color.darkened(0.55)
	stain.radius = data.visual_radius
	var sparks := Fx.spawn(get_tree(), SPARKS_SCENE, global_position + Vector2(0, -2)) as SparkSwarm
	sparks.count = BOSS_DEATH_SPARKS if is_boss() else DEATH_SPARKS
	var glow := Fx.spawn(get_tree(), LIGHT_FLASH_SCENE, global_position) as LightFlash
	glow.color = data.body_color.lightened(0.3)
	glow.texture_scale = 3.0 if is_boss() else 1.0
	glow.duration = 0.6 if is_boss() else 0.25
	if is_boss():
		# Al morir el jefe se borran sus balas: la pelea terminó.
		for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
			var bullet := node as Bullet
			if bullet.is_hostile_to_player():
				bullet.destroy()
		burst.amount = 40
		EventBus.shake_requested.emit(BOSS_DEATH_TRAUMA)
		EventBus.hitstop_requested.emit(BOSS_DEATH_HITSTOP)
		AudioManager.play_sfx(&"boss_die")
		EventBus.boss_defeated.emit(self)
	else:
		EventBus.shake_requested.emit(DEATH_TRAUMA)
		EventBus.hitstop_requested.emit(DEATH_HITSTOP)
		AudioManager.play_sfx(&"enemy_die", 0.1)
	killed.emit()
	queue_free()
