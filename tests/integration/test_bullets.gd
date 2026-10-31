extends GutTest
## Balas: chocan paredes y rocas, golpean hurtboxes y atraviesan a quien es invulnerable.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const PLAYER_BULLET_MASK: int = PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX
const ENEMY_BULLET_MASK: int = PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX

var _game: Game
var _player: Player


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player


func _enemy_bullet(at: Vector2, direction: Vector2) -> Bullet:
	return Bullet.spawn(get_tree(), BULLET_SCENE, ShotSpec.from_pattern(BulletPatternData.new()), at,
			direction, PhysicsLayers.ENEMY_BULLET, ENEMY_BULLET_MASK)


func _player_bullet(at: Vector2, direction: Vector2) -> Bullet:
	var weapon: WeaponData = load("res://content/weapons/base_shot.tres")
	return Bullet.spawn(get_tree(), BULLET_SCENE, ShotSpec.build(RunState.stats, weapon), at, direction,
			PhysicsLayers.PLAYER_BULLET, PLAYER_BULLET_MASK)


func test_enemy_bullet_dies_at_wall() -> void:
	# La pared derecha empieza en x = 120; a 90 px/s llega en ~0.45 s.
	var bullet := _enemy_bullet(Vector2(80, -56), Vector2.RIGHT)
	await wait_physics_frames(45)
	assert_false(is_instance_valid(bullet), "la bala enemiga murió contra la pared")


func test_player_bullet_dies_at_wall() -> void:
	var bullet := _player_bullet(Vector2(80, -56), Vector2.RIGHT)
	await wait_physics_frames(20)
	assert_false(is_instance_valid(bullet), "la bala del jugador murió contra la pared")


func test_enemy_bullet_dies_at_rock() -> void:
	# Roca en (80, -32): su cara izquierda está en x = 72.
	var bullet := _enemy_bullet(Vector2(40, -32), Vector2.RIGHT)
	await wait_physics_frames(30)
	assert_false(is_instance_valid(bullet), "la bala enemiga murió contra la roca")


func test_enemy_bullet_hurts_player_and_disappears() -> void:
	var bullet := _enemy_bullet(_player.global_position + Vector2(-40, -2), Vector2.RIGHT)
	await wait_physics_frames(40)
	assert_eq(_player.health.current, _player.health.max_health - 1.0, "perdió medio corazón")
	assert_false(is_instance_valid(bullet), "la bala se consumió al pegar")


func test_enemy_bullet_passes_through_invulnerable_player() -> void:
	_player.health.grant_invulnerability(5.0)
	var bullet := _enemy_bullet(_player.global_position + Vector2(-40, -2), Vector2.RIGHT)
	await wait_physics_frames(40)
	assert_eq(_player.health.current, _player.health.max_health, "no perdió vida")
	assert_true(is_instance_valid(bullet), "la bala siguió de largo")
	assert_gt(bullet.global_position.x, _player.global_position.x, "ya pasó al jugador")


func test_player_bullet_damages_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = load("res://content/enemies/farol.tres")
	enemy.position = Vector2(-60, -56)
	_game.get_node("Entities").add_child(enemy)
	_player_bullet(Vector2(-100, -58), Vector2.RIGHT)
	await wait_physics_frames(20)
	assert_eq(enemy.health.current, enemy.data.max_health - RunState.stats.damage, "le sacó el daño del jugador")
