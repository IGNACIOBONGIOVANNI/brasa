extends GutTest
## Contenido (.tres): enemigos, patrones, sonidos, plantillas de sala, pickups, items, armas, pisos,
## personajes y logros cargan bien y son coherentes entre sí.

const ENEMIES_DIR: String = "res://content/enemies/"
const PATTERNS_DIR: String = "res://content/patterns/"
const PICKUPS_DIR: String = "res://content/pickups/"
const ROOMS_DIR: String = "res://content/rooms/floor_1/"
const ITEMS_DIR: String = "res://content/items/"
const WEAPONS_DIR: String = "res://content/weapons/"
const LIBRARY: SfxLibrary = preload("res://content/sfx/sfx_library.tres")
const FLOOR_1: FloorTheme = preload("res://content/floors/floor_1.tres")
const CATALOG: ItemCatalog = preload("res://content/items/catalog.tres")
const RUN: RunConfig = preload("res://content/run/run_config.tres")
const META: MetaConfig = preload("res://content/meta/meta_config.tres")
const CHARACTERS_DIR: String = "res://content/characters/"
const ACHIEVEMENTS_DIR: String = "res://content/achievements/"
## Distancia mínima (en celdas, contando diagonales) entre un enemigo y la entrada de una puerta.
const ENEMY_DOOR_DISTANCE: int = 3
## Sonidos que el código pide por id (además de los sfx_id de armas, patrones y pickups).
const CODE_SFX: Array[StringName] = [
	&"enemy_hit", &"enemy_die", &"player_hurt", &"player_die", &"roll", &"pulse", &"empty",
	&"telegraph", &"charge", &"door_close", &"door_open", &"room_clear", &"bomb_place",
	&"explosion", &"rock_break", &"secret_found", &"item_pickup", &"buy", &"unlock", &"reload",
	&"weapon_swap", &"active_use", &"active_ready", &"pickup_heart", &"boss_phase", &"boss_die",
	&"exit_open", &"ui_select", &"pause", &"achievement", &"lightning", &"heartbeat", &"boss_intro",
	&"victory", &"defeat", &"medkit", &"revive", &"hop", &"beam", &"burrow", &"summon", &"lob",
	&"shield_block",
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
	assert_gte(enemies.size(), 3, "al menos Carnero, Vigía y Farol")
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
	for resource: Resource in _load_all(WEAPONS_DIR):
		var weapon := resource as WeaponData
		for id: StringName in [weapon.sfx_id, weapon.impact_sfx_id]:
			if id != &"":
				used.append(id)
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
	var templates: Dictionary[RoomTemplate, bool] = {}
	for theme: FloorTheme in RUN.floors:
		for template: RoomTemplate in theme.templates:
			templates[template] = true
	for template: RoomTemplate in templates:
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


func test_items_are_valid() -> void:
	var ids: Dictionary[StringName, bool] = {}
	var all: Array[ItemData] = CATALOG.items.duplicate()
	all.append(CATALOG.filler)
	for item: ItemData in all:
		assert_false(ids.has(item.id), "id repetido: %s" % item.id)
		ids[item.id] = true
		assert_ne(item.display_name, "", "%s tiene nombre" % item.id)
		assert_ne(item.description, "", "%s tiene descripción" % item.id)
		assert_gt(item.price, 0, "%s tiene precio" % item.id)
		var icon: PackedStringArray = item.get_icon()
		assert_false(icon.is_empty(), "%s tiene ícono" % item.id)
		for row: String in icon:
			assert_eq(row.length(), icon[0].length(), "%s: filas del ícono parejas" % item.id)
		for modifier: StatModifier in item.modifiers:
			assert_has(StatBlock.STAT_NAMES, modifier.stat, "%s: stat %s existe" % [item.id, modifier.stat])
		if item.hook_script != null:
			assert_not_null(item.hook_script.new() as ItemHook, "%s: el hook extiende ItemHook" % item.id)
		match item.kind:
			ItemData.Kind.ACTIVE:
				assert_gt(item.max_charge, 0, "%s: activo con carga" % item.id)
				assert_not_null(item.hook_script, "%s: activo con hook" % item.id)
			ItemData.Kind.WEAPON:
				assert_not_null(item.weapon, "%s: arma con WeaponData" % item.id)
	assert_eq(CATALOG.filler.pools, 0, "el relleno no está en ningún pool")


func test_qualities_are_complete_and_the_best_are_few() -> void:
	assert_eq(ItemData.QUALITY_NAMES.size(), ItemData.Quality.size(), "un nombre por calidad")
	assert_eq(ItemData.QUALITY_COLORS.size(), ItemData.Quality.size(), "un color por calidad")
	assert_eq(ItemData.QUALITY_PRICE_BONUS.size(), ItemData.Quality.size(), "un recargo por calidad")
	for quality_name: String in ItemData.QUALITY_NAMES:
		for letter: String in quality_name:
			assert_has(PixelIcons.QUALITY_GLYPHS, letter, "hay letra de píxeles para %s" % quality_name)
	var counts: Array[int] = []
	counts.resize(ItemData.Quality.size())
	for item: ItemData in CATALOG.items:
		counts[item.quality] += 1
		if item.quality == ItemData.Quality.S_PLUS_PLUS:
			assert_false(item.is_in_pool(ItemData.POOL_SHOP), "%s: S++ no se vende" % item.id)
	for quality: int in ItemData.Quality.size():
		assert_gt(counts[quality], 0, "hay items %s" % ItemData.QUALITY_NAMES[quality])
	assert_between(counts[ItemData.Quality.S], 1, 4, "muy pocos S")
	assert_between(counts[ItemData.Quality.S_PLUS_PLUS], 1, 3, "muy pocos S++")
	assert_lt(counts[ItemData.Quality.S_PLUS_PLUS], counts[ItemData.Quality.A], "menos S++ que A")


func test_catalog_has_the_milestone_items() -> void:
	var passive_or_active: int = 0
	var actives: int = 0
	var stats_touched: Dictionary[StringName, bool] = {}
	for item: ItemData in CATALOG.items:
		if item.kind != ItemData.Kind.WEAPON:
			passive_or_active += 1
		if item.kind == ItemData.Kind.ACTIVE:
			actives += 1
		for modifier: StatModifier in item.modifiers:
			stats_touched[modifier.stat] = true
	assert_gte(passive_or_active, 10, "al menos 10 items")
	assert_gte(actives, 2, "al menos 2 activos")
	for stat: StringName in [&"bounces", &"pierce", &"homing"]:
		assert_true(stats_touched.has(stat), "algún item da %s" % stat)
	# Sin nada desbloqueado los pools tienen que alcanzar igual.
	for pool: int in [ItemData.POOL_TREASURE, ItemData.POOL_SHOP]:
		var count: int = 0
		for item: ItemData in CATALOG.items:
			if item.is_in_pool(pool) and not item.locked:
				count += 1
		assert_gte(count, FloorController.SHOP_OFFERS + 1, "el pool %d alcanza para un piso" % pool)


func test_every_item_file_is_in_the_catalog() -> void:
	var in_catalog: Dictionary[String, bool] = {CATALOG.filler.resource_path: true}
	for item: ItemData in CATALOG.items:
		in_catalog[item.resource_path] = true
	for resource: Resource in _load_all(ITEMS_DIR):
		if resource is ItemData:
			assert_true(in_catalog.has(resource.resource_path), "%s está en el catálogo" % resource.resource_path)


func test_weapons_are_valid_and_cover_every_mode() -> void:
	var modes: Dictionary[WeaponData.FireMode, bool] = {}
	for resource: Resource in _load_all(WEAPONS_DIR):
		var weapon := resource as WeaponData
		assert_not_null(weapon, "%s es WeaponData" % resource.resource_path)
		modes[weapon.fire_mode] = true
		assert_eq(weapon.icon.size(), 5, "%s: ícono de 5 filas" % weapon.id)
		for row: String in weapon.icon:
			assert_eq(row.length(), 9, "%s: ícono de 9 columnas" % weapon.id)
		assert_true(weapon.magazine != 0 and weapon.ammo != 0, "%s: munición coherente" % weapon.id)
	assert_eq(modes.size(), WeaponData.FireMode.size(), "simple, escopeta, ráfaga, láser y orbital")


func test_treasure_and_shop_have_pedestal_spots() -> void:
	for template: RoomTemplate in FLOOR_1.templates:
		var spots: int = RoomTemplateParser.parse(template.layout).item_spots.size()
		if template.kind in [RoomSlot.Kind.TREASURE, RoomSlot.Kind.BOSS, RoomSlot.Kind.SECRET]:
			assert_eq(spots, 1, "%s: un pedestal (en el jefe aparece al vencerlo)" % template.id)
		elif template.kind == RoomSlot.Kind.SHOP:
			assert_eq(spots, FloorController.SHOP_OFFERS, "%s: un pedestal por oferta" % template.id)
		else:
			assert_eq(spots, 0, "%s: sin pedestales" % template.id)


func test_run_floors_are_complete() -> void:
	assert_eq(RUN.floors.size(), 4, "cuatro pisos")
	for theme: FloorTheme in RUN.floors:
		var kinds: Dictionary[RoomSlot.Kind, bool] = {}
		for template: RoomTemplate in theme.templates:
			kinds[template.kind] = true
			var grid: RoomGrid = RoomTemplateParser.parse(template.layout)
			assert_true(grid.is_valid(), "%s/%s: %s" % [theme.id, template.id, ", ".join(grid.errors)])
			for marker: RoomGrid.EnemyMarker in grid.enemies:
				assert_not_null(theme.enemy_for_symbol(marker.symbol), "%s/%s: enemigo %s" % [theme.id, template.id, marker.symbol])
			if template.kind == RoomSlot.Kind.BOSS:
				assert_eq(grid.enemies.size(), 1, "%s/%s: un solo enemigo, el jefe" % [theme.id, template.id])
				var boss: EnemyData = theme.enemy_for_symbol(grid.enemies[0].symbol)
				assert_false(boss == null or boss.phases.is_empty(), "%s/%s: es un jefe con fases" % [theme.id, template.id])
		for kind: int in RoomSlot.Kind.size():
			assert_true(kinds.has(kind), "%s tiene plantillas de tipo %d" % [theme.id, kind])
	for i: int in range(1, RUN.floors.size()):
		var previous: FloorTheme = RUN.floors[i - 1]
		var current: FloorTheme = RUN.floors[i]
		assert_gt(current.enemy_health_mult, previous.enemy_health_mult, "el piso %d es más difícil" % (i + 1))
		assert_gte(current.enemy_bullet_speed_mult, previous.enemy_bullet_speed_mult, "piso %d: balas" % (i + 1))
		assert_gte(current.room_count_min, previous.room_count_min, "piso %d: salas" % (i + 1))


func test_bosses_have_valid_phases() -> void:
	var bosses: int = 0
	for resource: Resource in _load_all(ENEMIES_DIR):
		var enemy := resource as EnemyData
		if enemy.phases.is_empty():
			continue
		bosses += 1
		assert_ne(enemy.epithet, "", "%s: tiene apodo para el cartel" % enemy.id)
		assert_eq(enemy.phases[0].health_fraction, 1.0, "%s: la primera fase arranca con la vida llena" % enemy.id)
		for i: int in enemy.phases.size():
			var boss_phase: BossPhase = enemy.phases[i]
			assert_not_null(boss_phase.behavior, "%s: fase %d con comportamiento" % [enemy.id, i])
			assert_gt(boss_phase.behavior.telegraph_time, 0.0, "%s: fase %d avisa antes de atacar" % [enemy.id, i])
			if boss_phase.behavior.attack_kind == EnemyData.AttackKind.SHOOT:
				assert_gt(boss_phase.behavior.patterns.size(), 0, "%s: fase %d con patrones" % [enemy.id, i])
			if i > 0:
				assert_lt(boss_phase.health_fraction, enemy.phases[i - 1].health_fraction, "%s: umbrales de mayor a menor" % enemy.id)
	assert_gte(bosses, RUN.floors.size(), "un jefe por piso")


func test_every_room_file_is_in_its_floor() -> void:
	for i: int in RUN.floors.size():
		var in_theme: Dictionary[String, bool] = {}
		for template: RoomTemplate in RUN.floors[i].templates:
			in_theme[template.resource_path] = true
		for resource: Resource in _load_all("res://content/rooms/floor_%d/" % (i + 1)):
			assert_true(in_theme.has(resource.resource_path), "%s está en floor_%d.tres" % [resource.resource_path, i + 1])


func test_each_floor_has_its_own_boss_and_enemy_letters_are_unique() -> void:
	var bosses: Dictionary[EnemyData, bool] = {}
	for theme: FloorTheme in RUN.floors:
		var letters: Dictionary[String, bool] = {}
		for enemy: EnemyData in theme.enemies:
			assert_false(letters.has(enemy.template_char), "%s: letra %s repetida" % [theme.id, enemy.template_char])
			letters[enemy.template_char] = true
			if not enemy.phases.is_empty():
				assert_false(bosses.has(enemy), "%s: el jefe %s ya está en otro piso" % [theme.id, enemy.id])
				bosses[enemy] = true
	assert_eq(bosses.size(), RUN.floors.size(), "un jefe distinto por piso")


func test_each_floor_has_its_own_mood() -> void:
	var lights: Dictionary[Color, bool] = {}
	for theme: FloorTheme in RUN.floors:
		assert_false(lights.has(theme.ambient_light), "%s: penumbra propia" % theme.id)
		lights[theme.ambient_light] = true
		assert_gt(theme.mote_amount, 0, "%s: tiene partículas de ambiente" % theme.id)
		assert_gt(theme.mote_color.a, 0.0, "%s: partículas visibles" % theme.id)


func test_floor_names_are_unique() -> void:
	var names: Dictionary[String, bool] = {}
	for theme: FloorTheme in RUN.floors:
		assert_false(names.has(theme.display_name), "nombre repetido: %s" % theme.display_name)
		assert_ne(theme.tagline, "", "%s: tiene su línea de historia" % theme.id)
		names[theme.display_name] = true


func test_characters_are_valid() -> void:
	assert_gte(META.characters.size(), 3, "tres personajes")
	assert_false(META.default_character().locked, "el primero está desbloqueado")
	var ids: Dictionary[StringName, bool] = {}
	for character: CharacterData in META.characters:
		assert_false(ids.has(character.id), "id repetido: %s" % character.id)
		ids[character.id] = true
		assert_ne(character.display_name, "", "%s tiene nombre" % character.id)
		assert_ne(character.description, "", "%s tiene descripción" % character.id)
		assert_not_null(character.stats, "%s tiene stats" % character.id)
		assert_gt(character.stats.max_health, 0.0, "%s tiene vida" % character.id)
		assert_eq(fmod(character.stats.max_health, 2.0), 0.0, "%s: corazones enteros" % character.id)
		if character.start_item != null:
			assert_has(CATALOG.items, character.start_item, "%s: el item inicial está en el catálogo" % character.id)
		if character.locked:
			assert_not_null(META.achievement_unlocking(character), "%s: algún logro lo desbloquea" % character.id)


func test_achievements_are_valid() -> void:
	var ids: Dictionary[StringName, bool] = {}
	for achievement: AchievementData in META.achievements:
		assert_false(ids.has(achievement.id), "id repetido: %s" % achievement.id)
		ids[achievement.id] = true
		assert_ne(achievement.display_name, "", "%s tiene nombre" % achievement.id)
		assert_ne(achievement.description, "", "%s tiene descripción" % achievement.id)
		assert_ne(achievement.unlocks_text(), "", "%s desbloquea algo" % achievement.id)
		if achievement.condition == AchievementData.Condition.DEFEAT_BOSS:
			assert_not_null(achievement.boss, "%s: qué jefe" % achievement.id)
			assert_true(achievement.boss != null and achievement.boss.phases.size() > 0, "%s: es un jefe" % achievement.id)
		else:
			assert_gt(achievement.amount, 0, "%s: cuánto" % achievement.id)
		for item: ItemData in achievement.unlock_items:
			assert_true(item.locked, "%s: %s arranca bloqueado" % [achievement.id, item.id])
			assert_has(CATALOG.items, item, "%s: %s está en el catálogo" % [achievement.id, item.id])
		for character: CharacterData in achievement.unlock_characters:
			assert_true(character.locked, "%s: %s arranca bloqueado" % [achievement.id, character.id])
			assert_has(META.characters, character, "%s: %s está en la lista" % [achievement.id, character.id])


func test_every_locked_item_can_be_unlocked() -> void:
	var by_achievement: Dictionary[StringName, bool] = {}
	for achievement: AchievementData in META.achievements:
		for item: ItemData in achievement.unlock_items:
			by_achievement[item.id] = true
	for item: ItemData in CATALOG.items:
		if item.locked:
			assert_true(item.unlock_cost > 0 or by_achievement.has(item.id), "%s: se compra o sale de un logro" % item.id)
	assert_gte(CATALOG.workshop_items().size(), 3, "el Taller vende algo")
	assert_false(CATALOG.filler.locked, "el relleno no se bloquea")


func test_every_character_and_achievement_file_is_listed() -> void:
	for resource: Resource in _load_all(CHARACTERS_DIR):
		assert_has(META.characters, resource, "%s está en meta_config" % resource.resource_path)
	for resource: Resource in _load_all(ACHIEVEMENTS_DIR):
		assert_has(META.achievements, resource, "%s está en meta_config" % resource.resource_path)


## Al exportar, Godot convierte los .tres a binario y en 4.7 eso vacía los PackedStringArray (los
## íconos de píxeles): el proyecto exporta los recursos como texto.
func test_export_keeps_text_resources() -> void:
	assert_false(ProjectSettings.get_setting("editor/export/convert_text_resources_to_binary", true))
