extends GutTest
## Hito 6: meta-progresión con las pantallas reales. Elegir personaje (y que la run arranque con sus
## stats e item), chispas y logros al terminar la run, el Taller y que el guardado persista entre
## sesiones. El SaveManager global queda en memoria (pre_run_hook); la prueba de disco usa otra
## instancia del script con un archivo propio.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const SAVE_MANAGER_SCRIPT: GDScript = preload("res://autoload/save_manager.gd")
const CAMPANARIO: EnemyData = preload("res://content/enemies/campanario.tres")
const LUPA: ItemData = preload("res://content/items/lupa.tres")
const DISK_PATH: String = "user://test_meta_flow/save.json"

var _main: Main


## Main abre el guardado en memoria: cada test arranca con un perfil nuevo.
func before_each() -> void:
	_main = MAIN_SCENE.instantiate() as Main
	_main.save_path = ""
	add_child_autofree(_main)


func after_each() -> void:
	var store := SaveStore.new(DISK_PATH)
	store.delete()
	DirAccess.remove_absolute(DISK_PATH.get_base_dir())


func _settle() -> void:
	await wait_physics_frames(2)


func _character(id: StringName) -> CharacterData:
	return SaveManager.config.character_by_id(id)


func _screen_text() -> String:
	var lines: PackedStringArray = []
	for node: Node in _main.screen.find_children("*", "Label", true, false):
		lines.append((node as Label).text)
	return "\n".join(lines)


func test_play_goes_through_the_character_select() -> void:
	(_main.screen as MainMenu).play_requested.emit()
	assert_true(_main.screen is CharacterSelect)
	var select := _main.screen as CharacterSelect
	for character: CharacterData in SaveManager.config.characters:
		assert_eq(select.button_for(character).disabled, character.locked, "%s: bloqueado o no" % character.id)
	var first: CharacterData = SaveManager.config.default_character()
	select.button_for(first).pressed.emit()
	assert_true(_main.screen is Game, "arrancó la run")
	assert_eq(RunState.character, first)
	await _settle()


func test_unlocked_character_starts_with_its_stats_and_item() -> void:
	var musgo: CharacterData = _character(&"musgo")
	SaveManager.profile.unlocked_characters[musgo.id] = true
	_main.show_character_select()
	var select := _main.screen as CharacterSelect
	assert_false(select.button_for(musgo).disabled, "desbloqueado")
	select.button_for(musgo).pressed.emit()
	await wait_physics_frames(2)
	var player: Player = _main.game.player
	assert_eq(RunState.character, musgo)
	assert_eq(player.health.max_health, musgo.stats.max_health, "su vida")
	assert_eq(player.health.current, musgo.stats.max_health, "llena")
	assert_eq(RunState.stats.move_speed, musgo.stats.move_speed, "sus stats")
	assert_eq(RunState.active_item, musgo.start_item, "su item")
	assert_eq(player.visual.body_color, musgo.body_color, "su color")
	assert_eq(SaveManager.profile.last_character, musgo.id, "queda elegido")
	await _settle()
	_main.start_run()
	assert_eq(RunState.character, musgo, "Otra run repite el personaje")
	await _settle()


func test_weapon_start_item_is_equipped() -> void:
	var ceniza: CharacterData = _character(&"ceniza")
	SaveManager.profile.unlocked_characters[ceniza.id] = true
	_main.start_run(ceniza)
	await wait_physics_frames(2)
	assert_eq(RunState.current_weapon_slot().weapon, ceniza.start_item.weapon)
	assert_eq(_main.game.player.health.max_health, ceniza.stats.max_health)
	await _settle()


func test_locked_character_falls_back_to_the_default() -> void:
	SaveManager.profile.last_character = &"ceniza"
	assert_eq(SaveManager.selected_character(), SaveManager.config.default_character())


