class_name EchoChargesMove
extends ChargesMove
## ECHO_CHARGES: embiste como CHARGES y, cuando termina, los fantasmas de su manada repiten cada
## embestida por el mismo camino: una franja que avisa `warn_time` s y después pasa la manada (una cada
## `interval` s, en el orden en que embistió). Hay que acordarse por dónde pasó.

## Cuánto dura pasando cada eco.
const ECHO_LINGER: float = 0.3

## Cada embestida: de dónde salió y dónde terminó (globales).
var _paths: Array[PackedVector2Array] = []
var _dash_from: Vector2 = Vector2.ZERO
var _echoing: bool = false
var _echo_time: float = 0.0
var _echo_total: float = 0.0


func _tick(delta: float) -> bool:
	if not _echoing:
		if super._tick(delta):
			_start_echoes()
		return false
	hold(delta)
	_echo_time += delta
	return _echo_time >= _echo_total


func _next(step: ChargesMove.Step) -> void:
	if step == ChargesMove.Step.DASH:
		_dash_from = enemy.global_position
	super._next(step)


func _end_dash() -> void:
	_paths.append(PackedVector2Array([_dash_from, enemy.global_position]))
	super._end_dash()


func _start_echoes() -> void:
	_echoing = true
	enemy.beam.stop()
	enemy.visual.set_charging(false)
	for i: int in _paths.size():
		var from: Vector2 = _paths[i][0]
		var to: Vector2 = _paths[i][1]
		if from.distance_to(to) < 4.0:
			continue
		var strike: BossStrike = spawn_strike((from + to) * 0.5, BossAttack.Look.HOOVES)
		strike.slash = (to - from) * 0.5
		strike.radius = enemy.data.body_radius + 2.0
		strike.warn_time = attack.warn_time + attack.interval * i
		strike.linger = ECHO_LINGER
	_echo_total = attack.warn_time + attack.interval * maxi(0, _paths.size() - 1) + ECHO_LINGER
	if not _paths.is_empty():
		AudioManager.play_sfx(&"stampede", 0.05)
