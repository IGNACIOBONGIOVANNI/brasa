class_name Enemy
extends CharacterBody2D
## Enemigo genérico configurado por un EnemyData. Todos comparten los mismos estados:
## Idle (aparece) → Move → Telegraph → Attack → Recover → Move. Muere al quedarse sin vida.
## Los estados leen el movimiento y los ataques de `behavior`: para un enemigo común es su data;
## para un jefe es la de la fase actual, que cambia cuando la vida baja de cada umbral.
## Los enemigos que crea otro (las babosas al dividirse, las crías de un nido) se avisan con
## `spawned` en el acto, aunque entran al árbol diferidos: así la sala los cuenta antes de enterarse
## (con `killed`) de que murió el que los creó.
## Caminos: la sala le pasa su `nav` (RoomNav); si algo tapa la línea hasta el jugador (roca, foso),
## camina rodeándolo (`route_direction`). Los jefes con movimientos propios (BossPhase.attacks) atacan
## con el estado BossAttack en vez de Telegraph/Attack.

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
## Su propia escena, para los hijos. Se carga al usarla (no con preload): enemy.tscn tiene la escena de
## las balas y bullet.gd usa esta clase, así que un preload acá arma una carga circular si lo primero
## que se carga es una bala (por ejemplo, el arma de un armazón al leer los capítulos).
const ENEMY_SCENE_PATH: String = "res://entities/enemies/enemy.tscn"
## Empujón con el que salen disparados los hijos (al dividirse o al nacer).
const CHILD_PUSH: float = 140.0
## Alfa del dibujo mientras es fantasma (PHASE).
const GHOST_ALPHA: float = 0.3
## Cada cuánto revisa si puede ir derecho al jugador o tiene que rodear algo.
const ROUTE_REFRESH: float = 0.2
## Mitad del interior de una sala (para que los jefes no salten ni tiren cosas afuera).
const ROOM_HALF: Vector2 = Vector2(120, 72)
## Las invocaciones del escenario no aparecen más cerca que esto del jugador.
const SCENERY_SPOT_CLEARANCE: float = 48.0
## Para llegar a alguien alcanza con tocarlo: el camino se revisa hasta esta distancia de más del
## propio cuerpo (si no, un jugador pegado a la pared "taparía" su propio camino).
const TOUCH_MARGIN: float = 4.0

@export var data: EnemyData

## Multiplicadores del piso (los pone la sala antes de agregarlo al árbol).
var health_multiplier: float = 1.0
var bullet_speed_multiplier: float = 1.0
## Ritmo de la regla de la sala (Furia): multiplica moverse, avisar y atacar.
var pace: float = 1.0
## Movimiento y ataques actuales.
var behavior: EnemyData
## Fase actual (jefes).
var phase: int = 0
var target: Player
## Velocidad propia del enemigo, sin el empujón de los golpes.
var move_velocity: Vector2 = Vector2.ZERO
var _attack_count: int = 0
var _dead: bool = false
## Desapareció porque murió quien lo invocó (no cuenta como muerte ni suelta nada).
var dismissed: bool = false
## Dirección del empujón con el que nace (si lo creó otro enemigo).
var _birth_push: Vector2 = Vector2.ZERO
## Bajo tierra (BURROW) o fantasma (PHASE): ni recibe ni hace daño.
var _hidden: bool = false
## Hijos que creó, por id (para el tope de SUMMON). Se guardan ids y no nodos: un nodo liberado no se
## puede leer como Enemy.
var _children: Array[int] = []
## BEAM: por dónde va el rayo (lo apunta el aviso y queda fijo al disparar).
var beam_direction: Vector2 = Vector2.DOWN
## Caminos de la sala donde está (null en la arena de tests: va siempre derecho) y dónde está el
## centro de esa sala (global).
var nav: RoomNav
var nav_origin: Vector2 = Vector2.ZERO
## Jefes: el movimiento que está haciendo, el último que hizo (para no repetirlo) y la pausa que
## pide al terminar (Recover la usa una vez; -1 = la de la fase).
var attack: BossAttack
var next_recover: float = -1.0
var _last_attack_index: int = -1
## Movimiento pedido desde el menú de debug: sale el próximo (una vez).
var _forced_attack: BossAttack
## En el aire (un jefe que salta o se esconde en la oscuridad): ni recibe ni hace daño.
var _airborne: bool = false
var _route_left: float = 0.0
var _route_direct: bool = true
var _route_point: Vector2 = Vector2.ZERO
var _probe_shape := CircleShape2D.new()

