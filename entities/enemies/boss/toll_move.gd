class_name TollMove
extends BossMove
## TOLL: tañe y salen `count` ondas de sonido (ShockRing), una cada `interval` s, que se agrandan a
## `speed` px/s, de `radius` px de grueso y con un hueco de `spread` grados. El hueco de la primera
## queda del lado contrario al jugador (hay que rodear al jefe o rodar) y cada onda lo gira un poco.

const TOLL_TRAUMA: float = 0.3
## Cuánto gira el hueco de una onda a la siguiente.
const GAP_TURN: float = 0.9

var _left: int = 0
var _next: float = 0.0
var _gap_angle: float = 0.0
var _turn: float = GAP_TURN


func _begin() -> void:
	_left = attack.count
	_gap_angle = (enemy.global_position - target_position()).angle()
	_turn = GAP_TURN if rng().randf() < 0.5 else -GAP_TURN


func _tick(delta: float) -> bool:
	hold(delta)
	if _left <= 0:
		_next -= delta
		return _next <= -attack.recover * 0.5
	_next -= delta
	if _next <= 0.0:
		var ring := ShockRing.new()
		ring.speed = attack.speed * enemy.bullet_speed_multiplier
		ring.thickness = attack.radius
		ring.damage = attack.damage
		ring.gap = deg_to_rad(attack.spread)
		ring.gap_angle = _gap_angle
		ring.max_radius = enemy.room_rect().size.length() * 0.6
		place(ring, enemy.global_position)
		_gap_angle += _turn
		_left -= 1
		_next = attack.interval
		enemy.visual.play_hit()
		EventBus.shake_requested.emit(TOLL_TRAUMA)
		AudioManager.play_sfx(&"boss_phase", 0.1)
	return false
