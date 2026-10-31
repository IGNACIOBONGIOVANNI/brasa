extends GutTest
## Hito 8: los textos de la Mochila (stats, armas y lo que cambia cada item).


func _modifier(stat: StringName, op: StatModifier.Op, value: float) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat = stat
	modifier.op = op
	modifier.value = value
	return modifier


func test_every_stat_has_a_name() -> void:
	for stat: StringName in StatBlock.STAT_NAMES:
		assert_has(InventoryMenu.STAT_LABELS, stat, "nombre para %s" % stat)


func test_base_stats_without_needless_decimals() -> void:
	assert_eq(InventoryMenu.stats_text(StatBlock.new()), "Daño 2 · Cadencia 3 · Alcance 150 · Velocidad 90")


func test_rare_stats_show_only_when_they_have_something() -> void:
	var stats := StatBlock.new()
	stats.pierce = 1.0
	stats.damage = 2.55
	assert_eq(InventoryMenu.stats_text(stats), "Daño 2.55 · Cadencia 3 · Alcance 150 · Velocidad 90 · Perforación 1")


func test_modifiers_read_like_the_stats() -> void:
	var item := ItemData.new()
	var modifiers: Array[StatModifier] = [
		_modifier(&"damage", StatModifier.Op.ADD, 0.5),
		_modifier(&"fire_rate", StatModifier.Op.MULT, 1.2),
		_modifier(&"max_health", StatModifier.Op.ADD, 2.0),
	]
	item.modifiers = modifiers
	assert_eq(InventoryMenu.modifiers_text(item), "Daño +0.5 · Cadencia x1.2 · Vida +1 corazón")


func test_weapon_numbers_use_the_current_stats() -> void:
	assert_eq(InventoryMenu.weapon_stats_text(RunState.BASE_WEAPON, StatBlock.new()), "Daño 2 · 3 tiros/s · Alcance 150")
	var laser := load("res://content/weapons/haz.tres") as WeaponData
	assert_string_starts_with(InventoryMenu.weapon_stats_text(laser, StatBlock.new()), "Daño 9.6 por segundo")