@onready var visual: EnemyVisual = $Visual
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var flash: FlashComponent = $FlashComponent
@onready var emitter: BulletEmitter = $BulletEmitter
@onready var beam: EnemyBeam = $Beam
@onready var status: StatusComponent = $Status
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
	status.radius = data.visual_radius
	if data.move_style == EnemyData.MoveStyle.FLY:
		# Vuela: los fosos no lo frenan (a los que ruedan, PROWL o BOUNCE, sí).
		collision_mask &= ~PhysicsLayers.PIT
	if _birth_push != Vector2.ZERO:
		knockback.apply(_birth_push, CHILD_PUSH)
	machine.start()
	if is_boss():
		EventBus.boss_spawned.emit(self)


func _physics_process(delta: float) -> void:
	# Apagado y la regla de la sala cambian el ritmo de todo lo suyo (moverse, avisar, atacar).
	machine.physics_update(delta * speed_factor())
	_update_guard()


## Apagado y el ritmo de la sala juntos.
func speed_factor() -> float:
	return status.speed_factor() * pace


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


## Mueve el cuerpo con move_velocity (más lento si está apagado) más el empujón de los golpes.
func apply_velocity() -> void:
	velocity = move_velocity * speed_factor() + knockback.velocity
	move_and_slide()


## Hacia dónde caminar para llegar al jugador: derecho si no hay nada en el medio; si una roca o un
## foso tapa la línea, hacia la próxima celda del camino que los rodea (RoomNav). Cero sin jugador.
func route_direction(delta: float) -> Vector2:
	var offset: Vector2 = to_target()
	if offset == Vector2.ZERO:
		return Vector2.ZERO
	if nav == null:
		return offset.normalized()
	_route_left -= delta
	if _route_left <= 0.0 or (not _route_direct and global_position.distance_to(_route_point) < 2.0):
		_refresh_route()
	if _route_direct:
		return offset.normalized()
	var to_point: Vector2 = _route_point - global_position
	return to_point.normalized() if to_point != Vector2.ZERO else offset.normalized()


