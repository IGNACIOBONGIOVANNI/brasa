extends GutTest
## Hito 1: en la sala de prueba el jugador se mueve, dispara y las balas desaparecen solas.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const USED_ACTIONS: Array[StringName] = [&"move_right", &"move_left", &"move_up", &"shoot", &"aim_right"]

var _game: Node2D
var _player: Player
var _weapon: WeaponComponent


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Node2D
	add_child_autofree(_game)
	_player = _game.get_node("Entities/Player") as Player
	_weapon = _player.weapon


func after_each() -> void:
	for action: StringName in USED_ACTIONS:
		Input.action_release(action)


func _live_bullets() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		if not node.is_queued_for_deletion():
			count += 1
	return count


func test_player_moves_with_move_action() -> void:
	var start_x: float = _player.global_position.x
	Input.action_press(&"move_right")
	await wait_physics_frames(20)
	assert_gt(_player.global_position.x, start_x + 10.0, "se movió a la derecha")


func test_walls_stop_the_player() -> void:
	# Desde (0, 32) hacia arriba pasa por el hueco entre las rocas del centro hasta la pared.
	Input.action_press(&"move_up")
	await wait_physics_frames(240)
	# Cara interna de la pared superior en y = -72; el cuerpo (radio 4) está 2 px debajo del origen.
	assert_almost_eq(_player.global_position.y, -70.0, 1.0, "frenó contra la pared")


func test_rocks_stop_the_player() -> void:
	# Hacia la izquierda está la roca en (-80, 32): su cara derecha está en x = -72.
	Input.action_press(&"move_left")
	await wait_physics_frames(240)
	assert_almost_eq(_player.global_position.x, -68.0, 1.0, "frenó contra la roca")


func test_shot_spawns_bullet_that_then_disappears() -> void:
	Input.action_press(&"aim_right")
	Input.action_press(&"shoot")
	await wait_physics_frames(2)
	Input.action_release(&"shoot")
	assert_eq(_live_bullets(), 1, "salió una sola bala")
	var bullet: Bullet = get_tree().get_first_node_in_group(Bullet.GROUP) as Bullet
	assert_gt(bullet.global_position.x, _player.global_position.x, "la bala sale hacia donde apunta")
	await wait_physics_frames(90)
	assert_eq(_live_bullets(), 0, "la bala murió por alcance o al chocar")


func test_fire_rate_follows_stats() -> void:
	watch_signals(_weapon)
	Input.action_press(&"aim_right")
	Input.action_press(&"shoot")
	await wait_physics_frames(60)
	# 3 disparos por segundo con los stats base: en 60 ticks salen 3 (o 4 si el último cae justo).
	var shots: int = get_signal_emit_count(_weapon, "fired")
	assert_between(shots, 3, 4, "cadencia según fire_rate")
