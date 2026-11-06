class_name BurrowersMove
extends BossMove
## BURROWERS: hunde las raíces y salen `count` montículos (Burrower) que persiguen al jugador por debajo
## de la tierra a `speed` px/s durante `linger` s (cada uno un poco más que el anterior); después tiemblan
## `warn_time` s y revientan en `radius`, soltando `pattern`. Termina cuando reventó el último.

const SLAM_TRAUMA: float = 0.35
## Diferencia de tiempo de caza entre una raíz y la siguiente (no revientan todas juntas).
const STAGGER: float = 0.35

var _time: float = 0.0
var _total: float = 0.0


func _begin() -> void:
	var aim: float = (target_position() - enemy.global_position).angle()
	for i: int in attack.count:
		var burrower := Burrower.new()
		burrower.direction = Vector2.from_angle(aim + (i - (attack.count - 1) * 0.5) * 0.9)
		burrower.speed = attack.speed * enemy.bullet_speed_multiplier
		burrower.hunt_time = attack.linger + i * STAGGER
		burrower.warn_time = attack.warn_time
		burrower.radius = attack.radius
		burrower.damage = attack.damage
		burrower.pattern = attack.pattern
		burrower.speed_multiplier = enemy.bullet_speed_multiplier
		burrower.area = enemy.room_rect().grow(-8.0)
		place(burrower, enemy.global_position + burrower.direction * enemy.data.body_radius)
	_total = attack.linger + (attack.count - 1) * STAGGER + attack.warn_time
	EventBus.shake_requested.emit(SLAM_TRAUMA)
	AudioManager.play_sfx(&"root", 0.05)


func _tick(delta: float) -> bool:
	hold(delta)
	_time += delta
	return _time >= _total
