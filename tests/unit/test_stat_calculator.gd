extends GutTest
## StatCalculator: base + ADD, por MULT, recortado; el orden de los items no importa.


func _item(modifiers: Array[StatModifier]) -> ItemData:
	var item := ItemData.new()
	item.modifiers = modifiers
	return item


func _mod(stat: StringName, op: StatModifier.Op, value: float) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat = stat
	modifier.op = op
	modifier.value = value
	return modifier


func _compute(items: Array[ItemData]) -> StatBlock:
	return StatCalculator.compute(StatBlock.new(), items)


func test_no_items_keeps_base_stats() -> void:
	var none: Array[ItemData] = []
	var stats: StatBlock = _compute(none)
	var base := StatBlock.new()
	for stat: StringName in StatBlock.STAT_NAMES:
		assert_almost_eq(float(stats.get(stat)), float(base.get(stat)), 0.0001, "stat %s" % stat)


func test_adds_then_multiplies() -> void:
	var items: Array[ItemData] = [
		_item([_mod(&"damage", StatModifier.Op.ADD, 1.0)]),
		_item([_mod(&"damage", StatModifier.Op.MULT, 1.5)]),
		_item([_mod(&"damage", StatModifier.Op.ADD, 1.0)]),
	]
	# (2 + 1 + 1) × 1.5 = 6
	assert_almost_eq(_compute(items).damage, 6.0, 0.0001)


func test_order_does_not_matter() -> void:
	var a: ItemData = _item([_mod(&"fire_rate", StatModifier.Op.MULT, 1.4), _mod(&"damage", StatModifier.Op.MULT, 0.8)])
	var b: ItemData = _item([_mod(&"damage", StatModifier.Op.ADD, 1.0)])
	var c: ItemData = _item([_mod(&"fire_rate", StatModifier.Op.ADD, 0.5)])
	var first: Array[ItemData] = [a, b, c]
	var reference: StatBlock = _compute(first)
	var orders: Array[Array] = [[b, c, a], [c, a, b], [a, c, b]]
	for order: Array in orders:
		var typed: Array[ItemData] = []
		typed.assign(order)
		var stats: StatBlock = _compute(typed)
		assert_almost_eq(stats.damage, reference.damage, 0.0001)
		assert_almost_eq(stats.fire_rate, reference.fire_rate, 0.0001)


func test_limits_are_applied() -> void:
	var items: Array[ItemData] = [
		_item([_mod(&"bounces", StatModifier.Op.ADD, 50.0), _mod(&"move_speed", StatModifier.Op.MULT, 0.0)]),
	]
	var stats: StatBlock = _compute(items)
	assert_eq(stats.bounces, StatCalculator.LIMITS[&"bounces"].y, "rebotes topeados")
	assert_eq(stats.move_speed, StatCalculator.LIMITS[&"move_speed"].x, "velocidad con mínimo")


func test_every_stat_has_limits() -> void:
	for stat: StringName in StatBlock.STAT_NAMES:
		assert_true(StatCalculator.LIMITS.has(stat), "límites de %s" % stat)
		assert_true(stat in StatBlock.new(), "StatBlock tiene %s" % stat)


func test_base_is_not_modified() -> void:
	var base := StatBlock.new()
	var items: Array[ItemData] = [_item([_mod(&"damage", StatModifier.Op.ADD, 5.0)])]
	StatCalculator.compute(base, items)
	assert_eq(base.damage, 2.0)
