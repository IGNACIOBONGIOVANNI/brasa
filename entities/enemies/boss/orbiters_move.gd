class_name OrbitersMove
extends BossMove
## ORBITERS: suelta `count` bolas con cadena (OrbitBall) que giran a su alrededor a `speed` grados por
## segundo: salen pegadas al jefe, se abren hasta `spread` px y vuelven, durante `linger` s. Lastiman al
## tocarlas (en `radius`). Hay que quedarse lejos o meterse entre dos bolas.

var _time: float = 0.0


func _begin() -> void:
	var first: float = rng().randf() * TAU
	var turn: float = deg_to_rad(attack.speed) * (1.0 if rng().randf() < 0.5 else -1.0)
	for i: int in attack.count:
		var ball := OrbitBall.new()
		ball.owner_id = enemy.get_instance_id()
		ball.angle = first + TAU * i / attack.count
		ball.turn_speed = turn
		ball.max_radius = attack.spread
		ball.life = attack.linger
		ball.radius = attack.radius
		ball.damage = attack.damage
		place(ball, enemy.global_position)
	AudioManager.play_sfx(&"orb_throw", 0.05)


func _tick(delta: float) -> bool:
	hold(delta)
	_time += delta
	return _time >= attack.linger
