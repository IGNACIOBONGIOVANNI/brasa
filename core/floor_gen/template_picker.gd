class_name TemplatePicker
extends RefCounted
## Elige la plantilla de cada sala del piso. Las salas normales son más difíciles cuanto más lejos
## están del inicio, y no se repite una plantilla mientras haya otras de esa dificultad.

const MAX_DIFFICULTY: int = 3


## `difficulty_bonus` sube la dificultad de todas las salas normales (pisos más avanzados).
static func assign(layout: FloorLayout, templates: Array[RoomTemplate], rng: RandomNumberGenerator,
		difficulty_bonus: int = 0) -> void:
	var max_distance: int = 1
	for slot: RoomSlot in layout.slots.values():
		max_distance = maxi(max_distance, slot.distance)
	var used: Dictionary[RoomTemplate, bool] = {}
	for slot: RoomSlot in layout.slots.values():
		var target: int = mini(MAX_DIFFICULTY, difficulty_for(slot.distance, max_distance) + difficulty_bonus)
		var candidates: Array[RoomTemplate] = _candidates(templates, slot.kind, target, used)
		if candidates.is_empty():
			push_error("TemplatePicker: no hay plantillas del tipo %d" % slot.kind)
			continue
		slot.template = candidates[rng.randi_range(0, candidates.size() - 1)]
		used[slot.template] = true


## Dificultad buscada para una sala normal: 1 cerca del inicio, MAX_DIFFICULTY cerca de lo más lejano.
static func difficulty_for(distance: int, max_distance: int) -> int:
	return clampi(1 + floori(MAX_DIFFICULTY * float(distance) / (max_distance + 1)), 1, MAX_DIFFICULTY)


## Plantillas posibles, de la opción preferida a la de último recurso.
static func _candidates(templates: Array[RoomTemplate], kind: RoomSlot.Kind, target: int,
		used: Dictionary[RoomTemplate, bool]) -> Array[RoomTemplate]:
	var of_kind: Array[RoomTemplate] = []
	for template: RoomTemplate in templates:
		if template.kind == kind:
			of_kind.append(template)
	if kind != RoomSlot.Kind.NORMAL:
		return of_kind
	var tiers: Array[Callable] = [
		func(t: RoomTemplate) -> bool: return t.difficulty == target and not used.has(t),
		func(t: RoomTemplate) -> bool: return t.difficulty == target,
		func(t: RoomTemplate) -> bool: return t.difficulty <= target and not used.has(t),
		func(t: RoomTemplate) -> bool: return t.difficulty <= target,
	]
	for accepts: Callable in tiers:
		var result: Array[RoomTemplate] = []
		for template: RoomTemplate in of_kind:
			if accepts.call(template):
				result.append(template)
		if not result.is_empty():
			return result
	return of_kind
