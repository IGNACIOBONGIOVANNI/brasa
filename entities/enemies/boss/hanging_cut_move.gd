class_name HangingCutMove
extends BossMove
## HANGING_CUT: el jefe tira un tajo largo donde está el jugador, cruzado a la línea entre los dos
## (`spread` px a cada lado). Avisa `warn_time` s y queda en el aire `linger` s: lastima al tocarlo y,
## cada `interval` s, de un punto del corte sale `pattern` hacia el jugador. `count` cortes, uno
## después del otro; termina cuando el último se cierra.

## Entre un corte y el siguiente, además del aviso.
const CUT_GAP: float = 0.25

var _left: int = 0
var _next: float = 0.0
var _shoot: float = 0.0
## Los cortes que tiró (por id: se liberan solos al cerrarse).
var _cuts: Array[int] = []


func _begin() -> void:
	_left = attack.count
	_shoot = attack.warn_time


func _tick(delta: float) -> bool:
	hold(delta)
	if _left > 0:
		_next -= delta
		if _next <= 0.0:
			_cut()
			_left -= 1
			_next = attack.warn_time + CUT_GAP
	_shoot -= delta
	if _shoot <= 0.0:
		_shoot = attack.interval
		_fire_from_cuts()
	return _left <= 0 and live_cuts().is_empty()


## Los cortes que siguen en el aire.
func live_cuts() -> Array[BossStrike]:
	var result: Array[BossStrike] = []
	for id: int in _cuts:
		var strike := instance_from_id(id) as BossStrike
		if strike != null and not strike.is_queued_for_deletion():
			result.append(strike)
	return result


func _cut() -> void:
	var at: Vector2 = clamp_to_room(target_position(), 8.0)
	var offset: Vector2 = at - enemy.global_position
	var across: Vector2 = (offset.orthogonal().normalized() if offset != Vector2.ZERO else Vector2.RIGHT)
	var strike: BossStrike = spawn_strike(at, BossAttack.Look.BLADE)
	strike.slash = across * attack.spread
	strike.linger = attack.linger
	_cuts.append(strike.get_instance_id())
	enemy.visual.set_look(offset.normalized() if offset != Vector2.ZERO else Vector2.DOWN)
	AudioManager.play_sfx(&"snip", 0.05)


## De cada corte ya abierto sale `pattern` desde un punto al azar, hacia el jugador.
func _fire_from_cuts() -> void:
	if attack.pattern == null or not enemy.has_target():
		return
	var spec := ShotSpec.from_pattern(attack.pattern)
	spec.speed *= enemy.bullet_speed_multiplier
	for strike: BossStrike in live_cuts():
		if not strike.has_struck():
			continue
		var at: Vector2 = strike.global_position + strike.slash * rng().randf_range(-0.9, 0.9)
		var aim: Vector2 = (target_position() - at).normalized()
		for direction: Vector2 in PatternMath.directions(attack.pattern, aim, 0):
			Bullet.spawn(enemy.get_tree(), Bullet.default_scene(), spec, at, direction, PhysicsLayers.ENEMY_BULLET,
					PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)
		AudioManager.play_sfx(attack.pattern.sfx_id, 0.1)
