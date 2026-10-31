extends GutTest
## Hito 5: jefes en la arena de pruebas. Fases por vida, multiplicadores del piso y muerte.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const CAMPANARIO: EnemyData = preload("res://content/enemies/campanario.tres")
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")

var _game: Game


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_game.player.health.always_invulnerable = true


func _spawn_boss(health_multiplier: float = 1.0) -> Enemy:
	var boss := ENEMY_SCENE.instantiate() as Enemy
	boss.data = CAMPANARIO
	boss.health_multiplier = health_multiplier
	boss.position = Vector2(0, -40)
	_game.get_node("Entities").add_child(boss)
	return boss


func _hit(boss: Enemy, damage: float) -> void:
	boss.hurtbox.receive_hit(HitInfo.create(damage, Vector2.UP, 0.0))


func test_boss_announces_itself_and_starts_in_phase_one() -> void:
	watch_signals(EventBus)
	var boss: Enemy = _spawn_boss()
	assert_true(boss.is_boss())
	assert_signal_emitted(EventBus, "boss_spawned")
	assert_eq(boss.phase, 0)
	assert_eq(boss.behavior, CAMPANARIO.phases[0].behavior)


func test_losing_health_changes_phase() -> void:
	var boss: Enemy = _spawn_boss()
	_hit(boss, 30.0)
	assert_eq(boss.phase, 0, "con 75 % sigue en la primera")
	_hit(boss, 30.0)
	assert_eq(boss.phase, 1, "con 50 % pasa a la segunda")
	assert_eq(boss.behavior, CAMPANARIO.phases[1].behavior)
	assert_eq(boss.machine.get_state_name(), &"Recover", "hace una pausa al cambiar")
	_hit(boss, 40.0)
	assert_eq(boss.phase, 2, "con 16 % pasa a la tercera")
	await wait_physics_frames(1)


func test_floor_multiplier_scales_boss_health() -> void:
	var boss: Enemy = _spawn_boss(1.5)
	assert_eq(boss.health.max_health, CAMPANARIO.max_health * 1.5)


func test_boss_death_clears_its_bullets_and_is_announced() -> void:
	var boss: Enemy = _spawn_boss()
	await wait_physics_frames(1)
	var hostile := Bullet.spawn(get_tree(), BULLET_SCENE, ShotSpec.from_pattern(BulletPatternData.new()),
			Vector2(-60, 40), Vector2.DOWN, PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL)
	watch_signals(EventBus)
	boss.health.kill()
	await wait_physics_frames(2)
	assert_signal_emitted(EventBus, "boss_defeated")
	assert_false(is_instance_valid(hostile), "sus balas desaparecen")
	assert_false(is_instance_valid(boss))
	await wait_physics_frames(25)
