class_name IceSpiralMove
extends BossMove
## ICE_SPIRAL: caen carámbanos en `count` brazos de espiral que salen del jefe hacia afuera, un paso
## cada `interval` s (en todos los brazos a la vez). Cada uno avisa con su sombra `warn_time` s y pega
## en `radius`. Los brazos giran: el lugar seguro se va corriendo y hay que acompañarlo.

## Pasos de cada brazo, la distancia del primero y cuánto se aleja y gira cada paso.
const STEPS: int = 9
const FIRST_DISTANCE: float = 22.0
const STEP_DISTANCE: float = 13.0
const STEP_TURN: float = 0.42

var _step: int = 0
var _next: float = 0.0
var _wait: float = 0.0
var _start_angle: float = 0.0
var _turn: float = STEP_TURN
var _center: Vector2 = Vector2.ZERO


func _begin() -> void:
	_center = enemy.global_position
	_start_angle = (target_position() - _center).angle() + PI / maxi(1, attack.count)
	_turn = STEP_TURN if rng().randf() < 0.5 else -STEP_TURN
	AudioManager.play_sfx(&"rumble", 0.05)


func _tick(delta: float) -> bool:
	hold(delta)
	if _step < STEPS:
		_next -= delta
		if _next <= 0.0:
			_drop_step()
			_step += 1
			_next = attack.interval
		return false
	_wait += delta
	return _wait >= attack.warn_time


func _drop_step() -> void:
	var area: Rect2 = enemy.room_rect().grow(-4.0)
	var distance: float = FIRST_DISTANCE + _step * STEP_DISTANCE
	for arm: int in attack.count:
		var angle: float = _start_angle + TAU * arm / attack.count + _step * _turn
		var at: Vector2 = _center + Vector2.from_angle(angle) * distance
		if area.has_point(at):
			spawn_strike(at, BossAttack.Look.ICE)
