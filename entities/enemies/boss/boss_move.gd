class_name BossMove
extends RefCounted
## Un movimiento de jefe en marcha (lo corre el estado BossAttack). Primero el aviso de
## `attack.windup` (se frena, parpadea, "!" y sonido), después lo propio de cada tipo (`_begin` y
## `_tick`, que devuelve true al terminar) y al final, o si lo cortan (cambio de fase, muerte), `_end`
## deja todo como estaba. Hay una subclase por BossAttack.Kind; BossMoves.create elige cuál.
## El `delta` que llega ya trae el ritmo del jefe (Apagado, Furia).

const STRIKE_SCENE: PackedScene = preload("res://entities/enemies/boss_strike.tscn")
## Lo que dejan algunos movimientos andando solo (ondas, coronas, raíces, ovillos): se borra al morir el
## jefe (Enemy._die).
const HAZARD_GROUP: StringName = &"boss_hazards"
const PULSE_COLOR: Color = Color("ffd166")

var enemy: Enemy
var attack: BossAttack
var _windup_left: float = 0.0
var _started: bool = false


func start() -> void:
	_windup_left = attack.windup
	_telegraph(true)
	AudioManager.play_sfx(&"telegraph", 0.05)
	_on_windup()


## Un tick. true cuando terminó.
func update(delta: float) -> bool:
	if not _started:
		_windup_left -= delta
		_windup_tick(delta)
		if _windup_left > 0.0:
			return false
		_started = true
		_telegraph(false)
		_begin()
	return _tick(delta)


## Termina (o lo cortan): saca el aviso y limpia lo que haya quedado.
func stop() -> void:
	_telegraph(false)
	_end()


## Al empezar el aviso.
func _on_windup() -> void:
	pass


## Durante el aviso: quieto, mirando al jugador.
func _windup_tick(delta: float) -> void:
	hold(delta)


func _begin() -> void:
	pass


func _tick(_delta: float) -> bool:
	return true


func _end() -> void:
	pass


func hold(delta: float) -> void:
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	enemy.look_at_target()


func rng() -> RandomNumberGenerator:
	return GameRNG.stream(RngStreams.COMBAT)


## Dónde está el jugador (o el jefe, si no hay jugador vivo).
func target_position() -> Vector2:
	return enemy.target.global_position if enemy.has_target() else enemy.global_position


## Un lugar cerca del jugador para el golpe número `index`: el primero justo donde está, los demás
## al azar a `attack.spread` px como mucho. Siempre adentro de la sala.
func spot_near_target(index: int) -> Vector2:
	var at: Vector2 = target_position()
	if index > 0:
		at += Vector2.from_angle(rng().randf() * TAU) * rng().randf_range(attack.spread * 0.35, attack.spread)
	return clamp_to_room(at, 6.0)


func clamp_to_room(at: Vector2, margin: float) -> Vector2:
	var area: Rect2 = enemy.room_rect().grow(-margin)
	return Vector2(clampf(at.x, area.position.x, area.end.x), clampf(at.y, area.position.y, area.end.y))


## Un golpe avisado (BossStrike) con el daño, el radio y el aviso del movimiento. La lava queda en el
## piso, por debajo del jugador y los enemigos (así se ve quién la está pisando).
func spawn_strike(at: Vector2, look: BossAttack.Look) -> BossStrike:
	var group: StringName = Fx.DECALS_GROUP if look == BossAttack.Look.LAVA else Fx.EFFECTS_GROUP
	var strike := Fx.spawn(enemy.get_tree(), STRIKE_SCENE, at, group) as BossStrike
	strike.look = look
	strike.warn_time = attack.warn_time
	strike.damage = attack.damage
	strike.radius = attack.radius
	strike.speed_multiplier = enemy.bullet_speed_multiplier
	return strike


## Agrega un nodo suelto de un movimiento (onda, corona, raíz, ovillo) a los efectos del mundo, en
## `at` (global). Los movimientos corren en el tick de física (no en un callback), así que va directo.
func place(node: Node2D, at: Vector2) -> void:
	var tree: SceneTree = enemy.get_tree()
	var container: Node = tree.get_first_node_in_group(Fx.EFFECTS_GROUP)
	if container == null:
		container = enemy.get_parent()
	container.add_child(node)
	node.global_position = at


## Le pega `damage` a cada jugador cuya posición cumpla `touches` (rodando o con i-frames no cuenta:
## lo decide su hurtbox), empujándolo desde `from`.
static func hurt_players(tree: SceneTree, damage: float, from: Vector2, touches: Callable) -> void:
	for node: Node in tree.get_nodes_in_group(Player.GROUP):
		var player := node as Player
		if touches.call(player.global_position):
			player.hurtbox.receive_hit(HitInfo.create(damage, player.global_position - from, BossStrike.KNOCKBACK))


func _telegraph(on: bool) -> void:
	if on:
		enemy.flash.start_pulse(PULSE_COLOR)
	else:
		enemy.flash.stop_pulse()
	enemy.visual.set_alert(on)
