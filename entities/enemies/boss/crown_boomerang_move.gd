class_name CrownBoomerangMove
extends BossMove
## CROWN_BOOMERANG: tira `count` coronas de clavos (CrownBoomerang) en abanico de `spread` grados hacia
## el jugador, a `speed` px/s. Cada una vuela `interval` s frenando, suelta `pattern` y vuelve a su mano:
## hay que esquivarla a la ida y a la vuelta. Termina cuando volvieron todas (o a los MAX_TIME s).

const MAX_TIME: float = 4.0
const THROW_TRAUMA: float = 0.25

var _crowns: Array[int] = []
var _time: float = 0.0


func _begin() -> void:
	var aim: float = (target_position() - enemy.global_position).angle()
	var spread: float = deg_to_rad(attack.spread)
	for i: int in attack.count:
		var offset: float = 0.0 if attack.count == 1 else -spread * 0.5 + spread * i / (attack.count - 1)
		var crown := CrownBoomerang.new()
		crown.direction = Vector2.from_angle(aim + offset)
		crown.speed = attack.speed * enemy.bullet_speed_multiplier
		crown.out_time = attack.interval
		crown.radius = attack.radius
		crown.damage = attack.damage
		crown.pattern = attack.pattern
		crown.speed_multiplier = enemy.bullet_speed_multiplier
		crown.owner_id = enemy.get_instance_id()
		place(crown, enemy.global_position + Vector2(0, -6))
		_crowns.append(crown.get_instance_id())
	enemy.visual.play_hit()
	EventBus.shake_requested.emit(THROW_TRAUMA)
	AudioManager.play_sfx(&"orb_throw", 0.05)


func _tick(delta: float) -> bool:
	hold(delta)
	_time += delta
	var flying: int = 0
	for id: int in _crowns:
		if instance_from_id(id) != null:
			flying += 1
	return flying == 0 or _time >= MAX_TIME
