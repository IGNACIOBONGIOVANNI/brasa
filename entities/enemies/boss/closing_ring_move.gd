class_name ClosingRingMove
extends BossMove
## CLOSING_RING: un cerco de espinas (ShockRing que se achica) arranca afuera de la sala y se cierra
## hacia el jefe a `speed` px/s, con un hueco de `spread` grados. `count` cercos, uno cada `interval` s,
## con el hueco girando. Hay que pasar por el hueco cuando llega, o rodar a través de las espinas.

const GAP_TURN: float = 1.3

var _left: int = 0
var _next: float = 0.0
var _wait: float = 0.0
var _gap_angle: float = 0.0


func _begin() -> void:
	_left = attack.count
	_gap_angle = rng().randf() * TAU


func _tick(delta: float) -> bool:
	hold(delta)
	if _left > 0:
		_next -= delta
		if _next <= 0.0:
			_spawn_ring()
			_left -= 1
			_next = attack.interval
		return false
	_wait += delta
	return _wait >= attack.warn_time


func _spawn_ring() -> void:
	var room: Rect2 = enemy.room_rect()
	var reach: float = 0.0
	for corner: Vector2 in [room.position, room.end, Vector2(room.position.x, room.end.y), Vector2(room.end.x, room.position.y)]:
		reach = maxf(reach, corner.distance_to(enemy.global_position))
	var ring := ShockRing.new()
	ring.radius = reach + 8.0
	ring.max_radius = reach + 16.0
	ring.min_radius = enemy.data.body_radius + 4.0
	ring.speed = -attack.speed * enemy.bullet_speed_multiplier
	ring.thickness = attack.radius
	ring.damage = attack.damage
	ring.gap = deg_to_rad(attack.spread)
	ring.gap_angle = _gap_angle
	ring.thorny = true
	place(ring, enemy.global_position)
	_gap_angle += GAP_TURN
	AudioManager.play_sfx(&"root", 0.1)
