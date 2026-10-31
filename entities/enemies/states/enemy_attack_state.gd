class_name EnemyAttackState
extends State
## Ataque según behavior.attack_kind: embestida hacia donde estaba el jugador al terminar el aviso
## (CHARGE), el próximo patrón de balas (SHOOT), el rayo por la línea que avisó (BEAM), explotar y
## morir (EXPLODE), invocar enemigos (SUMMON) o tirar una bola que cae donde está el jugador (LOB).
## Los que andan bajo tierra (BURROW) asoman al atacar.

const WALL_BUMP_TRAUMA: float = 0.25
## Velocidad que conserva al terminar la embestida (el resto lo frena en Recover).
const CHARGE_END_FACTOR: float = 0.35
const LOB_SHELL_SCENE: PackedScene = preload("res://entities/enemies/lob_shell.tscn")
## Distancia desde el centro a la que nacen las invocaciones.
const SUMMON_DISTANCE: float = 8.0

var _charge_direction: Vector2 = Vector2.DOWN
var _time_left: float = 0.0

@onready var enemy: Enemy = owner as Enemy


func enter(_previous: StringName) -> void:
	if enemy.behavior.move_style == EnemyData.MoveStyle.BURROW:
		enemy.set_hidden(false)
		AudioManager.play_sfx(&"burrow", 0.1)
	match enemy.behavior.attack_kind:
		EnemyData.AttackKind.CHARGE:
			var offset: Vector2 = enemy.to_target()
			_charge_direction = offset.normalized() if offset != Vector2.ZERO else enemy.visual.look_direction
			_time_left = enemy.behavior.charge_time
			enemy.visual.set_charging(true)
			AudioManager.play_sfx(&"charge", 0.05)
		EnemyData.AttackKind.SHOOT:
			var pattern: BulletPatternData = enemy.next_pattern()
			if pattern != null:
				enemy.emitter.fire(pattern, enemy.target)
		EnemyData.AttackKind.BEAM:
			_time_left = enemy.behavior.beam_time
			AudioManager.play_sfx(&"beam", 0.05)
		EnemyData.AttackKind.EXPLODE:
			EnemyBlast.explode(get_tree(), enemy.global_position, enemy.behavior.blast_radius,
					enemy.behavior.attack_damage, _first_pattern(), enemy.bullet_speed_multiplier, enemy.data.body_color)
			enemy.health.kill()
		EnemyData.AttackKind.SUMMON:
			_summon()
		EnemyData.AttackKind.LOB:
			_lob()


func exit() -> void:
	enemy.visual.set_charging(false)
	enemy.emitter.stop()
	enemy.beam.stop()
	if enemy.behavior.attack_kind == EnemyData.AttackKind.CHARGE:
		enemy.move_velocity *= CHARGE_END_FACTOR


func physics_update(delta: float) -> void:
	match enemy.behavior.attack_kind:
		EnemyData.AttackKind.CHARGE:
			_update_charge(delta)
		EnemyData.AttackKind.SHOOT:
			enemy.move_toward_velocity(Vector2.ZERO, delta)
			if not enemy.emitter.is_firing():
				machine.transition_to(&"Recover")
		EnemyData.AttackKind.BEAM:
			enemy.move_toward_velocity(Vector2.ZERO, delta)
			enemy.beam.fire(enemy.beam_origin(), enemy.beam_direction, enemy.behavior.attack_damage)
			_time_left -= delta
			if _time_left <= 0.0:
				machine.transition_to(&"Recover")
		EnemyData.AttackKind.EXPLODE:
			pass
		_:
			machine.transition_to(&"Recover")


func _update_charge(delta: float) -> void:
	_time_left -= delta
	enemy.move_velocity = _charge_direction * enemy.behavior.charge_speed
	enemy.apply_velocity()
	if enemy.get_slide_collision_count() > 0:
		EventBus.shake_requested.emit(WALL_BUMP_TRAUMA)
		machine.transition_to(&"Recover")
	elif _time_left <= 0.0:
		machine.transition_to(&"Recover")


func _first_pattern() -> BulletPatternData:
	return enemy.behavior.patterns[0] if not enemy.behavior.patterns.is_empty() else null


## Invoca hasta summon_count, sin pasar de summon_cap vivos.
func _summon() -> void:
	var free_slots: int = enemy.behavior.summon_cap - enemy.living_children()
	var count: int = mini(enemy.behavior.summon_count, free_slots)
	if enemy.behavior.summon == null or count <= 0:
		return
	var start: float = GameRNG.stream(RngStreams.COMBAT).randf() * TAU
	for i: int in count:
		var direction: Vector2 = Vector2.from_angle(start + TAU * i / count)
		enemy.spawn_child(enemy.behavior.summon, enemy.global_position + direction * SUMMON_DISTANCE)
	enemy.visual.play_hit()
	AudioManager.play_sfx(&"summon", 0.1)


## Tira una bola que cae donde está el jugador ahora.
func _lob() -> void:
	if not enemy.has_target():
		return
	var shell := Fx.spawn(get_tree(), LOB_SHELL_SCENE, enemy.target.global_position) as LobShell
	shell.origin = enemy.global_position + Vector2(0, -6)
	shell.duration = enemy.behavior.lob_time
	shell.damage = enemy.behavior.attack_damage
	shell.radius = enemy.behavior.blast_radius
	shell.pattern = _first_pattern()
	shell.speed_multiplier = enemy.bullet_speed_multiplier
	shell.color = enemy.data.body_color.lightened(0.25)
	AudioManager.play_sfx(&"lob", 0.1)
