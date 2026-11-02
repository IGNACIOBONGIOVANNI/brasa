class_name SweepMove
extends BossMove
## SWEEP: un rayo que barre `spread` grados a `speed` grados por segundo, empezando a un costado del
## jugador (al azar a qué lado). Antes muestra `warn_time` s la línea donde arranca. Hay que correr
## para el lado del barrido o rodar a través del rayo.

enum Step { PREVIEW, FIRE }

var _step: Step = Step.PREVIEW
var _time: float = 0.0
var _angle: float = 0.0
var _swept: float = 0.0
var _sign: float = 1.0


func _begin() -> void:
	_sign = 1.0 if rng().randf() < 0.5 else -1.0
	_angle = (target_position() - enemy.global_position).angle() - _sign * deg_to_rad(attack.spread) * 0.5
	enemy.beam_direction = Vector2.from_angle(_angle)


func _tick(delta: float) -> bool:
	_time += delta
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	enemy.visual.set_look(enemy.beam_direction)
	match _step:
		Step.PREVIEW:
			enemy.beam.preview(enemy.beam_origin(), enemy.beam_direction)
			if _time >= attack.warn_time:
				AudioManager.play_sfx(&"beam", 0.05)
				_step = Step.FIRE
		Step.FIRE:
			var turn: float = deg_to_rad(attack.speed) * delta
			_angle += _sign * turn
			_swept += turn
			enemy.beam_direction = Vector2.from_angle(_angle)
			enemy.beam.fire(enemy.beam_origin(), enemy.beam_direction, attack.damage)
			if _swept >= deg_to_rad(attack.spread):
				return true
	return false


func _end() -> void:
	enemy.beam.stop()