## true si el cuerpo puede ir derecho hasta tocar `to` sin chocar paredes, rocas ni fosos (a los que
## vuelan los fosos no los frenan). `layers`: qué cuenta como obstáculo (los que rompen rocas al
## embestir solo miran los fosos).
func has_clear_path(to: Vector2, layers: int = PhysicsLayers.WALL | PhysicsLayers.PIT) -> bool:
	var offset: Vector2 = to - global_position
	var reach: float = offset.length() - data.body_radius - TOUCH_MARGIN
	if reach <= 0.0:
		return true
	_probe_shape.radius = maxf(1.0, data.body_radius - 1.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _probe_shape
	query.transform = Transform2D(0.0, _body_shape.global_position)
	query.motion = offset.normalized() * reach
	query.collision_mask = collision_mask & layers
	query.exclude = [get_rid()]
	var result: PackedFloat32Array = get_world_2d().direct_space_state.cast_motion(query)
	return result.is_empty() or result[0] >= 1.0


func _refresh_route() -> void:
	_route_left = ROUTE_REFRESH
	_route_direct = has_clear_path(target.global_position)
	if not _route_direct:
		_route_point = nav_origin + nav.next_point(global_position - nav_origin, target.global_position - nav_origin)


## Interior de la sala donde está, en coordenadas globales.
func room_rect() -> Rect2:
	return Rect2(nav_origin - ROOM_HALF, ROOM_HALF * 2.0)


## Un lugar de la sala cerca de `at` donde puede pararse: adentro (con su cuerpo entero) y, si la
## sala tiene caminos, en una celda sin roca ni foso.
func landing_spot(at: Vector2) -> Vector2:
	var margin: float = data.body_radius + 2.0
	var area: Rect2 = room_rect().grow(-margin)
	var spot := Vector2(clampf(at.x, area.position.x, area.end.x), clampf(at.y, area.position.y, area.end.y))
	if nav != null:
		spot = nav_origin + nav.nearest_open(spot - nav_origin)
	return spot


## Jefes con movimientos propios en la fase actual (BossPhase.attacks).
func has_boss_attacks() -> bool:
	return is_boss() and not data.phases[phase].attacks.is_empty()


## El próximo movimiento de jefe: uno al azar de la fase (stream de combate), nunca el mismo dos
## veces seguidas si hay más de uno. Las embestidas no entran si un foso o una roca tapan el camino.
func next_boss_attack() -> BossAttack:
	if _forced_attack != null:
		var forced: BossAttack = _forced_attack
		_forced_attack = null
		return forced
	var attacks: Array[BossAttack] = data.phases[phase].attacks
	var blocked: bool = has_target() and not has_clear_path(target.global_position)
	var choices: Array[int] = []
	for i: int in attacks.size():
		var repeated: bool = i == _last_attack_index and attacks.size() > 1
		if not repeated and not (blocked and attacks[i].kind == BossAttack.Kind.CHARGES):
			choices.append(i)
	if choices.is_empty():
		for i: int in attacks.size():
			if i != _last_attack_index or attacks.size() == 1:
				choices.append(i)
	var index: int = choices[GameRNG.stream(RngStreams.COMBAT).randi_range(0, choices.size() - 1)]
	_last_attack_index = index
	return attacks[index]


## Menú de debug: que haga `forced` ya si está caminando o en pausa; si no, apenas termine.
func force_attack(forced: BossAttack) -> void:
	_forced_attack = forced
	var state: StringName = machine.get_state_name()
	if state == &"Move" or state == &"Recover":
		machine.transition_to(&"BossAttack")


func is_airborne() -> bool:
	return _airborne


## En el aire (salta, o se esconde en la oscuridad): sin hurtbox, sin daño por contacto y sin cuerpo
## (lo mueven a mano). El dibujo lo maneja quien lo llama (EnemyVisual.set_lift).
func set_airborne(airborne: bool) -> void:
	if airborne == _airborne:
		return
	_airborne = airborne
	_body_shape.set_deferred(&"disabled", airborne)
	_apply_touchable()


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
	var child := (load(ENEMY_SCENE_PATH) as PackedScene).instantiate() as Enemy
	child.data = child_data
	child.health_multiplier = health_multiplier
	child.bullet_speed_multiplier = bullet_speed_multiplier
	child.pace = pace
	child.nav = nav
	child.nav_origin = nav_origin
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


## Bajo tierra, fantasma o en el aire: nada lo toca.
func is_hidden() -> bool:
	return _hidden or _airborne


## Bajo tierra o fantasma: sin hurtbox ni daño por contacto; el dibujo cambia.
func set_hidden(hide_it: bool) -> void:
	if hide_it == _hidden:
		return
	_hidden = hide_it
	_apply_touchable()
	match data.move_style:
		EnemyData.MoveStyle.BURROW:
			visual.set_burrowed(hide_it)
		_:
			visual.self_modulate.a = GHOST_ALPHA if hide_it else 1.0


func _apply_touchable() -> void:
	_hurtbox_shape.set_deferred(&"disabled", is_hidden())
	hitbox.active = not is_hidden()


## Desaparece sin morir de verdad (murió quien lo invocó): la sala lo descuenta, pero no suelta nada,
## no cuenta como enemigo muerto ni dispara lo de los items.
func dismiss() -> void:
	if _dead:
		return
	_dead = true
	dismissed = true
	if is_inside_tree():
		var puff := Fx.spawn(get_tree(), BURST_SCENE, global_position + Vector2(0, -2)) as CPUParticles2D
		puff.color = data.body_color
		puff.amount = 8
		killed.emit()
		queue_free()
	else:
		# Todavía no entró al árbol (lo acaban de crear): _attach_child lo libera en vez de agregarlo.
		killed.emit()


## Un lugar del borde de la sala para que aparezca algo "del escenario" (los ojos de los poltergeist):
## una celda libre pegada a una pared, lejos de las puertas y del jugador. Global.
func scenery_spot(rng: RandomNumberGenerator) -> Vector2:
	for _attempt: int in 24:
		var cell: Vector2i
		match rng.randi_range(0, 3):
			0:
				cell = Vector2i(rng.randi_range(1, RoomGrid.WIDTH - 2), 0)
			1:
				cell = Vector2i(rng.randi_range(1, RoomGrid.WIDTH - 2), RoomGrid.HEIGHT - 1)
			2:
				cell = Vector2i(0, rng.randi_range(1, RoomGrid.HEIGHT - 2))
			_:
				cell = Vector2i(RoomGrid.WIDTH - 1, rng.randi_range(1, RoomGrid.HEIGHT - 2))
		var near_door: bool = (absi(cell.x - RoomGrid.CENTER.x) <= 2 and (cell.y == 0 or cell.y == RoomGrid.HEIGHT - 1)) \
				or (absi(cell.y - RoomGrid.CENTER.y) <= 2 and (cell.x == 0 or cell.x == RoomGrid.WIDTH - 1))
		if near_door or (nav != null and not nav.is_open(cell)):
			continue
		var at: Vector2 = nav_origin + RoomGrid.cell_center(cell)
		if has_target() and at.distance_to(target.global_position) < SCENERY_SPOT_CLEARANCE:
			continue
		return at
	return global_position


## EnemyData.death_pattern: el anillo de balas al morir.
static func _death_ring(tree: SceneTree, scene: PackedScene, pattern: BulletPatternData, at: Vector2,
		speed_multiplier: float) -> void:
	var spec := ShotSpec.from_pattern(pattern)
	spec.speed *= speed_multiplier
	for direction: Vector2 in PatternMath.ring(pattern.count, deg_to_rad(pattern.angle_offset_degrees)):
		Bullet.spawn(tree, scene, spec, at + direction * 4.0, direction,
				PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)


## Si el contenedor ya no está (fin de la run), el hijo se libera sin entrar. Se pasa el id porque un
## objeto liberado no se puede pasar como argumento tipado.
static func _attach_child(container_id: int, child: Enemy, at: Vector2) -> void:
	var container := instance_from_id(container_id) as Node2D
	if container == null or not container.is_inside_tree() or child._dead:
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
	_last_attack_index = -1
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
	if data.summons_die_with_me:
		for id: int in _children:
			var child := instance_from_id(id) as Enemy
			if child != null and not child.is_queued_for_deletion():
				child.dismiss()
	if data.death_pattern != null:
		# Diferido: puede morir en un callback de física (una bala), donde no se agregan áreas.
		_death_ring.call_deferred(get_tree(), emitter.bullet_scene, data.death_pattern, global_position,
				bullet_speed_multiplier)
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
		# Al morir el jefe se borran sus balas, sus bombas y sus golpes avisados: la pelea terminó.
		for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
			var bullet := node as Bullet
			if bullet.is_hostile_to_player():
				bullet.destroy()
		for node: Node in get_tree().get_nodes_in_group(LobShell.GROUP):
			(node as LobShell).fizzle()
		for node: Node in get_tree().get_nodes_in_group(BossStrike.GROUP):
			(node as BossStrike).vanish()
		for node: Node in get_tree().get_nodes_in_group(RollingBall.GROUP):
			(node as RollingBall).vanish()
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
