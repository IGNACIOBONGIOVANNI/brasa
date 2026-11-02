class_name GroundLinesMove
extends BossMove
## GROUND_LINES: golpes que avanzan por el piso desde el jefe (raíces que salen, grietas de fuego):
## `count` líneas en abanico de `spread` grados hacia el jugador o, sin `aim_at_player`, repartidas en
## 360°. Cada `interval` s cada línea avanza un paso y pone un golpe avisado; una línea corta en la
## pared, en una roca o en un foso (sirven para cubrirse).

## Distancia entre golpes de una misma línea.
const STEP: float = 14.0
const SLAM_TRAUMA: float = 0.3

var _origin: Vector2 = Vector2.ZERO
var _directions: Array[Vector2] = []
var _reach: Array[float] = []
var _next: float = 0.0
var _wait: float = 0.0


func _begin() -> void:
	_origin = enemy.global_position
	EventBus.shake_requested.emit(SLAM_TRAUMA)
	var base: float = (target_position() - _origin).angle() if attack.aim_at_player else rng().randf() * TAU
	for i: int in attack.count:
		var angle: float
		if attack.aim_at_player:
			angle = base + deg_to_rad(attack.spread) * (i - (attack.count - 1) * 0.5)
		else:
			angle = base + TAU * i / attack.count
		_directions.append(Vector2.from_angle(angle))
		_reach.append(enemy.data.body_radius + STEP * 0.5)


func _tick(delta: float) -> bool:
	hold(delta)
	if not _directions.is_empty():
		_next -= delta
		if _next <= 0.0:
			_next = attack.interval
			_advance()
		return false
	_wait += delta
	return _wait >= attack.warn_time


## Cada línea avanza un paso; las que llegaron a algo que las corta se terminan.
func _advance() -> void:
	var area: Rect2 = enemy.room_rect().grow(-4.0)
	for i: int in range(_directions.size() - 1, -1, -1):
		_reach[i] += STEP
		var at: Vector2 = _origin + _directions[i] * _reach[i]
		if not area.has_point(at) or not _open(at):
			_directions.remove_at(i)
			_reach.remove_at(i)
			continue
		spawn_strike(at, attack.look)


func _open(at: Vector2) -> bool:
	return enemy.nav == null or enemy.nav.is_open(RoomNav.cell_of(at - enemy.nav_origin))
