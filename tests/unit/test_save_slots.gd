extends GutTest
## SaveSlots en una carpeta propia: cada partida es su archivo, borrar una no toca las otras y el
## guardado de antes de las partidas (save.json) pasa a la partida 1 con sus opciones aparte, sin
## perderse (queda una copia).

const DIR: String = "user://test_save_slots/"

var _slots: SaveSlots


func before_each() -> void:
	_clear()
	_slots = SaveSlots.new(DIR)


func after_each() -> void:
	_clear()


func _clear() -> void:
	if not DirAccess.dir_exists_absolute(DIR):
		return
	for file: String in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file))
	DirAccess.remove_absolute(DIR)


func _write(path: String, data: Dictionary) -> void:
	assert_eq(SaveStore.new(path).write(data), OK)


func _profile_with(sparks: int) -> Dictionary:
	var profile := MetaProfile.new()
	profile.sparks = sparks
	return profile.to_dict()


func test_each_slot_is_its_own_file() -> void:
	for slot: int in range(1, SaveSlots.COUNT + 1):
		assert_false(_slots.is_used(slot), "partida %d vacía" % slot)
	_write(_slots.slot_path(2), _profile_with(5))
	_write(_slots.slot_path(4), _profile_with(9))
	assert_true(_slots.is_used(2))
	assert_false(_slots.is_used(3))
	assert_eq(MetaProfile.from_dict(_slots.read(2)).sparks, 5)
	assert_eq(MetaProfile.from_dict(_slots.read(4)).sparks, 9)
	_slots.delete(2)
	assert_false(_slots.is_used(2), "borrada")
	assert_eq(MetaProfile.from_dict(_slots.read(4)).sparks, 9, "las otras siguen igual")
	assert_ne(_slots.slot_path(1), _slots.slot_path(2))
	assert_ne(_slots.options_path(), _slots.slot_path(1))


func test_old_save_becomes_slot_one_and_its_options_move_out() -> void:
	var old: Dictionary = _profile_with(42)
	old["options"] = {"volume": 0.3, "window_scale": 3}
	_write(_slots.legacy_path(), old)
	assert_true(_slots.migrate_legacy())
	var slot_one: Dictionary = _slots.read(1)
	assert_eq(MetaProfile.from_dict(slot_one).sparks, 42, "el progreso pasó a la partida 1")
	assert_false(slot_one.has("options"), "sin las opciones")
	var options: GameOptions = GameOptions.from_dict(SaveStore.new(_slots.options_path()).read())
	assert_almost_eq(options.volume, 0.3, 0.0001, "las opciones quedaron aparte")
	assert_eq(options.window_scale, 3)
	assert_false(FileAccess.file_exists(_slots.legacy_path()), "el viejo ya no se lee")
	assert_true(FileAccess.file_exists(_slots.legacy_path() + SaveSlots.LEGACY_BACKUP_SUFFIX), "pero queda la copia")
	assert_false(_slots.migrate_legacy(), "una sola vez")


func test_old_save_is_not_migrated_over_a_used_slot() -> void:
	_write(_slots.slot_path(3), _profile_with(1))
	_write(_slots.legacy_path(), _profile_with(42))
	assert_false(_slots.migrate_legacy())
	assert_false(_slots.is_used(1))
	assert_true(FileAccess.file_exists(_slots.legacy_path()), "no lo toca")


func test_without_an_old_save_nothing_happens() -> void:
	assert_false(_slots.migrate_legacy())
	assert_false(_slots.is_used(1))
	assert_false(FileAccess.file_exists(_slots.options_path()))
