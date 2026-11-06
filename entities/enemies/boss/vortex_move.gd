class_name VortexMove
extends BossMove
## VORTEX: el ojo del huracán. Arma un remolino (Vortex) que avisa `warn_time` s y después, durante
## `linger` s, chupa al jugador hacia el jefe a `speed` px/s (menos de lo que camina: se puede escapar
## caminando en contra o rodando) mientras tira `pattern` cada `interval` s.

const PULL_TRAUMA: float = 0.25

var _time: float = 0.0
var _shoot: float = 0.0
var _vortex_id: int = 0


func _begin() -> void:
	var vortex := Vortex.new()
	vortex.radius = enemy.room_rect().size.x * 0.55
	place(vortex, enemy.global_position)
	_vortex_id = vortex.get_instance_id()
	AudioManager.play_sfx(&"gust", 0.05)


func _tick(delta: float) -> bool:
	hold(delta)
	_time += delta
	var vortex := instance_from_id(_vortex_id) as Vortex
	if vortex != null:
		vortex.global_position = enemy.global_position
	if _time < attack.warn_time:
		return false
	if vortex != null and vortex.strength < 1.0:
		vortex.strength = 1.0
		vortex.spin_speed = 5.0
		EventBus.shake_requested.emit(PULL_TRAUMA)
	if enemy.has_target():
		var pull: Vector2 = enemy.global_position - enemy.target.global_position
		if pull.length() > enemy.data.body_radius:
			enemy.target.push(pull.normalized() * attack.speed)
	if attack.pattern != null and enemy.has_target() and not enemy.emitter.is_firing():
		_shoot -= delta
		if _shoot <= 0.0:
			_shoot = attack.interval
			enemy.emitter.fire(attack.pattern, enemy.target)
	return _time >= attack.warn_time + attack.linger


func _end() -> void:
	enemy.emitter.stop()
	var vortex := instance_from_id(_vortex_id) as Vortex
	if vortex != null:
		vortex.queue_free()
