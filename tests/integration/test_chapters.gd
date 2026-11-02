extends GutTest
## Hito 21: el capítulo 2 con las pantallas reales. Se desbloquea con Testa (al prender la Fragua),
## se elige en "Elegí capítulo", cuenta su historia la primera vez, muestra solo sus personajes y la
## run recorre sus pisos (también al seguir una run guardada).

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const CHAPTER_2: RunConfig = preload("res://content/run/chapter_2.tres")

var _main: Main


func before_each() -> void:
	_main = MAIN_SCENE.instantiate() as Main
	_main.save_dir = ""
	add_child_autofree(_main)


func _testa() -> CharacterData:
	return SaveManager.config.character_by_id(&"testa")


func _unlock_testa() -> void:
	SaveManager.profile.unlocked_characters[&"testa"] = true
	SaveManager.profile.intro_seen = true


func test_chapter_two_is_locked_until_the_forge_is_lit() -> void:
	SaveManager.profile.intro_seen = true
	assert_eq(SaveManager.available_chapters().size(), 1, "de entrada, solo el primero")
	(_main.screen as MainMenu).play_requested.emit()
	assert_true(_main.screen is CharacterSelect, "con un capítulo no hay que elegir")
	assert_null((_main.screen as CharacterSelect).button_for(_testa()), "Testa no está entre los del primero")
	SaveManager.profile.achievements[&"fragua_apagada"] = true
	assert_true(SaveManager.profile.sync_unlocks(SaveManager.config.achievements), "el logro desbloquea a Testa")
	assert_eq(SaveManager.available_chapters().size(), 2, "prender la Fragua abre el monte")
	await wait_physics_frames(2)


func test_old_saves_with_the_forge_lit_get_testa() -> void:
	var profile: MetaProfile = MetaProfile.from_dict({"achievements": ["fragua_apagada"]})
	assert_false(profile.is_character_available(_testa()), "el guardado viejo no lo tenía")
	assert_true(profile.sync_unlocks(SaveManager.config.achievements))
	assert_true(profile.is_character_available(_testa()))
	assert_false(profile.sync_unlocks(SaveManager.config.achievements), "la segunda vez no cambia nada")


func test_play_goes_through_the_chapter_select_and_its_story() -> void:
	_unlock_testa()
	(_main.screen as MainMenu).play_requested.emit()
	assert_true(_main.screen is ChapterSelect, "con dos capítulos, a elegir")
	var chapters := _main.screen as ChapterSelect
	assert_false(chapters.button_for(1).disabled)
	assert_false(chapters.button_for(2).disabled)
	chapters.button_for(2).pressed.emit()
	assert_true(_main.screen is IntroScreen, "la primera vez cuenta la historia del capítulo")
	assert_eq((_main.screen as IntroScreen).lines, CHAPTER_2.intro)
	(_main.screen as IntroScreen).skip()
	assert_true(_main.screen is CharacterSelect)
	var select := _main.screen as CharacterSelect
	assert_null(select.button_for(SaveManager.config.default_character()), "Brasa es del primero")
	assert_not_null(select.button_for(_testa()), "Testa es del monte")
	select.button_for(_testa()).pressed.emit()
	assert_true(_main.screen is Game, "arrancó la run")
	assert_eq(RunState.chapter.id, &"monte")
	assert_eq(_main.game.floor_controller.run, CHAPTER_2, "los pisos del monte")
	assert_eq(_main.game.floor_controller.theme.display_name, "Esquiladero")
	assert_true(SaveManager.has_seen_intro(CHAPTER_2), "la historia queda vista")
	await wait_physics_frames(2)


func test_the_chapter_story_is_told_once() -> void:
	_unlock_testa()
	SaveManager.profile.seen_intros[&"monte"] = true
	_main.show_chapter_select()
	(_main.screen as ChapterSelect).button_for(2).pressed.emit()
	assert_true(_main.screen is CharacterSelect, "ya la vio: directo a los personajes")
	await wait_physics_frames(2)


func test_chapter_one_plays_as_before() -> void:
	_unlock_testa()
	_main.show_chapter_select()
	(_main.screen as ChapterSelect).button_for(1).pressed.emit()
	var select := _main.screen as CharacterSelect
	assert_null(select.button_for(_testa()))
	select.button_for(SaveManager.config.default_character()).pressed.emit()
	assert_eq(RunState.chapter.id, &"fragua")
	assert_eq(_main.game.floor_controller.theme.display_name, "Sótano")
	await wait_physics_frames(2)


func test_back_from_the_characters_goes_to_the_chapters() -> void:
	_unlock_testa()
	_main.show_character_select(CHAPTER_2)
	(_main.screen as CharacterSelect).back_requested.emit()
	assert_true(_main.screen is ChapterSelect)
	(_main.screen as ChapterSelect).back_requested.emit()
	assert_true(_main.screen is MainMenu)
	await wait_physics_frames(2)


func test_summary_tells_the_story_of_the_chapter() -> void:
	RunState.start_run(_testa())
	assert_eq(RunSummary.story_text(true), CHAPTER_2.victory_text)
	assert_eq(RunSummary.story_text(false), CHAPTER_2.defeat_text)
	RunState.start_run()
	assert_eq(RunSummary.story_text(true), RunSummary.VICTORY_TEXT, "el primero, como siempre")


func test_a_saved_run_continues_in_its_chapter() -> void:
	_unlock_testa()
	_main.start_run(_testa())
	await wait_physics_frames(3)
	assert_true(_main.game.save_run())
	_main.show_menu()
	RunState.start_run()
	_main.continue_run()
	assert_true(_main.screen is Game)
	assert_eq(RunState.character, _testa())
	assert_eq(RunState.chapter.id, &"monte")
	assert_eq(_main.game.floor_controller.theme.display_name, "Esquiladero")
	await wait_physics_frames(2)


func test_chapter_argument_for_automated_runs() -> void:
	assert_eq(Main.chapter_from_args(PackedStringArray(["--chapter=2"])), CHAPTER_2)
	assert_null(Main.chapter_from_args(PackedStringArray(["--chapter=9"])))
	assert_null(Main.chapter_from_args(PackedStringArray(["--seed=3"])))
