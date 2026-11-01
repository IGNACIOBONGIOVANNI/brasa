extends GutTest
## MetaProfile y MetaRules: desbloqueos, Taller, chispas por run, logros y pasar a/desde el
## diccionario del guardado. Con items, personajes y logros armados acá (no el contenido real).

var _profile: MetaProfile


func before_each() -> void:
	_profile = MetaProfile.new()


func _item(id: StringName, locked: bool, cost: int = 0) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.locked = locked
	item.unlock_cost = cost
	return item


func _character(id: StringName, locked: bool) -> CharacterData:
	var character := CharacterData.new()
	character.id = id
	character.locked = locked
	return character


func _record(kills: int, bosses: Array[StringName], victory: bool) -> RunRecord:
	var record := RunRecord.new()
	record.kills = kills
	record.bosses = bosses
	record.victory = victory
	return record


func _boss(id: StringName) -> EnemyData:
	var boss := EnemyData.new()
	boss.id = id
	return boss


func _achievement(id: StringName, condition: AchievementData.Condition, amount: int) -> AchievementData:
	var achievement := AchievementData.new()
	achievement.id = id
	achievement.condition = condition
	achievement.amount = amount
	return achievement


func test_locked_things_need_an_unlock() -> void:
	var free_item: ItemData = _item(&"libre", false)
	var locked_item: ItemData = _item(&"cerrado", true)
	var locked_character: CharacterData = _character(&"otro", true)
	assert_true(_profile.is_item_available(free_item))
	assert_false(_profile.is_item_available(locked_item))
	assert_false(_profile.is_character_available(locked_character))
	var items: Array[ItemData] = [free_item, locked_item]
	var expected: Array[ItemData] = [free_item]
	assert_eq(_profile.available_items(items), expected)
	_profile.unlocked_items[&"cerrado"] = true
	_profile.unlocked_characters[&"otro"] = true
	assert_true(_profile.is_item_available(locked_item))
	assert_true(_profile.is_character_available(locked_character))


func test_buying_spends_sparks_once() -> void:
	var item: ItemData = _item(&"lupa", true, 20)
	_profile.sparks = 19
	assert_false(_profile.buy(item), "no alcanza")
	_profile.sparks = 25
	assert_true(_profile.buy(item))
	assert_eq(_profile.sparks, 5)
	assert_true(_profile.is_item_available(item))
	assert_false(_profile.buy(item), "ya está")
	assert_eq(_profile.sparks, 5)


func test_achievement_only_items_are_not_for_sale() -> void:
	_profile.sparks = 999
	assert_false(_profile.can_buy(_item(&"de_logro", true, 0)))
	assert_false(_profile.can_buy(_item(&"comun", false, 10)), "lo que no está bloqueado no se vende")


func test_sparks_for_a_run() -> void:
	var no_bosses: Array[StringName] = []
	var one_boss: Array[StringName] = [&"campanario"]
	var two_bosses: Array[StringName] = [&"campanario", &"rey_carnero"]
	assert_eq(MetaRules.sparks_for(_record(0, no_bosses, false)), 0)
	assert_eq(MetaRules.sparks_for(_record(14, no_bosses, false)), 2, "una cada 5 enemigos")
	assert_eq(MetaRules.sparks_for(_record(20, one_boss, false)), 14, "más 10 por jefe")
	assert_eq(MetaRules.sparks_for(_record(50, two_bosses, true)), 10 + 20 + 10, "más 10 por ganar")


func test_record_run_adds_sparks_and_totals() -> void:
	var bosses: Array[StringName] = [&"campanario"]
	var no_achievements: Array[AchievementData] = []
	var rewards: MetaProfile.RunRewards = _profile.record_run(_record(10, bosses, false), no_achievements)
	assert_eq(rewards.sparks, 12)
	assert_eq(_profile.sparks, 12)
	_profile.record_run(_record(5, bosses, true), no_achievements)
	assert_eq(_profile.sparks, 12 + 11 + 10)
	assert_eq(_profile.runs, 2)
	assert_eq(_profile.wins, 1)
	assert_eq(_profile.total_kills, 15)


func test_achievements_unlock_their_rewards_once() -> void:
	var achievement: AchievementData = _achievement(&"jefe", AchievementData.Condition.DEFEAT_BOSS, 0)
	achievement.boss = _boss(&"campanario")
	var item: ItemData = _item(&"premio", true)
	var character: CharacterData = _character(&"heroe", true)
	var unlock_items: Array[ItemData] = [item]
	var unlock_characters: Array[CharacterData] = [character]
	achievement.unlock_items = unlock_items
	achievement.unlock_characters = unlock_characters
	var all: Array[AchievementData] = [achievement]
	var no_bosses: Array[StringName] = []
	var boss: Array[StringName] = [&"campanario"]
	assert_eq(_profile.record_run(_record(3, no_bosses, false), all).achievements.size(), 0, "sin vencer al jefe")
	var rewards: MetaProfile.RunRewards = _profile.record_run(_record(3, boss, false), all)
	assert_eq(rewards.achievements, all, "se cumplió")
	assert_true(_profile.has_achievement(achievement))
	assert_true(_profile.is_item_available(item))
	assert_true(_profile.is_character_available(character))
	assert_eq(_profile.record_run(_record(3, boss, false), all).achievements.size(), 0, "no se repite")


