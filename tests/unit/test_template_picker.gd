extends GutTest
## TemplatePicker: cada sala recibe una plantilla de su tipo, más difícil cuanto más lejos.


func _template(id: StringName, kind: RoomSlot.Kind, difficulty: int = 1) -> RoomTemplate:
	var template := RoomTemplate.new()
	template.id = id
	template.kind = kind
	template.difficulty = difficulty
	return template


func _templates() -> Array[RoomTemplate]:
	var templates: Array[RoomTemplate] = [
		_template(&"inicio", RoomSlot.Kind.START),
		_template(&"jefe", RoomSlot.Kind.BOSS),
		_template(&"tesoro", RoomSlot.Kind.TREASURE),
		_template(&"tienda", RoomSlot.Kind.SHOP),
		_template(&"secreta", RoomSlot.Kind.SECRET),
	]
	for difficulty: int in [1, 2, 3]:
		for i: int in 3:
			templates.append(_template(StringName("n%d_%d" % [difficulty, i]), RoomSlot.Kind.NORMAL, difficulty))
	return templates


func _layout(seed_value: int) -> FloorLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var layout: FloorLayout = FloorGenerator.generate(rng, FloorParams.new())
	TemplatePicker.assign(layout, _templates(), rng)
	return layout


func test_every_room_gets_a_template_of_its_kind() -> void:
	for seed_value: int in 50:
		var layout: FloorLayout = _layout(seed_value)
		for slot: RoomSlot in layout.slots.values():
			assert_not_null(slot.template)
			assert_eq(slot.template.kind, slot.kind)


func test_difficulty_grows_with_distance() -> void:
	assert_eq(TemplatePicker.difficulty_for(0, 6), 1, "al lado del inicio")
	assert_eq(TemplatePicker.difficulty_for(3, 6), 2, "a mitad de camino")
	assert_eq(TemplatePicker.difficulty_for(6, 6), 3, "lo más lejos")


func test_normal_rooms_never_exceed_target_difficulty() -> void:
	for seed_value: int in 50:
		var layout: FloorLayout = _layout(seed_value)
		var max_distance: int = 1
		for slot: RoomSlot in layout.slots.values():
			max_distance = maxi(max_distance, slot.distance)
		for slot: RoomSlot in layout.slots.values():
			if slot.kind == RoomSlot.Kind.NORMAL:
				assert_lte(slot.template.difficulty, TemplatePicker.difficulty_for(slot.distance, max_distance))


func test_same_seed_picks_same_templates() -> void:
	var first: FloorLayout = _layout(321)
	var second: FloorLayout = _layout(321)
	for cell: Vector2i in first.slots:
		assert_eq(first.get_slot(cell).template.id, second.get_slot(cell).template.id)
