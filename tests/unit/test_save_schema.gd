extends GutTest
## SaveSchema: versión del guardado y migraciones encadenadas (con migraciones de prueba).


## v1 → v2: renombra "coins" a "sparks".
func _rename_coins(data: Dictionary) -> Dictionary:
	data["sparks"] = data.get("coins", 0)
	data.erase("coins")
	return data


## v2 → v3: agrega los totales.
func _add_totals(data: Dictionary) -> Dictionary:
	data["totals"] = {"runs": 0}
	return data


func test_the_game_has_one_migration_per_version() -> void:
	assert_eq(SaveSchema.latest(SaveSchema.migrations()), SaveSchema.VERSION)


func test_version_of_reads_ints_and_json_floats() -> void:
	assert_eq(SaveSchema.version_of({"version": 2}), 2)
	assert_eq(SaveSchema.version_of({"version": 3.0}), 3, "el JSON trae floats")
	assert_eq(SaveSchema.version_of({}), 0, "sin versión")
	assert_eq(SaveSchema.version_of({"version": "1"}), 0, "texto no vale")
	assert_eq(SaveSchema.version_of({"version": -4}), 0)


func test_upgrade_chains_every_missing_step_in_order() -> void:
	var steps: Array[Callable] = [_rename_coins, _add_totals]
	var old: Dictionary = {"version": 1, "coins": 7}
	var upgraded: Dictionary = SaveSchema.upgrade(old, steps)
	assert_eq(upgraded["version"], 3)
	assert_eq(upgraded["sparks"], 7, "aplicó la primera")
	assert_false(upgraded.has("coins"))
	assert_true(upgraded.has("totals"), "y la segunda")
	assert_eq(old["coins"], 7, "no tocó el original")


func test_upgrade_skips_the_steps_already_applied() -> void:
	var steps: Array[Callable] = [_rename_coins, _add_totals]
	var upgraded: Dictionary = SaveSchema.upgrade({"version": 2, "sparks": 3, "coins": 99}, steps)
	assert_eq(upgraded["version"], 3)
	assert_eq(upgraded["sparks"], 3, "no volvió a renombrar")
	assert_true(upgraded.has("totals"))


func test_latest_save_needs_no_steps() -> void:
	var steps: Array[Callable] = [_rename_coins]
	assert_eq(SaveSchema.upgrade({"version": 2, "sparks": 1}, steps), {"version": 2, "sparks": 1})


func test_can_upgrade_only_known_versions() -> void:
	var steps: Array[Callable] = [_rename_coins]
	assert_true(SaveSchema.can_upgrade({"version": 1}, steps))
	assert_true(SaveSchema.can_upgrade({"version": 2}, steps))
	assert_false(SaveSchema.can_upgrade({"version": 3}, steps), "más nueva que el juego")
	assert_false(SaveSchema.can_upgrade({}, steps), "sin versión")