func test_finishing_a_run_pays_sparks_and_unlocks_achievements() -> void:
	_main.start_run()
	await wait_physics_frames(2)
	RunState.kills = 12
	RunState.bosses_defeated.append(CAMPANARIO.id)
	EventBus.run_ended.emit(true)
	await wait_physics_frames(1)
	assert_true(_main.screen is RunSummary)
	var profile: MetaProfile = SaveManager.profile
	assert_eq(profile.sparks, 2 + 10 + 10, "kills, jefe y victoria")
	assert_eq([profile.runs, profile.wins, profile.total_kills], [1, 1, 12])
	assert_true(profile.has_achievement(SaveManager.config.achievements[0]), "venció al Campanario")
	assert_true(profile.is_character_available(_character(&"musgo")), "y desbloqueó a Musgo")
	var text: String = _screen_text()
	assert_string_contains(text, "+22 chispas")
	assert_string_contains(text, "Logro: Silencio en el Sótano")
	await _settle()


func test_dying_also_counts() -> void:
	_main.start_run()
	_main.game.player.health.kill()
	await wait_physics_frames(roundi(Main.DEATH_DELAY * 60.0) + 30)
	assert_true(_main.screen is RunSummary)
	assert_eq(SaveManager.profile.runs, 1)
	assert_eq(SaveManager.profile.wins, 0)
	await _settle()


func test_abandoning_a_run_does_not_count() -> void:
	_main.start_run()
	await wait_physics_frames(2)
	_main.game.menu_requested.emit()
	assert_true(_main.screen is MainMenu)
	assert_eq(SaveManager.profile.runs, 0)
	await _settle()


func test_defeated_bosses_are_recorded() -> void:
	RunState.start_run()
	var boss := ENEMY_SCENE.instantiate() as Enemy
	boss.data = CAMPANARIO
	EventBus.boss_defeated.emit(boss)
	boss.free()
	assert_has(RunState.bosses_defeated, CAMPANARIO.id)
	assert_eq(RunState.make_record(false).bosses, RunState.bosses_defeated)


func test_workshop_purchase_adds_the_item_to_the_pools() -> void:
	_main.show_workshop()
	var workshop := _main.screen as WorkshopMenu
	assert_true(workshop.button_for(LUPA).disabled, "sin chispas no se compra")
	RunState.start_run(null, SaveManager.profile)
	var before: int = RunState.item_pool.remaining(ItemData.POOL_TREASURE)
	SaveManager.add_sparks(LUPA.unlock_cost + 3)
	assert_false(workshop.button_for(LUPA).disabled, "ahora sí")
	workshop.button_for(LUPA).pressed.emit()
	assert_true(SaveManager.profile.is_item_available(LUPA))
	assert_eq(SaveManager.profile.sparks, 3)
	assert_true(workshop.button_for(LUPA).disabled, "ya comprado")
	RunState.start_run(null, SaveManager.profile)
	assert_eq(RunState.item_pool.remaining(ItemData.POOL_TREASURE), before + 1, "sale en el tesoro")
	await _settle()


func test_achievements_menu_shows_progress() -> void:
	SaveManager.profile.achievements[SaveManager.config.achievements[0].id] = true
	_main.show_achievements()
	var text: String = _screen_text()
	assert_string_contains(text, "Logros 1/%d" % SaveManager.config.achievements.size())
	for node: Node in _main.screen.find_children("*", "Label", true, false):
		var label := node as Label
		if label.text == SaveManager.config.achievements[0].display_name:
			assert_eq(label.get_theme_color(&"font_color"), AchievementsMenu.DONE_COLOR, "marcado como hecho")
	await _settle()


func test_progress_persists_between_sessions() -> void:
	var first: Variant = SAVE_MANAGER_SCRIPT.new()
	add_child_autofree(first)
	first.open(DISK_PATH)
	assert_true(first.is_persistent())
	first.add_sparks(7)
	first.select_character(_character(&"brasa"))
	var second: Variant = SAVE_MANAGER_SCRIPT.new()
	add_child_autofree(second)
	second.open(DISK_PATH)
	assert_eq(second.profile.sparks, 7, "leyó lo guardado")
	assert_eq(second.profile.last_character, &"brasa")


func test_save_path_from_args() -> void:
	assert_eq(Main.save_path_from_args(PackedStringArray(["--save=user://otro.json"]), "x"), "user://otro.json")
	assert_eq(Main.save_path_from_args(PackedStringArray(["--demo-input"]), "x"), "", "la demo no guarda")
	assert_eq(Main.save_path_from_args(PackedStringArray(["--demo-input", "--save=user://d.json"]), "x"), "user://d.json")
	assert_eq(Main.save_path_from_args(PackedStringArray(), "x"), "x")
