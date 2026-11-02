class_name LeapMove
extends BossMove
## LEAP: salta (en el aire no recibe ni hace daño), su sombra persigue al jugador `warn_time` s,
## queda fija `lock_time` s y cae encima: pega en `radius` y suelta `pattern` (la onda). `count`
## saltos seguidos. Nunca cae en un foso ni en una roca (Enemy.landing_spot).

const HEIGHT: float = 150.0
const RISE_TIME: float = 0.3
const FALL_TIME: float = 0.16
## Qué tan rápido lo sigue la sombra (un poco más lento que el jugador corriendo).
const TRACK_SPEED: float = 95.0
const LAND_TRAUMA: float = 0.5

enum Step { RISE, TRACK, LOCK, FALL }

var _step: Step = Step.RISE
var _left: int = 0
var _time: float = 0.0


func _begin() -> void:
	_left = attack.count
	_rise()


func _tick(delta: float) -> bool:
	_time += delta
	match _step:
		Step.RISE:
			enemy.visual.set_lift(HEIGHT * ease(minf(_time / RISE_TIME, 1.0), 0.5))
			if _time >= RISE_TIME:
				_next(Step.TRACK)
		Step.TRACK:
			var goal: Vector2 = enemy.landing_spot(target_position())
			enemy.global_position = enemy.global_position.move_toward(goal, TRACK_SPEED * delta)
			if _time >= attack.warn_time:
				_next(Step.LOCK)
		Step.LOCK:
			if _time >= attack.lock_time:
				AudioManager.play_sfx(&"leap", 0.1)
				_next(Step.FALL)
		Step.FALL:
			enemy.visual.set_lift(HEIGHT * (1.0 - minf(_time / FALL_TIME, 1.0)))
			if _time >= FALL_TIME:
				_land()
				_left -= 1
				if _left <= 0:
					return true
				_rise()
	return false


func _end() -> void:
	enemy.visual.set_lift(0.0)
	enemy.set_airborne(false)


func _rise() -> void:
	enemy.set_airborne(true)
	enemy.move_velocity = Vector2.ZERO
	AudioManager.play_sfx(&"leap", 0.1)
	_next(Step.RISE)


func _next(step: Step) -> void:
	_step = step
	_time = 0.0


func _land() -> void:
	enemy.visual.set_lift(0.0)
	enemy.set_airborne(false)
	EnemyBlast.explode(enemy.get_tree(), enemy.global_position, attack.radius, attack.damage, attack.pattern,
			enemy.bullet_speed_multiplier, enemy.data.body_color.lightened(0.2))
	EventBus.shake_requested.emit(LAND_TRAUMA)
