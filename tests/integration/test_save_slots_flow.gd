extends GutTest
## Hito 15: las cuatro partidas con las pantallas reales, en una carpeta propia (nunca la del
## guardado real). Lo primero es la pantalla de partidas; cada partida guarda su progreso aparte,
## muestra su porcentaje, se puede borrar (con confirmación) y las opciones son las mismas para
## todas. Un guardado de antes de las partidas aparece como la partida 1.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const DIR: String = "user://test_save_slots_flow/"

var _main: Main


func before_each() -> void:
	_clear()


func after_each() -> void:
	SaveManager.use_slots("")
	_clear()


func _clear() -> void:
	if not DirAccess.dir_exists_absolute(DIR):
		return
	for file: String in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file))
	DirAccess.remove_absolute(DIR)


func _start() -> void:
	_main = MAIN_SCENE.instantiate() as Main
	_main.save_dir = DIR
	add_child_autofree(_main)


func _slots_menu() -> SaveSlotsMenu:
	return _main.screen as SaveSlotsMenu


func _choose(slot: int) -> void:
	_slots_menu().button_for(slot).pressed.emit()


func _screen_text() -> String:
	var lines: PackedStringArray = []
	for node: Node in _main.screen.find_children("*", "Label", true, false):
		lines.append((node as Label).text)
	return "\n".join(lines)


## Termina una run ganada en la partida abierta.
func _win_a_run() -> void:
	RunState.start_run(null, SaveManager.profile)
	SaveManager.record_run(RunState.make_record(true))


func test_the_game_starts_on_the_four_empty_slots() -> void:
	_start()
	assert_true(_main.screen is SaveSlotsMenu, "lo primero son las partidas")
	assert_eq(SaveManager.slot, 0, "ninguna abierta")
	var text: String = _screen_text()
	assert_eq(text.count("vacía"), SaveSlots.COUNT)
	for slot: int in range(1, SaveSlots.COUNT + 1):
		assert_true(_slots_menu().button_for(slot).visible)
	await wait_physics_frames(2)


func test_slots_keep_their_own_progress() -> void:
	_start()
	_choose(2)
	assert_true(_main.screen is MainMenu, "elegirla lleva al menú")
	assert_eq(SaveManager.slot, 2)
	assert_string_contains(_screen_text(), "Partida 2 · 0 %")
	SaveManager.add_sparks(30)
	_win_a_run()
	assert_true(FileAccess.file_exists(DIR.path_join("slot_2.json")), "se guardó en su archivo")
	assert_false(FileAccess.file_exists(DIR.path_join("slot_1.json")), "las otras no se tocan")
	var expected: int = MetaRules.percent(SaveManager.completion())
	assert_gt(expected, 0, "ganar suma progreso")
	assert_string_contains(_screen_text(), "Partida 2 · %d %%" % expected, "el menú muestra el progreso")
	(_main.screen as MainMenu).change_slot_requested.emit()
	await wait_physics_frames(2)
	assert_true(_main.screen is SaveSlotsMenu, "Cambiar partida vuelve a las partidas")
	assert_string_contains(_screen_text(), "%d %% · 1 run · 1 victoria" % expected)
	assert_eq(_screen_text().count("vacía"), SaveSlots.COUNT - 1)
	_choose(1)
	assert_eq(SaveManager.profile.sparks, 0, "la partida 1 empieza de cero")
	assert_eq(SaveManager.profile.wins, 0)
	_main.show_slots()
	_choose(2)
	assert_gte(SaveManager.profile.sparks, 30, "y la 2 conserva lo suyo")
	await wait_physics_frames(2)


func test_deleting_a_slot_asks_first() -> void:
	_start()
	_choose(3)
	SaveManager.add_sparks(5)
	_main.show_slots()
	var menu: SaveSlotsMenu = _slots_menu()
	menu.ask_delete(3)
	assert_string_contains(_screen_text(), "¿Borrarla?")
	menu.cancel_delete()
	assert_true(FileAccess.file_exists(DIR.path_join("slot_3.json")), "con No sigue ahí")
	menu.ask_delete(3)
	menu.confirm_delete()
	assert_false(FileAccess.file_exists(DIR.path_join("slot_3.json")), "con Sí se borra")
	assert_eq(_screen_text().count("vacía"), SaveSlots.COUNT)
	_choose(3)
	assert_eq(SaveManager.profile.sparks, 0, "vuelve a empezar")
	await wait_physics_frames(2)


func test_options_are_shared_and_the_last_slot_is_remembered() -> void:
	_start()
	_choose(4)
	SaveManager.set_volume(0.4)
	_main.show_slots()
	_choose(1)
	assert_almost_eq(SaveManager.options.volume, 0.4, 0.0001, "mismas opciones en otra partida")
	# Otra sesión: lee las opciones y arranca en la última partida abierta.
	SaveManager.use_slots(DIR)
	assert_almost_eq(SaveManager.options.volume, 0.4, 0.0001, "quedaron guardadas")
	assert_eq(SaveManager.last_slot(), 1)
	SaveManager.set_volume(1.0)
	await wait_physics_frames(2)


func test_an_old_save_shows_up_as_slot_one() -> void:
	var old := MetaProfile.new()
	old.sparks = 12
	old.runs = 3
	var data: Dictionary = old.to_dict()
	data["options"] = {"volume": 0.7}
	assert_eq(SaveStore.new(DIR.path_join(SaveSlots.LEGACY_FILE)).write(data), OK)
	_start()
	assert_string_contains(_screen_text(), "0 % · 3 runs · 0 victorias", "la partida 1 tiene el progreso de antes")
	assert_almost_eq(SaveManager.options.volume, 0.7, 0.0001, "y las opciones de antes")
	_choose(1)
	assert_eq(SaveManager.profile.sparks, 12)
	SaveManager.set_volume(1.0)
	await wait_physics_frames(2)
