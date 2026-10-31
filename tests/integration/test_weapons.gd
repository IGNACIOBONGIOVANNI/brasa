extends GutTest
## Hito 4: armas data-driven en la arena de pruebas. Escopeta, ráfaga, recarga, cambio de arma,
## láser (corta en las paredes), orbital (lastima y borra balas) y munición al limpiar salas.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")
const FAROL: EnemyData = preload("res://content/enemies/farol.tres")
const USED_ACTIONS: Array[StringName] = [&"shoot", &"aim_right", &"aim_left", &"swap_weapon", &"reload"]

var _game: Game
var _player: Player


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.health.always_invulnerable = true


func after_each() -> void:
	for action: StringName in USED_ACTIONS:
		Input.action_release(action)


func _weapon(id: String) -> WeaponData:
	return load("res://content/weapons/%s.tres" % id) as WeaponData


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_physics_frames(1)
	Input.action_release(action)


func _player_bullets() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		var bullet := node as Bullet
		if not bullet.is_hostile_to_player() and not bullet.is_queued_for_deletion():
			count += 1
	return count


func _dummy(at: Vector2) -> Enemy:
	var data := FAROL.duplicate() as EnemyData
	data.spawn_delay = 30.0
	data.max_health = 100.0
	return _game.spawn_enemy(data, at)


func test_shotgun_fires_a_spread_and_uses_one_shell() -> void:
	RunState.add_weapon(_weapon("trabuco"))
	await wait_physics_frames(1)
	Input.action_press(&"aim_right")
	await _tap(&"shoot")
	await wait_physics_frames(1)
	assert_eq(_player_bullets(), 5, "5 perdigones")
	assert_eq(RunState.current_weapon_slot().in_magazine, 3, "gastó un cartucho")


func test_burst_fires_three_bullets_over_time() -> void:
	RunState.add_weapon(_weapon("metralla"))
	await wait_physics_frames(1)
	Input.action_press(&"aim_right")
	await _tap(&"shoot")
	assert_eq(_player_bullets(), 1, "la primera sale enseguida")
	await wait_physics_frames(12)
	assert_eq(_player_bullets(), 3, "y las otras dos atrás")
	assert_eq(RunState.current_weapon_slot().in_magazine, 15)


func test_empty_magazine_reloads_automatically() -> void:
	RunState.add_weapon(_weapon("trabuco"))
	await wait_physics_frames(1)
	var slot: WeaponSlot = RunState.current_weapon_slot()
	Input.action_press(&"aim_right")
	Input.action_press(&"shoot")
	for _i: int in 240:
		await wait_physics_frames(1)
		if slot.in_magazine == 0:
			break
	assert_eq(slot.in_magazine, 0, "vació el cargador")
	await wait_physics_frames(roundi(_weapon("trabuco").reload_time * 60.0) + 5)
	assert_gt(slot.in_magazine, 0, "recargó solo")
	assert_lt(slot.reserve, _weapon("trabuco").ammo, "sacó de la reserva")


func test_swap_cycles_weapons() -> void:
	RunState.add_weapon(_weapon("trabuco"))
	await wait_physics_frames(1)
	assert_eq(_player.weapon.weapon(), _weapon("trabuco"), "equipa la nueva")
	await _tap(&"swap_weapon")
	await wait_physics_frames(1)
	assert_eq(_player.weapon.weapon(), RunState.BASE_WEAPON, "vuelve a la pistola")


func test_laser_damages_in_line_and_stops_at_rocks() -> void:
	RunState.add_weapon(_weapon("haz"))
	_player.global_position = Vector2(0, 32)
	var in_line: Enemy = _dummy(Vector2(50, 30))
	# Detrás de la roca de (-80, 32).
	var behind_rock: Enemy = _dummy(Vector2(-104, 30))
	await wait_physics_frames(1)
	Input.action_press(&"aim_right")
	Input.action_press(&"shoot")
	await wait_physics_frames(30)
	Input.action_release(&"aim_right")
	assert_lt(in_line.health.current, 100.0, "el rayo lastima")
	assert_lt(RunState.current_weapon_slot().in_magazine, _weapon("haz").magazine, "gasta energía")
	Input.action_press(&"aim_left")
	await wait_physics_frames(30)
	assert_eq(behind_rock.health.current, 100.0, "la roca corta el rayo")


func test_orbital_hurts_enemies_and_clears_bullets() -> void:
	RunState.add_weapon(_weapon("orbita"))
	_player.global_position = Vector2(0, 20)
	var close: Enemy = _dummy(_player.global_position + Vector2(24, -1))
	await wait_physics_frames(1)
	var hostile := Bullet.spawn(get_tree(), BULLET_SCENE, ShotSpec.from_pattern(BulletPatternData.new()),
			_player.global_position + Vector2(0, -23), Vector2.UP, PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL)
	hostile.spec.speed = 0.0
	Input.action_press(&"shoot")
	await wait_physics_frames(60)
	assert_lt(close.health.current, 100.0, "los orbes lastiman")
	assert_false(is_instance_valid(hostile), "y borran balas enemigas")


func test_clearing_a_room_gives_back_ammo() -> void:
	RunState.add_weapon(_weapon("orbita"))
	var slot: WeaponSlot = RunState.current_weapon_slot()
	for _i: int in 30:
		slot.consume()
	var before: int = slot.reserve
	EventBus.room_cleared.emit(Vector2i.ZERO)
	assert_gt(slot.reserve, before)
