extends GutTest
## Contenido (.tres): enemigos, patrones, sonidos, plantillas de sala, pickups y el tema del piso
## cargan bien y son coherentes entre sí.

const ENEMIES_DIR: String = "res://content/enemies/"
const PATTERNS_DIR: String = "res://content/patterns/"
const PICKUPS_DIR: String = "res://content/pickups/"
const ROOMS_DIR: String = "res://content/rooms/floor_1/"
const LIBRARY: SfxLibrary = preload("res://content/sfx/sfx_library.tres")
const FLOOR_1: FloorTheme = preload("res://content/floors/floor_1.tres")
## Distancia mínima (en celdas, contando diagonales) entre un enemigo y la entrada de una puerta.
const ENEMY_DOOR_DISTANCE: int = 3
## Sonidos que el código pide por id (además de los sfx_id de armas, patrones y pickups).
const CODE_SFX: Array[StringName] = [
	&"enemy_hit", &"enemy_die", &"player_hurt", &"player_die", &"roll", &"pulse", &"empty",
	&"telegraph", &"charge", &"door_close", &"door_open", &"room_clear", &"bomb_place",
	&"explosion", &"rock_break", &"secret_found",
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
	for resource: Resource in _load_all(PICKUPS_DIR):
		used.append((resource as PickupData).sfx_id)
	for id: StringName in used:
		assert_has(ids, id, "existe el sonido %s" % id)


func test_room_templates_are_valid_and_resolvable() -> void:
	for template: RoomTemplate in FLOOR_1.templates:
		var grid: RoomGrid = RoomTemplateParser.parse(template.layout)
		assert_true(grid.is_valid(), "%s: %s" % [template.id, ", ".join(grid.errors)])
		for marker: RoomGrid.EnemyMarker in grid.enemies:
			assert_not_null(FLOOR_1.enemy_for_symbol(marker.symbol), "%s: enemigo %s" % [template.id, marker.symbol])
		for marker: RoomGrid.PickupMarker in grid.pickups:
			assert_not_null(FLOOR_1.pickup_for_symbol(marker.symbol), "%s: pickup %s" % [template.id, marker.symbol])


func test_enemies_spawn_away_from_doors() -> void:
	for template: RoomTemplate in FLOOR_1.templates:
		for marker: RoomGrid.EnemyMarker in RoomTemplateParser.parse(template.layout).enemies:
			for side: Vector2i in FloorLayout.DIRECTIONS:
				var entrance: Vector2i = RoomGrid.door_cells(side)[1]
				var gap: Vector2i = (marker.cell - entrance).abs()
				assert_gte(maxi(gap.x, gap.y), ENEMY_DOOR_DISTANCE,
						"%s: enemigo en %s muy cerca de la puerta %s" % [template.id, marker.cell, side])


func test_floor_has_templates_for_every_room() -> void:
	var by_kind: Dictionary[RoomSlot.Kind, int] = {}
	var difficulties: Dictionary[int, bool] = {}
	for template: RoomTemplate in FLOOR_1.templates:
		by_kind[template.kind] = by_kind.get(template.kind, 0) + 1
		var grid: RoomGrid = RoomTemplateParser.parse(template.layout)
		if template.kind == RoomSlot.Kind.NORMAL:
			difficulties[template.difficulty] = true
			assert_gt(grid.enemies.size(), 0, "%s: las salas normales tienen enemigos" % template.id)
		elif template.kind != RoomSlot.Kind.BOSS:
			assert_eq(grid.enemies.size(), 0, "%s: las salas especiales no tienen enemigos" % template.id)
	for kind: int in RoomSlot.Kind.size():
		assert_gt(by_kind.get(kind, 0), 0, "hay plantillas de tipo %d" % kind)
	assert_gte(by_kind.get(RoomSlot.Kind.NORMAL, 0), 10, "al menos 10 salas normales")
	assert_eq(difficulties.size(), TemplatePicker.MAX_DIFFICULTY, "salas normales de cada dificultad")


func test_every_room_file_is_in_the_floor() -> void:
	var in_theme: Dictionary[String, bool] = {}
	for template: RoomTemplate in FLOOR_1.templates:
		in_theme[template.resource_path] = true
	for resource: Resource in _load_all(ROOMS_DIR):
		assert_true(in_theme.has(resource.resource_path), "%s está en floor_1.tres" % resource.resource_path)


func test_pickups_cover_every_kind_with_unique_symbols() -> void:
	var kinds: Dictionary[PickupData.Kind, bool] = {}
	var symbols: Dictionary[String, bool] = {}
	for pickup: PickupData in FLOOR_1.pickups:
		assert_false(symbols.has(pickup.template_symbol), "símbolo repetido %s" % pickup.template_symbol)
		symbols[pickup.template_symbol] = true
		kinds[pickup.kind] = true
		assert_true(RoomTemplateParser.PICKUP_SYMBOLS.contains(pickup.template_symbol))
	assert_eq(kinds.size(), PickupData.Kind.size(), "moneda, corazón, bomba y llave")
