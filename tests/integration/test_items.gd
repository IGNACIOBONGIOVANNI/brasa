extends GutTest
## Hito 4: items en la arena de pruebas. Pedestales (gratis y con precio), stats, activos (uso,
## carga, intercambio) e items con hook.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const USED_ACTIONS: Array[StringName] = [&"use_active", &"move_left"]

var _game: Game
var _player: Player


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player


func after_each() -> void:
	for action: StringName in USED_ACTIONS:
		Input.action_release(action)


func _item(id: String) -> ItemData:
	return load("res://content/items/%s.tres" % id) as ItemData


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_physics_frames(1)
	Input.action_release(action)


## Pedestal justo debajo del jugador.
func _pedestal_under_player(item: ItemData, price: int = 0) -> ItemPedestal:
	var pedestal: ItemPedestal = _game.spawn_item_pedestal(item)
	pedestal.set_item(item, price)
	pedestal.global_position = _player.global_position
	return pedestal


func _player_bullets() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		var bullet := node as Bullet
		if not bullet.is_hostile_to_player() and not bullet.is_queued_for_deletion():
			count += 1
	return count


func test_pedestal_gives_a_passive_that_changes_stats() -> void:
	watch_signals(EventBus)
	var pedestal: ItemPedestal = _pedestal_under_player(_item("polvora_negra"))
	await wait_physics_frames(3)
	assert_almost_eq(RunState.stats.damage, 3.0, 0.0001, "2 de base + 1")
	assert_has(RunState.items, _item("polvora_negra"))
	assert_null(pedestal.item, "el pedestal quedó vacío")
	assert_signal_emitted(EventBus, "item_picked")
	await wait_physics_frames(1)


func test_shop_pedestal_needs_enough_coins() -> void:
	var pedestal: ItemPedestal = _pedestal_under_player(_item("aguja"), 5)
	await wait_physics_frames(3)
	assert_not_null(pedestal.item, "sin plata no se lleva nada")
	RunState.add_coins(5)
	await wait_physics_frames(3)
	assert_not_null(pedestal.item, "hay que salir y volver a entrar")
	pedestal.global_position = _player.global_position + Vector2(60, 0)
	await wait_physics_frames(2)
	pedestal.global_position = _player.global_position
	await wait_physics_frames(3)
	assert_null(pedestal.item, "lo compró")
	assert_eq(RunState.coins, 0, "pagó 5")
	assert_eq(RunState.stats.pierce, 2.0)
	await wait_physics_frames(1)


func test_new_active_leaves_the_old_one_on_the_pedestal() -> void:
	RunState.add_item(_item("estallido"))
	var pedestal: ItemPedestal = _pedestal_under_player(_item("caparazon"))
	await wait_physics_frames(5)
	assert_eq(RunState.active_item, _item("caparazon"))
	assert_eq(pedestal.item, _item("estallido"), "el viejo quedó en el pedestal")
	assert_eq(pedestal.price, 0, "y gratis")
	assert_eq(RunState.active_item, _item("caparazon"), "no se lo vuelve a llevar sin salir")
	await wait_physics_frames(1)


func test_extra_heart_arrives_full() -> void:
	RunState.add_item(_item("corazon_de_repuesto"))
	await wait_physics_frames(1)
	assert_eq(_player.health.max_health, 8.0)
	assert_eq(_player.health.current, 8.0)


func test_burst_active_fires_a_ring_and_recharges_with_rooms() -> void:
	RunState.add_item(_item("estallido"))
	assert_true(RunState.is_active_ready(), "llega cargado")
	await _tap(&"use_active")
	await wait_physics_frames(1)
	assert_gte(_player_bullets(), 14, "anillo de balas")
	assert_false(RunState.is_active_ready(), "gastó la carga")
	EventBus.room_cleared.emit(Vector2i.ZERO)
	assert_false(RunState.is_active_ready(), "una sala no alcanza")
	EventBus.room_cleared.emit(Vector2i.ZERO)
	assert_true(RunState.is_active_ready(), "con dos salas vuelve a estar listo")
	await wait_physics_frames(1)


