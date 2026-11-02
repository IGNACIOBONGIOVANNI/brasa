class_name SnowballMove
extends BossMove
## SNOWBALL: empuja `count` bolas de nieve gigantes (una cada `interval` s) hacia el jugador. Cada una
## rueda a `speed` px/s, rebota en las paredes, rompe las rocas que toca, crece desde `radius` y se
## deshace a los `linger` s (RollingBall). Pasarle por encima lastima `damage`.

const BALL_SCENE: PackedScene = preload("res://entities/enemies/rolling_ball.tscn")

var _left: int = 0
var _next: float = 0.0
var _wait: float = 0.0


func _begin() -> void:
	_left = attack.count


func _tick(delta: float) -> bool:
	hold(delta)
	if _left > 0:
		_next -= delta
		if _next <= 0.0:
			_roll()
			_left -= 1
			_next = attack.interval
		return false
	_wait += delta
	return _wait >= attack.warn_time


func _roll() -> void:
	var offset: Vector2 = target_position() - enemy.global_position
	var direction: Vector2 = offset.normalized() if offset != Vector2.ZERO else Vector2.DOWN
	var at: Vector2 = enemy.global_position + direction * (enemy.data.body_radius + attack.radius)
	var ball := Fx.spawn(enemy.get_tree(), BALL_SCENE, at, Fx.ENTITIES_GROUP) as RollingBall
	ball.velocity = direction * attack.speed
	ball.radius = attack.radius
	ball.damage = attack.damage
	ball.lifetime = attack.linger
	ball.area = enemy.room_rect()
	AudioManager.play_sfx(&"snowball", 0.1)
