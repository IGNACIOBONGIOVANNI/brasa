extends GutTest
## Contenido (.tres): los enemigos, patrones y sonidos cargan bien y son coherentes entre sí.

const ENEMIES_DIR: String = "res://content/enemies/"
const PATTERNS_DIR: String = "res://content/patterns/"
const LIBRARY: SfxLibrary = preload("res://content/sfx/sfx_library.tres")
## Sonidos que el código pide por id (además de los sfx_id de armas y patrones).
const CODE_SFX: Array[StringName] = [
	&"enemy_hit", &"enemy_die", &"player_hurt", &"player_die", &"roll", &"pulse", &"pulse_empty",
	&"telegraph", &"charge",
]


func _load_all(dir: String) -> Array[Resource]:
	var result: Array[Resource] = []
	for file: String in ResourceLoader.list_directory(dir):
		if file.ends_with(".tres"):
			result.append(load(dir + file))
	return result


func _sfx_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for sfx: SfxData in LIBRARY.sounds:
		ids.append(sfx.id)
	return ids


func test_enemies_are_valid() -> void:
	var enemies: Array[Resource] = _load_all(ENEMIES_DIR)
	assert_eq(enemies.size(), 3, "Carnero, Vigía y Farol")
	for resource: Resource in enemies:
		var enemy := resource as EnemyData
		assert_not_null(enemy, "%s es EnemyData" % resource.resource_path)
		assert_gt(enemy.max_health, 0.0, "%s tiene vida" % enemy.id)
		assert_gt(enemy.telegraph_time, 0.0, "%s avisa antes de atacar" % enemy.id)
		assert_lt(enemy.body_radius, enemy.visual_radius, "%s: el cuerpo es más chico que el dibujo" % enemy.id)
		if enemy.attack_kind == EnemyData.AttackKind.SHOOT:
			assert_gt(enemy.patterns.size(), 0, "%s dispara: tiene patrones" % enemy.id)
			for pattern: BulletPatternData in enemy.patterns:
				assert_not_null(pattern, "%s: patrón cargado" % enemy.id)


func test_all_four_pattern_kinds_are_used() -> void:
	var kinds: Dictionary[BulletPatternData.Kind, bool] = {}
	for resource: Resource in _load_all(PATTERNS_DIR):
		var pattern := resource as BulletPatternData
		assert_not_null(pattern, "%s es BulletPatternData" % resource.resource_path)
		kinds[pattern.kind] = true
	assert_eq(kinds.size(), BulletPatternData.Kind.size(), "anillo, espiral, abanico y apuntado")


func test_sfx_ids_are_unique() -> void:
	var seen: Dictionary[StringName, bool] = {}
	for id: StringName in _sfx_ids():
		assert_false(seen.has(id), "id repetido: %s" % id)
		seen[id] = true


func test_every_sound_used_exists() -> void:
	var ids: Array[StringName] = _sfx_ids()
	var used: Array[StringName] = CODE_SFX.duplicate()
	var weapon: WeaponData = load("res://content/weapons/base_shot.tres")
	used.append(weapon.sfx_id)
	used.append(weapon.impact_sfx_id)
	for resource: Resource in _load_all(PATTERNS_DIR):
		used.append((resource as BulletPatternData).sfx_id)
	for id: StringName in used:
		assert_has(ids, id, "existe el sonido %s" % id)
