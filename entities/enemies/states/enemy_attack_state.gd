class_name EnemyAttackState
extends State
## Ataque según behavior.attack_kind: embestida hacia donde estaba el jugador al terminar el aviso
## (CHARGE), el próximo patrón de balas (SHOOT), el rayo por la línea que avisó (BEAM), explotar y
## morir (EXPLODE), invocar enemigos (SUMMON), tirar una bola que cae donde está el jugador (LOB), un
## tajo corto adelante (SLASH) o soplar y empujar al jugador (GUST). Los que andan bajo tierra (BURROW)
## asoman al atacar. Los que embisten en línea recta (charge_axis_only) van por la fila o la columna
## del jugador y rompen la roca que chocan.

const WALL_BUMP_TRAUMA: float = 0.25
## Velocidad que conserva al terminar la embestida (el resto lo frena en Recover).
const CHARGE_END_FACTOR: float = 0.35
const LOB_SHELL_SCENE: PackedScene = preload("res://entities/enemies/lob_shell.tscn")
## Distancia desde el centro a la que nacen las invocaciones.
const SUMMON_DISTANCE: float = 8.0
const STRIKE_SCENE: PackedScene = preload("res://entities/enemies/boss_strike.tscn")
const WIND_SCENE: PackedScene = preload("res://fx/wind_gust.tscn")
## SLASH: el tajo sale casi en el acto (el aviso ya lo dio Telegraph) y es finito.
const SLASH_WARN: float = 0.1
const SLASH_WIDTH: float = 3.0
## GUST: ancho del soplido (grados) y cuánto llega.
const GUST_CONE: float = 50.0

var _charge_direction: Vector2 = Vector2.DOWN
var _time_left: float = 0.0
var _gust_direction: Vector2 = Vector2.DOWN

@onready var enemy: Enemy = owner as Enemy


func enter(_previous: StringName) -> void:
	if enemy.behavior.move_style == EnemyData.MoveStyle.BURROW:
		enemy.set_hidden(false)
		AudioManager.play_sfx(&"burrow", 0.1)
	match enemy.behavior.attack_kind:
		EnemyData.AttackKind.CHARGE:
			var offset: Vector2 = enemy.to_target()
			_charge_direction = offset.normalized() if offset != Vector2.ZERO else enemy.visual.look_direction
			if enemy.behavior.charge_axis_only:
				_charge_direction = Vector2(signf(offset.x), 0.0) if absf(offset.x) >= absf(offset.y) \
						else Vector2(0.0, signf(offset.y))
				if _charge_direction == Vector2.ZERO:
					_charge_direction = Vector2.DOWN
				enemy.visual.set_look(_charge_direction)
			_time_left = enemy.behavior.charge_time
			enemy.visual.set_charging(true)
			AudioManager.play_sfx(&"charge", 0.05)
		EnemyData.AttackKind.SHOOT:
			var pattern: BulletPatternData = enemy.next_pattern()
			if pattern != null:
				enemy.emitter.fire(pattern, enemy.target)
		EnemyData.AttackKind.BEAM:
			_time_left = enemy.behavior.beam_time
			AudioManager.play_sfx(&"beam", 0.05)
		EnemyData.AttackKind.EXPLODE:
			EnemyBlast.explode(get_tree(), enemy.global_position, enemy.behavior.blast_radius,
					enemy.behavior.attack_damage, _first_pattern(), enemy.bullet_speed_multiplier, enemy.data.body_color)
			enemy.health.kill()
		EnemyData.AttackKind.SUMMON:
			_summon()
		EnemyData.AttackKind.LOB:
			_lob()
		EnemyData.AttackKind.SLASH:
			_slash()
		EnemyData.AttackKind.GUST:
			var offset: Vector2 = enemy.to_target()
			_gust_direction = offset.normalized() if offset != Vector2.ZERO else enemy.visual.look_direction
			_time_left = enemy.behavior.beam_time
			var wind := Fx.spawn(get_tree(), WIND_SCENE, enemy.global_position) as WindGust
			wind.direction = _gust_direction
			wind.cone = GUST_CONE
			wind.length = enemy.behavior.attack_range
			wind.duration = enemy.behavior.beam_time
			AudioManager.play_sfx(&"gust", 0.1)


func exit() -> void:
	enemy.visual.set_charging(false)
	enemy.emitter.stop()
	enemy.beam.stop()
	if enemy.behavior.attack_kind == EnemyData.AttackKind.CHARGE:
		enemy.move_velocity *= CHARGE_END_FACTOR


