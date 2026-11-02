class_name MetaProfile
extends RefCounted
## El progreso de una partida (lo que se guarda en su espacio): chispas, items y personajes
## desbloqueados, logros, el último personaje elegido, si vio la intro y los totales de todas las
## runs. Las opciones van aparte (GameOptions). Pasa a y desde el diccionario del guardado; al leer
## tolera claves que falten y tipos raros (quedan en su valor por defecto).


## Lo que dejó una run terminada (para el resumen).
class RunRewards:
	var sparks: int = 0
	var achievements: Array[AchievementData] = []


var sparks: int = 0
var unlocked_items: Dictionary[StringName, bool] = {}
var unlocked_characters: Dictionary[StringName, bool] = {}
var achievements: Dictionary[StringName, bool] = {}
var last_character: StringName = &""
var runs: int = 0
var wins: int = 0
var total_kills: int = 0
## Ya vio la intro de la historia (se muestra la primera vez que se aprieta Jugar).
var intro_seen: bool = false
## Capítulos (RunConfig.id) cuya intro ya vio, sin contar el primero (ese es `intro_seen`).
var seen_intros: Dictionary[StringName, bool] = {}


func is_item_available(item: ItemData) -> bool:
	return not item.locked or unlocked_items.has(item.id)


func is_character_available(character: CharacterData) -> bool:
	return not character.locked or unlocked_characters.has(character.id)


## Los de `items` que pueden salir en una run.
func available_items(items: Array[ItemData]) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item: ItemData in items:
		if is_item_available(item):
			result.append(item)
	return result


func has_achievement(achievement: AchievementData) -> bool:
	return achievements.has(achievement.id)


## Se puede comprar en el Taller: se vende, todavía no está y alcanzan las chispas.
func can_buy(item: ItemData) -> bool:
	return item.unlock_cost > 0 and not is_item_available(item) and sparks >= item.unlock_cost


## Lo compra en el Taller. Devuelve false si no se podía.
func buy(item: ItemData) -> bool:
	if not can_buy(item):
		return false
	sparks -= item.unlock_cost
	unlocked_items[item.id] = true
	return true


## Suma una run terminada: chispas, totales y los logros que se cumplieron por primera vez (con lo
## que desbloquean).
func record_run(record: RunRecord, all_achievements: Array[AchievementData]) -> RunRewards:
	var rewards := RunRewards.new()
	rewards.sparks = MetaRules.sparks_for(record)
	sparks += rewards.sparks
	runs += 1
	if record.victory:
		wins += 1
	total_kills += record.kills
	for achievement: AchievementData in all_achievements:
		if has_achievement(achievement) or not MetaRules.is_met(achievement, self, record):
			continue
		achievements[achievement.id] = true
		for item: ItemData in achievement.unlock_items:
			unlocked_items[item.id] = true
		for character: CharacterData in achievement.unlock_characters:
			unlocked_characters[character.id] = true
		rewards.achievements.append(achievement)
	return rewards


## Repone lo que desbloquean los logros que ya tiene (un logro puede desbloquear algo nuevo en una
## versión más nueva del juego). Devuelve si cambió algo.
func sync_unlocks(all_achievements: Array[AchievementData]) -> bool:
	var changed: bool = false
	for achievement: AchievementData in all_achievements:
		if not has_achievement(achievement):
			continue
		for item: ItemData in achievement.unlock_items:
			if not unlocked_items.has(item.id):
				unlocked_items[item.id] = true
				changed = true
		for character: CharacterData in achievement.unlock_characters:
			if not unlocked_characters.has(character.id):
				unlocked_characters[character.id] = true
				changed = true
	return changed


## Si vio la intro del capítulo (la del primero es `intro_seen`).
func has_seen_intro(chapter_id: StringName, first: bool) -> bool:
	return intro_seen if first else seen_intros.has(chapter_id)


func to_dict() -> Dictionary:
	return {
		"version": SaveSchema.VERSION,
		"sparks": sparks,
		"unlocked_items": _ids(unlocked_items),
		"unlocked_characters": _ids(unlocked_characters),
		"achievements": _ids(achievements),
		"last_character": String(last_character),
		"totals": {"runs": runs, "wins": wins, "kills": total_kills},
		"intro_seen": intro_seen,
		"seen_intros": _ids(seen_intros),
	}


static func from_dict(data: Dictionary) -> MetaProfile:
	var profile := MetaProfile.new()
	profile.sparks = maxi(0, _int(data, "sparks"))
	profile.unlocked_items = _id_set(data.get("unlocked_items"))
	profile.unlocked_characters = _id_set(data.get("unlocked_characters"))
	profile.achievements = _id_set(data.get("achievements"))
	var last: Variant = data.get("last_character")
	if last is String:
		profile.last_character = StringName(last as String)
	var totals: Variant = data.get("totals")
	if totals is Dictionary:
		profile.runs = maxi(0, _int(totals, "runs"))
		profile.wins = maxi(0, _int(totals, "wins"))
		profile.total_kills = maxi(0, _int(totals, "kills"))
	var intro_value: Variant = data.get("intro_seen")
	profile.intro_seen = typeof(intro_value) == TYPE_BOOL and intro_value
	profile.seen_intros = _id_set(data.get("seen_intros"))
	return profile


## El JSON guarda los números como float.
static func _int(source: Dictionary, key: String) -> int:
	var value: Variant = source.get(key)
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value)
	return 0


static func _id_set(value: Variant) -> Dictionary[StringName, bool]:
	var result: Dictionary[StringName, bool] = {}
	if value is Array:
		for entry: Variant in value as Array:
			if entry is String and not (entry as String).is_empty():
				result[StringName(entry as String)] = true
	return result


## Ordenados, así el archivo no cambia de orden entre guardadas.
static func _ids(ids: Dictionary[StringName, bool]) -> Array[String]:
	var result: Array[String] = []
	for id: StringName in ids:
		result.append(String(id))
	result.sort()
	return result