func test_shell_active_makes_the_player_invulnerable() -> void:
	RunState.add_item(_item("caparazon"))
	await _tap(&"use_active")
	await wait_physics_frames(1)
	assert_true(_player.health.is_invulnerable())
	assert_false(_player.hurtbox.receive_hit(HitInfo.create(1.0, Vector2.RIGHT, 0.0)), "no recibe daño")


func test_active_without_charge_does_nothing() -> void:
	RunState.add_item(_item("estallido"))
	RunState.spend_active()
	await _tap(&"use_active")
	await wait_physics_frames(1)
	assert_eq(_player_bullets(), 0)


func test_milk_tooth_heals_every_six_kills() -> void:
	RunState.add_item(_item("diente_de_leche"))
	await wait_physics_frames(1)
	_player.health.take_damage(2.0)
	var dummy := Node2D.new()
	add_child_autofree(dummy)
	for _i: int in 5:
		EventBus.enemy_killed.emit(dummy)
	await wait_physics_frames(2)
	assert_eq(_player.health.current, 4.0, "con 5 muertes todavía no")
	EventBus.enemy_killed.emit(dummy)
	await wait_physics_frames(2)
	assert_eq(_player.health.current, 5.0, "a la sexta cura medio corazón")


func test_spite_fires_a_ring_when_hurt() -> void:
	RunState.add_item(_item("rencor"))
	await wait_physics_frames(1)
	_player.hurtbox.receive_hit(HitInfo.create(1.0, Vector2.RIGHT, 0.0))
	await wait_physics_frames(2)
	assert_gte(_player_bullets(), 8)
	await wait_physics_frames(1)


## Hito 7.
func test_lightning_hits_every_enemy() -> void:
	var carnero := load("res://content/enemies/carnero.tres") as EnemyData
	var enemies: Array[Enemy] = [
		_game.spawn_enemy(carnero, Vector2(-70, -30)),
		_game.spawn_enemy(carnero, Vector2(70, -30)),
	]
	await wait_physics_frames(roundi(carnero.spawn_delay * 60.0) + 5)
	RunState.add_item(_item("relampago"))
	await _tap(&"use_active")
	await wait_physics_frames(1)
	for enemy: Enemy in enemies:
		assert_almost_eq(enemy.health.current, carnero.max_health - 8.0, 0.001, "le pegó el rayo")
	assert_false(RunState.is_active_ready(), "gastó la carga")
	await wait_physics_frames(2)


func test_lightning_without_enemies_keeps_its_charge() -> void:
	RunState.add_item(_item("relampago"))
	await _tap(&"use_active")
	await wait_physics_frames(1)
	assert_true(RunState.is_active_ready())


func test_medkit_heals_a_heart_and_is_not_wasted_at_full_health() -> void:
	RunState.add_item(_item("botiquin"))
	await _tap(&"use_active")
	await wait_physics_frames(1)
	assert_true(RunState.is_active_ready(), "con la vida llena no se gasta")
	_player.health.take_damage(3.0)
	await _tap(&"use_active")
	await wait_physics_frames(1)
	assert_eq(_player.health.current, 5.0, "curó un corazón")
	assert_false(RunState.is_active_ready())


func test_echo_fires_backwards_every_fourth_shot() -> void:
	var hook := _item("eco").hook_script.new() as ItemHook
	var context := HookContext.new()
	context.player = _player
	context.position = _player.global_position
	context.direction = Vector2.RIGHT
	for _i: int in 3:
		hook.on_shoot(context)
	assert_eq(_player_bullets(), 0, "los primeros 3 no")
	hook.on_shoot(context)
	assert_eq(_player_bullets(), 1, "el cuarto sí")
	await wait_physics_frames(1)


func test_shards_burst_out_of_killed_enemies() -> void:
	RunState.add_item(_item("esquirlas"))
	await wait_physics_frames(1)
	var dummy := Node2D.new()
	add_child_autofree(dummy)
	dummy.global_position = Vector2(0, -48)
	EventBus.enemy_killed.emit(dummy)
	await wait_physics_frames(1)
	assert_gte(_player_bullets(), 6)
	await wait_physics_frames(1)
