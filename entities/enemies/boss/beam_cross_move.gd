class_name BeamCrossMove
extends BossMove
## BEAM_CROSS: `count` rayos repartidos alrededor del jefe (el suyo y otros EnemyBeam). Se ven
## `warn_time` s girando despacio y después disparan girando a `speed` grados por segundo durante
## `linger` s, para un lado al azar. Hay que ir corriendo delante del rayo o rodar a través de uno.

enum Step { PREVIEW, FIRE }

## En el aviso giran a esta fracción de la velocidad (se ve hacia dónde van a girar).
const PREVIEW_TURN: float = 0.25
const START_TRAUMA: float = 0.3

var _step: Step = Step.PREVIEW
var _time: float = 0.0
var _angle: float = 0.0
var _turn: float = 1.0
## Los rayos de más (el primero es el del jefe).
var _beams: Array[EnemyBeam] = []


func _begin() -> void:
	# Que ningún rayo arranque encima del jugador: el jugador queda entre dos.
	var count: int = maxi(2, attack.count)
	_angle = (target_position() - enemy.global_position).angle() + PI / count
	_turn = 1.0 if rng().randf() < 0.5 else -1.0
	for _i: int in count - 1:
		var beam := EnemyBeam.new()
		beam.material = enemy.beam.material
		beam.color = enemy.beam.color
		enemy.add_child(beam)
		_beams.append(beam)


func _tick(delta: float) -> bool:
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	_time += delta
	var all: Array[EnemyBeam] = [enemy.beam]
	all.append_array(_beams)
	match _step:
		Step.PREVIEW:
			_angle += _turn * deg_to_rad(attack.speed) * PREVIEW_TURN * delta
			for i: int in all.size():
				var direction: Vector2 = _direction(i, all.size())
				all[i].preview(_origin(direction), direction)
			if _time >= attack.warn_time:
				_step = Step.FIRE
				_time = 0.0
				EventBus.shake_requested.emit(START_TRAUMA)
				AudioManager.play_sfx(&"beam", 0.05)
		Step.FIRE:
			_angle += _turn * deg_to_rad(attack.speed) * delta
			for i: int in all.size():
				var direction: Vector2 = _direction(i, all.size())
				all[i].fire(_origin(direction), direction, attack.damage)
			if _time >= attack.linger:
				return true
	return false


func _end() -> void:
	enemy.beam.stop()
	for beam: EnemyBeam in _beams:
		if is_instance_valid(beam):
			beam.queue_free()
	_beams.clear()


func _direction(index: int, count: int) -> Vector2:
	return Vector2.from_angle(_angle + TAU * index / count)


func _origin(direction: Vector2) -> Vector2:
	return enemy.global_position + Vector2(0, -2) + direction * enemy.data.body_radius
