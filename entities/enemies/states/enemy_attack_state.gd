class_name EnemyAttackState
extends State
## Ataque según data.attack_kind: embestida en línea recta hacia donde estaba el jugador al
## terminar el aviso (CHARGE), o el próximo patrón de balas (SHOOT).

const WALL_BUMP_TRAUMA: float = 0.25
## Velocidad que conserva al terminar la embestida (el resto lo frena en Recover).
const CHARGE_END_FACTOR: float = 0.35

var _charge_direction: Vector2 = Vector2.DOWN
var _time_left: float = 0.0

@onready var enemy: Enemy = owner as Enemy


func enter(_previous: StringName) -> void:
	if enemy.data.attack_kind == EnemyData.AttackKind.CHARGE:
		var offset: Vector2 = enemy.to_target()
		_charge_direction = offset.normalized() if offset != Vector2.ZERO else enemy.visual.look_direction
		_time_left = enemy.data.charge_time
		enemy.visual.set_charging(true)
		AudioManager.play_sfx(&"charge", 0.05)
		return
	var pattern: BulletPatternData = enemy.next_pattern()
	if pattern != null:
		enemy.emitter.fire(pattern, enemy.target)


func exit() -> void:
	enemy.visual.set_charging(false)
	enemy.emitter.stop()
	if enemy.data.attack_kind == EnemyData.AttackKind.CHARGE:
		enemy.move_velocity *= CHARGE_END_FACTOR


func physics_update(delta: float) -> void:
	if enemy.data.attack_kind == EnemyData.AttackKind.CHARGE:
		_update_charge(delta)
		return
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	if not enemy.emitter.is_firing():
		machine.transition_to(&"Recover")


func _update_charge(delta: float) -> void:
	_time_left -= delta
	enemy.move_velocity = _charge_direction * enemy.data.charge_speed
	enemy.apply_velocity()
	if enemy.get_slide_collision_count() > 0:
		EventBus.shake_requested.emit(WALL_BUMP_TRAUMA)
		machine.transition_to(&"Recover")
	elif _time_left <= 0.0:
		machine.transition_to(&"Recover")
