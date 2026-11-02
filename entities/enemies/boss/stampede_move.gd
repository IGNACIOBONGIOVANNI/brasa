class_name StampedeMove
extends BossMove
## STAMPEDE: el jefe brama y una manada cruza la sala: `count` oleadas, una cada `interval` s, de
## franjas de punta a punta (horizontales y verticales alternadas) con un solo hueco libre, cerca del
## jugador. Cada franja avisa `warn_time` s y lastima `linger` s mientras pasa la manada: hay que
## meterse en el hueco (o rodar justo cuando pasa).

## Ancho de cada franja: la sala (240 x 144) queda en 6 filas o 10 columnas.
const LANE: float = 24.0
const ROAR_TRAUMA: float = 0.35

var _left: int = 0
var _wave: int = 0
var _next: float = 0.0
var _wait: float = 0.0


func _begin() -> void:
	_left = attack.count
	AudioManager.play_sfx(&"stampede", 0.05)
	EventBus.shake_requested.emit(ROAR_TRAUMA)


func _tick(delta: float) -> bool:
	hold(delta)
	if _left > 0:
		_next -= delta
		if _next <= 0.0:
			spawn_wave(_wave % 2 == 0)
			_wave += 1
			_left -= 1
			_next = attack.interval
		return false
	_wait += delta
	return _wait >= attack.warn_time + attack.linger


## Una oleada: todas las franjas menos una, al lado de la del jugador o la misma. Devuelve el centro
## del hueco.
func spawn_wave(horizontal: bool) -> Vector2:
	var room: Rect2 = enemy.room_rect()
	var span: float = room.size.y if horizontal else room.size.x
	var lanes: int = maxi(2, floori(span / LANE))
	var local: Vector2 = target_position() - room.position
	var player_lane: int = clampi(floori((local.y if horizontal else local.x) / LANE), 0, lanes - 1)
	var gap: int = clampi(player_lane + rng().randi_range(-1, 1), 0, lanes - 1)
	var gap_center := Vector2.ZERO
	for i: int in lanes:
		var center: Vector2
		if horizontal:
			center = Vector2(room.get_center().x, room.position.y + LANE * (i + 0.5))
		else:
			center = Vector2(room.position.x + LANE * (i + 0.5), room.get_center().y)
		if i == gap:
			gap_center = center
			continue
		var strike: BossStrike = spawn_strike(center, BossAttack.Look.HOOVES)
		strike.radius = LANE * 0.5 - 2.0
		strike.slash = Vector2(room.size.x * 0.5, 0.0) if horizontal else Vector2(0.0, room.size.y * 0.5)
		strike.linger = attack.linger
	return gap_center
