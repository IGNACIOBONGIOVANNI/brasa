class_name ThreadTrailMove
extends BossMove
## THREAD_TRAIL: suelta `count` ovillos (ThreadBall) que ruedan rebotando en la sala a `speed` px/s
## durante `linger` s y dejan atrás un hilo que corta (cada tramo dura `interval` s). El primero sale
## hacia el jugador; los demás, abiertos en abanico.

## Pausa del jefe después de soltarlos (los ovillos siguen solos).
const AFTER_THROW: float = 0.6

var _time: float = 0.0


func _begin() -> void:
	var aim: float = (target_position() - enemy.global_position).angle()
	for i: int in attack.count:
		var ball := ThreadBall.new()
		var side: float = 1.0 if i % 2 == 1 else -1.0
		ball.direction = Vector2.from_angle(aim + side * ceili(i * 0.5) * 0.7)
		ball.speed = attack.speed * enemy.bullet_speed_multiplier
		ball.life = attack.linger
		ball.trail_time = attack.interval
		ball.radius = attack.radius
		ball.damage = attack.damage
		ball.area = enemy.room_rect()
		place(ball, enemy.global_position + ball.direction * enemy.data.body_radius)
	enemy.visual.play_hit()
	AudioManager.play_sfx(&"snip", 0.05)


func _tick(delta: float) -> bool:
	hold(delta)
	_time += delta
	return _time >= AFTER_THROW
