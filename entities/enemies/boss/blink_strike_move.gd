class_name BlinkStrikeMove
extends BossMove
## BLINK_STRIKE: paso de sombra: el jefe se desvanece (en el aire: ni pega ni recibe), su sombra marca
## dónde va a aparecer, al lado del jugador, del lado de atrás (un tajo que avisa `warn_time` s), y
## reaparece ahí con el golpe: pega en `radius` y suelta `pattern`. `count` veces seguidas.

enum Step { GONE, BACK }

## Cuánto queda visible entre un paso y el siguiente.
const BACK_TIME: float = 0.35
## A qué distancia del jugador aparece.
const AMBUSH_DISTANCE: float = 26.0
const GONE_ALPHA: float = 0.15
const STRIKE_TRAUMA: float = 0.35

var _step: Step = Step.GONE
var _left: int = 0
var _time: float = 0.0
var _spot: Vector2 = Vector2.ZERO


func _begin() -> void:
	_left = attack.count
	_vanish()


func _tick(delta: float) -> bool:
	_time += delta
	match _step:
		Step.GONE:
			enemy.move_velocity = Vector2.ZERO
			if _time >= attack.warn_time:
				_appear()
		Step.BACK:
			hold(delta)
			if _time >= BACK_TIME:
				if _left <= 0:
					return true
				_vanish()
	return false


func _end() -> void:
	enemy.set_airborne(false)
	enemy.visual.modulate.a = 1.0


func _vanish() -> void:
	_step = Step.GONE
	_time = 0.0
	enemy.set_airborne(true)
	enemy.visual.modulate.a = GONE_ALPHA
	# Aparece del otro lado del jugador (el que no ve venir el golpe).
	var player: Vector2 = target_position()
	var away: Vector2 = player - enemy.global_position
	var direction: Vector2 = away.normalized() if away != Vector2.ZERO else Vector2.DOWN
	_spot = enemy.landing_spot(player + direction * AMBUSH_DISTANCE)
	var strike: BossStrike = spawn_strike(_spot, BossAttack.Look.CLAW)
	strike.slash = direction.orthogonal() * attack.radius
	strike.pattern = attack.pattern
	AudioManager.play_sfx(&"darkness", 0.1)


func _appear() -> void:
	_step = Step.BACK
	_time = 0.0
	_left -= 1
	enemy.global_position = _spot
	enemy.set_airborne(false)
	enemy.visual.modulate.a = 1.0
	enemy.look_at_target()
	EventBus.shake_requested.emit(STRIKE_TRAUMA)
