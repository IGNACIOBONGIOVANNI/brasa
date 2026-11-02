class_name ScissorsMove
extends BossMove
## SCISSORS: dos hojas (dos rayos) que salen del jefe abiertas `spread` grados alrededor del jugador
## y se cierran hacia el medio a `speed` grados por segundo. Antes se ven `warn_time` s. Hay que
## salirse de entre las hojas (por los costados, o por detrás del jefe) o rodar a través de una.
## `count` cortes seguidos, cada uno con su aviso.

enum Step { PREVIEW, CLOSE }

const CUT_TRAUMA: float = 0.25

var _step: Step = Step.PREVIEW
var _time: float = 0.0
var _center: float = 0.0
var _open: float = 0.0
var _cuts: int = 0
## La otra hoja (la primera es el rayo del jefe).
var _blade: EnemyBeam


func _begin() -> void:
	_blade = EnemyBeam.new()
	_blade.material = enemy.beam.material
	_blade.color = enemy.beam.color
	enemy.add_child(_blade)
	_aim()


func _tick(delta: float) -> bool:
	_time += delta
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	enemy.visual.set_look(Vector2.from_angle(_center))
	var first: Vector2 = Vector2.from_angle(_center - _open)
	var second: Vector2 = Vector2.from_angle(_center + _open)
	match _step:
		Step.PREVIEW:
			enemy.beam.preview(_origin(first), first)
			_blade.preview(_origin(second), second)
			if _time >= attack.warn_time:
				AudioManager.play_sfx(&"beam", 0.05)
				_step = Step.CLOSE
		Step.CLOSE:
			enemy.beam.fire(_origin(first), first, attack.damage)
			_blade.fire(_origin(second), second, attack.damage)
			_open = maxf(0.0, _open - deg_to_rad(attack.speed) * delta)
			if _open <= 0.0:
				_cuts += 1
				AudioManager.play_sfx(&"snip", 0.05)
				EventBus.shake_requested.emit(CUT_TRAUMA)
				if _cuts >= attack.count:
					return true
				_aim()
	return false


func _end() -> void:
	enemy.beam.stop()
	if is_instance_valid(_blade):
		_blade.queue_free()


## Abre las hojas alrededor de donde está el jugador ahora.
func _aim() -> void:
	_center = (target_position() - enemy.global_position).angle()
	_open = deg_to_rad(attack.spread) * 0.5
	_step = Step.PREVIEW
	_time = 0.0


func _origin(direction: Vector2) -> Vector2:
	return enemy.global_position + Vector2(0, -2) + direction * enemy.data.body_radius
