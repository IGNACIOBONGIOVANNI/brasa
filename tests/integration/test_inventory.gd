extends GutTest
## Hito 8: la Mochila (I) pausa el juego y muestra las armas, el activo y los items; también se abre
## desde la pausa y no se abre encima de otra cosa que pausó el juego.

const GAME_SCENE: PackedScene = preload("res://main/game.tscn")

var _game: Game
var _inventory: InventoryMenu


func before_each() -> void:
	GameRNG.start_run(1234)
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_inventory = _game.get_node("Inventory") as InventoryMenu
	await wait_physics_frames(1)


func after_each() -> void:
	get_tree().paused = false


func _item(id: String) -> ItemData:
	return load("res://content/items/%s.tres" % id) as ItemData


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	get_tree().root.push_input(event)


func test_the_key_opens_and_closes_it() -> void:
	_press(&"inventory")
	assert_true(_inventory.is_open(), "se abre")
	assert_true(get_tree().paused, "y pausa")
	_press(&"inventory")
	assert_false(_inventory.is_open(), "la misma tecla la cierra")
	assert_false(get_tree().paused)
	_press(&"inventory")
	_press(&"ui_cancel")
	assert_false(_inventory.is_open(), "Esc también")
	await wait_physics_frames(1)


func test_shows_weapons_active_and_items() -> void:
	for id: String in ["arma_haz", "botiquin", "polvora_negra", "lupa"]:
		RunState.add_item(_item(id))
	_inventory.open()
	assert_eq(_inventory.slot_count(), 5, "2 armas + 1 activo + 2 pasivos")
	await wait_process_frames(2)
	assert_eq(_inventory.detail_title(), "Haz", "arranca mostrando el arma en la mano")
	assert_string_contains(_inventory.detail_kind(), "calidad S", "con su calidad")
	_inventory.close()
	await wait_physics_frames(1)


func test_does_not_open_over_the_pause() -> void:
	var pause := _game.get_node("PauseMenu") as PauseMenu
	pause.open()
	_press(&"inventory")
	assert_false(_inventory.is_open())
	pause.close()
	await wait_physics_frames(1)


func test_the_pause_menu_opens_it() -> void:
	var pause := _game.get_node("PauseMenu") as PauseMenu
	pause.open()
	pause.inventory_requested.emit()
	assert_false(pause.is_open(), "se cierra la pausa")
	assert_true(_inventory.is_open(), "y se abre la Mochila")
	assert_true(get_tree().paused, "el juego sigue en pausa")
	_inventory.close()
	await wait_physics_frames(1)