func physics_update(delta: float) -> void:
	match enemy.behavior.attack_kind:
		EnemyData.AttackKind.CHARGE:
			_update_charge(delta)
		EnemyData.AttackKind.SHOOT:
			enemy.move_toward_velocity(Vector2.ZERO, delta)
			if not enemy.emitter.is_firing():
				machine.transition_to(&"Recover")
		EnemyData.AttackKind.BEAM:
			enemy.move_toward_velocity(Vector2.ZERO, delta)
			enemy.beam.fire(enemy.beam_origin(), enemy.beam_direction, enemy.behavior.attack_damage)
			_time_left -= delta
			if _time_left <= 0.0:
				machine.transition_to(&"Recover")
		EnemyData.AttackKind.EXPLODE:
			pass
		EnemyData.AttackKind.GUST:
			enemy.move_toward_velocity(Vector2.ZERO, delta)
			_blow()
			_time_left -= delta
			if _time_left <= 0.0:
				machine.transition_to(&"Recover")
		_:
			machine.transition_to(&"Recover")


func _update_charge(delta: float) -> void:
	_time_left -= delta
	enemy.move_velocity = _charge_direction * enemy.behavior.charge_speed
	enemy.apply_velocity()
	if enemy.get_slide_collision_count() > 0:
		if enemy.behavior.charge_axis_only:
			var rock := enemy.get_slide_collision(0).get_collider() as Rock
			if rock != null:
				rock.destroy()
		EventBus.shake_requested.emit(WALL_BUMP_TRAUMA)
		machine.transition_to(&"Recover")
	elif _time_left <= 0.0:
		machine.transition_to(&"Recover")


func _first_pattern() -> BulletPatternData:
	return enemy.behavior.patterns[0] if not enemy.behavior.patterns.is_empty() else null


## Invoca hasta summon_count, sin pasar de summon_cap vivos.
func _summon() -> void:
	var free_slots: int = enemy.behavior.summon_cap - enemy.living_children()
	var count: int = mini(enemy.behavior.summon_count, free_slots)
	if enemy.behavior.summon == null or count <= 0:
		return
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.COMBAT)
	var start: float = rng.randf() * TAU
	for i: int in count:
		var direction: Vector2 = Vector2.from_angle(start + TAU * i / count)
		var at: Vector2 = enemy.global_position + direction * SUMMON_DISTANCE
		if enemy.behavior.summon_anywhere:
			at = enemy.scenery_spot(rng)
		enemy.spawn_child(enemy.behavior.summon, at)
	enemy.visual.play_hit()
	AudioManager.play_sfx(&"summon", 0.1)


## Un tajo corto hacia el jugador, donde está (hasta su alcance), con un saltito (las tijeras). El aviso
## ya lo dio Telegraph: hay que alejarse o rodar.
func _slash() -> void:
	var offset: Vector2 = enemy.to_target()
	var direction: Vector2 = offset.normalized() if offset != Vector2.ZERO else enemy.visual.look_direction
	var reach: float = clampf(offset.length(), enemy.data.body_radius + 2.0, enemy.behavior.attack_range)
	var strike := Fx.spawn(get_tree(), STRIKE_SCENE, enemy.global_position + direction * reach) as BossStrike
	strike.look = BossAttack.Look.BLADE
	strike.warn_time = SLASH_WARN
	strike.damage = enemy.behavior.attack_damage
	strike.radius = SLASH_WIDTH
	strike.slash = direction.orthogonal() * enemy.behavior.blast_radius
	enemy.move_velocity = direction * enemy.behavior.charge_speed
	enemy.visual.set_look(direction)
	AudioManager.play_sfx(&"snip", 0.1)


## GUST: empuja al jugador si está adelante, en el abanico y al alcance.
func _blow() -> void:
	if not enemy.has_target():
		return
	var offset: Vector2 = enemy.to_target()
	if offset.length() > enemy.behavior.attack_range or offset == Vector2.ZERO:
		return
	if offset.normalized().dot(_gust_direction) < cos(deg_to_rad(GUST_CONE * 0.5)):
		return
	enemy.target.push(_gust_direction * enemy.behavior.charge_speed)


## Tira una bola que cae donde está el jugador ahora.
func _lob() -> void:
	if not enemy.has_target():
		return
	var shell := Fx.spawn(get_tree(), LOB_SHELL_SCENE, enemy.target.global_position) as LobShell
	shell.origin = enemy.global_position + Vector2(0, -6)
	shell.duration = enemy.behavior.lob_time
	shell.damage = enemy.behavior.attack_damage
	shell.radius = enemy.behavior.blast_radius
	shell.pattern = _first_pattern()
	shell.speed_multiplier = enemy.bullet_speed_multiplier
	shell.color = enemy.data.body_color.lightened(0.25)
	AudioManager.play_sfx(&"lob", 0.1)
