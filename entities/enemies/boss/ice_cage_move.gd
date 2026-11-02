class_name IceCageMove
extends BossMove
## ICE_CAGE: caen `count` carámbanos en ronda alrededor del jugador (a `spread` px) con un hueco de
## dos, del lado del medio de la sala; quedan clavados `linger` s (lastiman al tocarlos) y en el medio
## cae uno enorme que avisa el doble y suelta `pattern`: hay que salir por el hueco a tiempo.

const RUMBLE_TRAUMA: float = 0.3

var _wait: float = 0.0


func _begin() -> void:
	var center: Vector2 = clamp_to_room(target_position(), 6.0)
	var to_middle: Vector2 = enemy.room_rect().get_center() - center
	# El hueco mira al medio de la sala (si el jugador está en el medio, a cualquier lado).
	var turn: float = to_middle.angle() if to_middle.length() > attack.spread * 0.5 else rng().randf() * TAU
	var step: float = TAU / attack.count
	for i: int in attack.count:
		# Los dos que quedan a los lados de `turn` no caen: ese es el hueco.
		if i == 0 or i == attack.count - 1:
			continue
		var at: Vector2 = center + Vector2.from_angle(turn + step * (i + 0.5)) * attack.spread
		var icicle: BossStrike = spawn_strike(at, BossAttack.Look.ICE)
		icicle.linger = attack.linger
	var big: BossStrike = spawn_strike(center, BossAttack.Look.ICE)
	big.radius = attack.spread - attack.radius - 2.0
	big.warn_time = attack.warn_time * 2.0
	big.pattern = attack.pattern
	AudioManager.play_sfx(&"rumble", 0.05)
	EventBus.shake_requested.emit(RUMBLE_TRAUMA)


func _tick(delta: float) -> bool:
	hold(delta)
	_wait += delta
	return _wait >= attack.warn_time * 2.0
