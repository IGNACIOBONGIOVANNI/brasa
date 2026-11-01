extends GutTest
## RulePicker y RoomRule: la Prueba siempre tiene regla, las salas normales solo lejos del inicio y
## con su probabilidad, misma seed = mismas reglas; Contrarreloj da el premio solo a tiempo.


func _rule(id: StringName) -> RoomRule:
	var rule := RoomRule.new()
	rule.id = id
	return rule


## Un pasillo: inicio, cuatro salas normales (distancias 1 a 4) y una Prueba al final.
func _layout() -> FloorLayout:
	var layout := FloorLayout.new()
	layout.grid_size = Vector2i(9, 8)
	layout.start = Vector2i(0, 0)
	layout.slots[layout.start] = RoomSlot.new(layout.start, RoomSlot.Kind.START)
	for i: int in range(1, 6):
		var kind: RoomSlot.Kind = RoomSlot.Kind.CHALLENGE if i == 5 else RoomSlot.Kind.NORMAL
		var slot := RoomSlot.new(Vector2i(i, 0), kind)
		slot.distance = i
		layout.slots[slot.cell] = slot
	return layout


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_challenge_always_gets_a_rule_and_near_rooms_never() -> void:
	var rules: Array[RoomRule] = [_rule(&"a"), _rule(&"b")]
	var layout: FloorLayout = _layout()
	RulePicker.assign(layout, rules, 0.0, _rng(1))
	assert_not_null(layout.get_slot(Vector2i(5, 0)).rule, "la Prueba siempre")
	for i: int in range(1, 5):
		assert_null(layout.get_slot(Vector2i(i, 0)).rule, "con chance 0 ninguna normal")
	layout = _layout()
	RulePicker.assign(layout, rules, 1.0, _rng(1))
	assert_null(layout.get_slot(layout.start).rule, "el inicio nunca")
	assert_null(layout.get_slot(Vector2i(1, 0)).rule, "la vecina del inicio tampoco")
	for i: int in range(RulePicker.MIN_DISTANCE, 5):
		assert_not_null(layout.get_slot(Vector2i(i, 0)).rule, "con chance 1, la sala a %d pasos" % i)


func test_same_seed_same_rules() -> void:
	var rules: Array[RoomRule] = [_rule(&"a"), _rule(&"b"), _rule(&"c")]
	var first: FloorLayout = _layout()
	var second: FloorLayout = _layout()
	RulePicker.assign(first, rules, 0.5, _rng(77))
	RulePicker.assign(second, rules, 0.5, _rng(77))
	for cell: Vector2i in first.slots:
		assert_eq(first.get_slot(cell).rule, second.get_slot(cell).rule, "sala %s" % cell)


func test_without_rules_nothing_happens() -> void:
	var none: Array[RoomRule] = []
	var layout: FloorLayout = _layout()
	RulePicker.assign(layout, none, 1.0, _rng(3))
	assert_null(layout.get_slot(Vector2i(5, 0)).rule)


func test_time_limit_decides_the_bonus() -> void:
	var rule: RoomRule = _rule(&"reloj")
	assert_true(rule.earns_bonus(999.0), "sin límite siempre")
	rule.time_limit = 30.0
	assert_true(rule.earns_bonus(29.5))
	assert_false(rule.earns_bonus(30.5), "tarde no")
