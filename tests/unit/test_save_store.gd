extends GutTest
## SaveStore: escritura atómica, lectura con migraciones y qué pasa con archivos rotos, nuevos o a
## medio escribir. Usa una carpeta propia en user:// que se borra después de cada test.

const DIR: String = "user://test_save_store/"
const PATH: String = DIR + "save.json"

var _store: SaveStore


func before_each() -> void:
	_store = SaveStore.new(PATH)
	_store.delete()


func after_each() -> void:
	_store.delete()
	DirAccess.remove_absolute(DIR)


func _write_text(file_path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _add_flag(data: Dictionary) -> Dictionary:
	data["migrated"] = true
	return data


func test_missing_file_reads_empty() -> void:
	assert_eq(_store.read(), {})
	assert_eq(_store.status, SaveStore.Status.MISSING)


func test_write_then_read_round_trips() -> void:
	var data: Dictionary = {"version": SaveSchema.VERSION, "sparks": 12, "list": ["a", "b"]}
	assert_eq(_store.write(data), OK)
	assert_true(FileAccess.file_exists(PATH))
	assert_false(FileAccess.file_exists(PATH + SaveStore.TEMP_SUFFIX), "no queda el temporal")
	var read: Dictionary = SaveStore.new(PATH).read()
	assert_eq(int(read["sparks"]), 12)
	assert_eq(read["list"], ["a", "b"])


func test_writing_again_replaces_the_file() -> void:
	_store.write({"version": SaveSchema.VERSION, "sparks": 1})
	assert_eq(_store.write({"version": SaveSchema.VERSION, "sparks": 2}), OK, "renombra encima del anterior")
	assert_eq(int(_store.read()["sparks"]), 2)


func test_old_versions_are_migrated_on_read() -> void:
	_write_text(PATH, JSON.stringify({"version": 1, "sparks": 5}))
	var steps: Array[Callable] = [_add_flag]
	_store.steps = steps
	var read: Dictionary = _store.read()
	assert_eq(_store.status, SaveStore.Status.OK)
	assert_eq(int(read["version"]), 2)
	assert_true(read["migrated"])


func test_corrupt_file_is_set_aside() -> void:
	_write_text(PATH, "{ esto no es json")
	assert_eq(_store.read(), {})
	assert_eq(_store.status, SaveStore.Status.CORRUPT)
	assert_false(FileAccess.file_exists(PATH), "salió del camino")
	assert_true(FileAccess.file_exists(PATH + SaveStore.CORRUPT_SUFFIX), "pero no se borró")


func test_file_without_version_counts_as_corrupt() -> void:
	_write_text(PATH, JSON.stringify({"sparks": 5}))
	_store.read()
	assert_eq(_store.status, SaveStore.Status.CORRUPT)


func test_newer_version_is_left_untouched() -> void:
	var text: String = JSON.stringify({"version": SaveSchema.VERSION + 1, "sparks": 5})
	_write_text(PATH, text)
	assert_eq(_store.read(), {})
	assert_eq(_store.status, SaveStore.Status.TOO_NEW)
	assert_eq(FileAccess.get_file_as_string(PATH), text, "no lo tocó")


func test_leftover_temp_file_is_recovered() -> void:
	# Un corte entre borrar el guardado viejo y renombrar el temporal deja solo el temporal.
	_write_text(PATH + SaveStore.TEMP_SUFFIX, JSON.stringify({"version": SaveSchema.VERSION, "sparks": 9}))
	var read: Dictionary = _store.read()
	assert_eq(_store.status, SaveStore.Status.RECOVERED)
	assert_eq(int(read["sparks"]), 9)


func test_half_written_temp_file_does_not_hide_the_save() -> void:
	_write_text(PATH, JSON.stringify({"version": SaveSchema.VERSION, "sparks": 3}))
	_write_text(PATH + SaveStore.TEMP_SUFFIX, "{\"version\": 1, \"spa")
	assert_eq(int(_store.read()["sparks"]), 3)
	assert_eq(_store.status, SaveStore.Status.OK)