func test_conditions() -> void:
	var no_bosses: Array[StringName] = []
	var record: RunRecord = _record(30, no_bosses, false)
	record.items = 4
	_profile.total_kills = 120
	var total: AchievementData = _achievement(&"a", AchievementData.Condition.TOTAL_KILLS, 100)
	var in_run: AchievementData = _achievement(&"b", AchievementData.Condition.KILLS_IN_RUN, 40)
	var items: AchievementData = _achievement(&"c", AchievementData.Condition.ITEMS_IN_RUN, 4)
	var boss: AchievementData = _achievement(&"d", AchievementData.Condition.DEFEAT_BOSS, 0)
	assert_true(MetaRules.is_met(total, _profile, record))
	assert_false(MetaRules.is_met(in_run, _profile, record))
	assert_true(MetaRules.is_met(items, _profile, record))
	assert_false(MetaRules.is_met(boss, _profile, record), "sin jefe configurado nunca se cumple")


func test_dict_round_trip() -> void:
	_profile.sparks = 33
	_profile.unlocked_items[&"lupa"] = true
	_profile.unlocked_items[&"cuarzo"] = true
	_profile.unlocked_characters[&"musgo"] = true
	_profile.achievements[&"furia"] = true
	_profile.last_character = &"musgo"
	_profile.runs = 4
	_profile.wins = 1
	_profile.total_kills = 210
	var data: Dictionary = _profile.to_dict()
	assert_eq(data["version"], SaveSchema.VERSION)
	assert_eq(data["unlocked_items"], ["cuarzo", "lupa"], "ordenados")
	# Pasa por JSON como en el archivo real (los números vuelven como float).
	var copy: MetaProfile = MetaProfile.from_dict(JSON.parse_string(JSON.stringify(data)))
	assert_eq(copy.sparks, 33)
	assert_eq(copy.unlocked_items, _profile.unlocked_items)
	assert_eq(copy.unlocked_characters, _profile.unlocked_characters)
	assert_eq(copy.achievements, _profile.achievements)
	assert_eq(copy.last_character, &"musgo")
	assert_eq([copy.runs, copy.wins, copy.total_kills], [4, 1, 210])


func test_from_dict_tolerates_missing_and_bad_values() -> void:
	var copy: MetaProfile = MetaProfile.from_dict({
		"sparks": "muchas",
		"unlocked_items": ["lupa", 7, "", null],
		"unlocked_characters": "musgo",
		"last_character": 3,
		"totals": {"runs": -2, "kills": 5.0},
	})
	assert_eq(copy.sparks, 0)
	var expected: Dictionary[StringName, bool] = {&"lupa": true}
	assert_eq(copy.unlocked_items, expected, "solo los textos")
	assert_eq(copy.unlocked_characters.size(), 0)
	assert_eq(copy.last_character, &"")
	assert_eq(copy.runs, 0, "nunca negativos")
	assert_eq(copy.total_kills, 5)
	assert_eq(MetaProfile.from_dict({}).sparks, 0, "vacío = perfil nuevo")


func test_intro_seen_round_trip() -> void:
	assert_false(MetaProfile.from_dict({}).intro_seen, "un guardado viejo no la vio")
	_profile.intro_seen = true
	var copy: MetaProfile = MetaProfile.from_dict(JSON.parse_string(JSON.stringify(_profile.to_dict())))
	assert_true(copy.intro_seen)
	assert_false(MetaProfile.from_dict({"intro_seen": "sí"}).intro_seen, "solo true cuenta")


func test_window_scale_round_trip_and_clamp() -> void:
	assert_eq(MetaProfile.from_dict({}).window_scale, WindowScales.DEFAULT_SCALE, "sin dato: 1280x720")
	_profile.window_scale = 5
	var copy: MetaProfile = MetaProfile.from_dict(JSON.parse_string(JSON.stringify(_profile.to_dict())))
	assert_eq(copy.window_scale, 5)
	assert_eq(MetaProfile.from_dict({"options": {"window_scale": 99}}).window_scale, WindowScales.MAX_SCALE, "recortada")
	assert_eq(MetaProfile.from_dict({"options": {"window_scale": "grande"}}).window_scale, WindowScales.DEFAULT_SCALE)


func test_options_round_trip_and_clamp() -> void:
	_profile.volume = 0.4
	_profile.music_volume = 0.3
	_profile.fullscreen = true
	var copy: MetaProfile = MetaProfile.from_dict(JSON.parse_string(JSON.stringify(_profile.to_dict())))
	assert_almost_eq(copy.volume, 0.4, 0.0001)
	assert_almost_eq(copy.music_volume, 0.3, 0.0001)
	assert_true(copy.fullscreen)
	var bad: MetaProfile = MetaProfile.from_dict({"options": {"volume": 7, "music_volume": -2, "fullscreen": "sí"}})
	assert_eq(bad.volume, 1.0, "recortado a 1")
	assert_eq(bad.music_volume, 0.0, "recortado a 0")
	assert_false(bad.fullscreen, "solo true cuenta")
	assert_eq(MetaProfile.from_dict({}).volume, 1.0, "sin opciones: volumen al máximo")
	assert_eq(MetaProfile.from_dict({}).music_volume, MetaProfile.DEFAULT_MUSIC_VOLUME, "guardados viejos: la música por defecto")
