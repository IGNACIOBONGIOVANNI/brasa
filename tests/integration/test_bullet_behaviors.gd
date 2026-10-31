extends GutTest
## Hito 4: rebote, perforación y teledirigido en las balas del jugador (en la arena de pruebas).

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")
const FAROL: EnemyData = preload("res://content/enemies/farol.tres")

var _game: Game


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	# El jugador queda lejos y no molesta.
	_game.player.global_position = Vector2(0, 60)


func _shoot(stats: StatBlock, at: Vector2, direction: Vector2) -> Bullet:
	return Bullet.spawn(get_tree(), BULLET_SCENE, ShotSpec.build(stats, RunState.BASE_WEAPON), at, direction,
			PhysicsLayers.PLAYER_BULLET, PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX)


## Enemigo quieto (sigue "apareciendo") con mucha vida.
func _dummy(at: Vector2) -> Enemy:
	var data := FAROL.duplicate() as EnemyData
	data.spawn_delay = 30.0
	data.max_health = 100.0
	return _game.spawn_enemy(data, at)


func test_bouncing_bullet_comes_back_from_the_wall() -> void:
	var stats := StatBlock.new()
	stats.bounces = 1.0
	var bullet: Bullet = _shoot(stats, Vector2(80, -56), Vector2.RIGHT)
	await wait_physics_frames(20)
	assert_true(is_instance_valid(bullet), "sigue viva después de tocar la pared")
	var x_before: float = bullet.global_position.x
	await wait_physics_frames(5)
	assert_lt(bullet.global_position.x, x_before, "ahora va para la izquierda")


func test_bullet_without_bounces_dies_at_the_wall() -> void:
	var bullet: Bullet = _shoot(StatBlock.new(), Vector2(80, -56), Vector2.RIGHT)
	await wait_physics_frames(20)
	assert_false(is_instance_valid(bullet))


func test_piercing_bullet_hits_two_enemies_in_line() -> void:
	var first: Enemy = _dummy(Vector2(-40, -56))
	var second: Enemy = _dummy(Vector2(10, -56))
	var stats := StatBlock.new()
	stats.pierce = 1.0
	_shoot(stats, Vector2(-90, -58), Vector2.RIGHT)
	await wait_physics_frames(40)
	assert_lt(first.health.current, 100.0, "golpeó al primero")
	assert_lt(second.health.current, 100.0, "y atravesó hasta el segundo")


func test_normal_bullet_stops_at_the_first_enemy() -> void:
	var first: Enemy = _dummy(Vector2(-40, -56))
	var second: Enemy = _dummy(Vector2(10, -56))
	_shoot(StatBlock.new(), Vector2(-90, -58), Vector2.RIGHT)
	await wait_physics_frames(40)
	assert_lt(first.health.current, 100.0)
	assert_eq(second.health.current, 100.0, "el segundo no recibió nada")


func test_homing_bullet_curves_into_an_enemy_off_its_line() -> void:
	var target: Enemy = _dummy(Vector2(40, -20))
	_shoot(StatBlock.new(), Vector2(-60, -58), Vector2.RIGHT)
	await wait_physics_frames(50)
	assert_eq(target.health.current, 100.0, "sin teledirigido pasa de largo")
	var stats := StatBlock.new()
	stats.homing = 1.0
	_shoot(stats, Vector2(-60, -58), Vector2.RIGHT)
	await wait_physics_frames(50)
	assert_lt(target.health.current, 100.0, "con teledirigido dobla y le pega")
