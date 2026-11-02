class_name GustMove
extends BossMove
## GUST: el jefe toma aire y sopla por toda la sala. Primero `warn_time` s de aviso (el viento ya se
## ve pero no empuja) y después `linger` s de viento que empuja al jugador a `speed` px/s, del jefe
## hacia el jugador por el eje más largo; mientras sopla tira `pattern` cada `interval` s.

const WIND_SCENE: PackedScene = preload("res://fx/wind_gust.tscn")
const GUST_TRAUMA: float = 0.2

var direction: Vector2 = Vector2.RIGHT
var _time: float = 0.0
var _shoot: float = 0.0
var _wind_id: int = 0


func _begin() -> void:
	var offset: Vector2 = target_position() - enemy.global_position
	direction = Vector2(signf(offset.x), 0.0) if absf(offset.x) >= absf(offset.y) else Vector2(0.0, signf(offset.y))
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	var room: Rect2 = enemy.room_rect()
	var horizontal: bool = direction.y == 0.0
	var edge: Vector2 = room.get_center() - direction * (room.size.x if horizontal else room.size.y) * 0.5
	var wind := Fx.spawn(enemy.get_tree(), WIND_SCENE, edge) as WindGust
	wind.direction = direction
	wind.length = room.size.x if horizontal else room.size.y
	wind.width = room.size.y if horizontal else room.size.x
	wind.duration = attack.warn_time + attack.linger
	_wind_id = wind.get_instance_id()
	AudioManager.play_sfx(&"gust", 0.05)
	EventBus.shake_requested.emit(GUST_TRAUMA)


func _tick(delta: float) -> bool:
	hold(delta)
	_time += delta
	if _time < attack.warn_time:
		return false
	if enemy.has_target():
		enemy.target.push(direction * attack.speed)
	if attack.pattern != null and enemy.has_target() and not enemy.emitter.is_firing():
		_shoot -= delta
		if _shoot <= 0.0:
			_shoot = attack.interval
			enemy.emitter.fire(attack.pattern, enemy.target)
	return _time >= attack.warn_time + attack.linger


func _end() -> void:
	enemy.emitter.stop()
	var wind := instance_from_id(_wind_id) as WindGust
	if wind != null:
		wind.queue_free()
