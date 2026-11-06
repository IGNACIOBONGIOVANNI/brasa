class_name BulletWallMove
extends BossMove
## BULLET_WALL: costuras: `count` paredes de balas (`pattern`), una cada `interval` s, que cruzan la sala
## de punta a punta a `speed` px/s, alternando de arriba a abajo y de izquierda a derecha. Cada pared
## tiene un solo hueco de `spread` px cerca de donde está el jugador: hay que meterse ahí.

## Distancia entre una bala y la siguiente de la pared.
const SPACING: float = 11.0

var _left: int = 0
var _next: float = 0.0
var _wait: float = 0.0
var _index: int = 0


func _begin() -> void:
	_left = attack.count


func _tick(delta: float) -> bool:
	hold(delta)
	if _left > 0:
		_next -= delta
		if _next <= 0.0:
			_spawn_wall()
			_left -= 1
			_index += 1
			_next = attack.interval
		return false
	_wait += delta
	return _wait >= 0.5


func _spawn_wall() -> void:
	if attack.pattern == null:
		return
	var room: Rect2 = enemy.room_rect()
	var horizontal: bool = _index % 2 == 0
	var from_start: bool = rng().randf() < 0.5
	var player: Vector2 = target_position()
	var spec := ShotSpec.from_pattern(attack.pattern)
	spec.speed = attack.speed * enemy.bullet_speed_multiplier
	spec.max_range = (room.size.y if horizontal else room.size.x) + 16.0
	# Una pared horizontal baja (o sube) por la sala: sus balas van a lo ancho.
	var length: float = room.size.x if horizontal else room.size.y
	var gap_center: float = (player.x - room.position.x) if horizontal else (player.y - room.position.y)
	gap_center = clampf(gap_center + rng().randf_range(-16.0, 16.0), attack.spread * 0.5, length - attack.spread * 0.5)
	var direction: Vector2
	var edge: float
	if horizontal:
		direction = Vector2.DOWN if from_start else Vector2.UP
		edge = room.position.y + 2.0 if from_start else room.end.y - 2.0
	else:
		direction = Vector2.RIGHT if from_start else Vector2.LEFT
		edge = room.position.x + 2.0 if from_start else room.end.x - 2.0
	var along: float = SPACING * 0.5
	while along < length:
		if absf(along - gap_center) > attack.spread * 0.5:
			var at := Vector2(room.position.x + along, edge) if horizontal else Vector2(edge, room.position.y + along)
			Bullet.spawn(enemy.get_tree(), Bullet.default_scene(), spec, at, direction, PhysicsLayers.ENEMY_BULLET,
					PhysicsLayers.PLAYER_HURTBOX)
		along += SPACING
	enemy.visual.play_hit()
	AudioManager.play_sfx(&"snip", 0.05)
