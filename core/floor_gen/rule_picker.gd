class_name RulePicker
extends RefCounted
## Sortea las reglas de las salas de un piso (con el stream FLOOR). La Prueba siempre tiene una;
## las salas normales, con probabilidad `chance` si están a `min_distance` pasos o más del inicio
## (las primeras quedan tranquilas). Lógica pura: misma seed, mismas reglas.

const MIN_DISTANCE: int = 2


static func assign(layout: FloorLayout, rules: Array[RoomRule], chance: float, rng: RandomNumberGenerator,
		min_distance: int = MIN_DISTANCE) -> void:
	if rules.is_empty():
		return
	for slot: RoomSlot in layout.slots.values():
		var wants_rule: bool = false
		if slot.kind == RoomSlot.Kind.CHALLENGE:
			wants_rule = true
		elif slot.kind == RoomSlot.Kind.NORMAL and slot.distance >= min_distance:
			wants_rule = rng.randf() < chance
		if wants_rule:
			slot.rule = rules[rng.randi_range(0, rules.size() - 1)]
