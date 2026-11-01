class_name MetaProfile
extends RefCounted
## El progreso entre runs (lo que se guarda): chispas, items y personajes desbloqueados, logros, el
## último personaje elegido, los totales de todas las runs y las opciones (volumen, música, pantalla completa, resolución). Pasa a y desde el diccionario del
## guardado; al leer tolera claves que falten y tipos raros (quedan en su valor por defecto).


## Lo que dejó una run terminada (para el resumen).
const DEFAULT_MUSIC_VOLUME: float = 0.8


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
## Volumen general, de 0 a 1.
var volume: float = 1.0
## Volumen de la música, de 0 a 1 (encima del general).
var music_volume: float = DEFAULT_MUSIC_VOLUME
var fullscreen: bool = false
## Tamaño de la ventana en múltiplos de 320x180 (ver WindowScales).
var window_scale: int = WindowScales.DEFAULT_SCALE
## Ya vio la intro de la historia (se muestra la primera vez que se aprieta Jugar).
var intro_seen: bool = false


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


func to_dict() -> Dictionary:
	return {
		"version": SaveSchema.VERSION,
		"sparks": sparks,
		"unlocked_items": _ids(unlocked_items),
		"unlocked_characters": _ids(unlocked_characters),
		"achievements": _ids(achievements),
		"last_character": String(last_character),
		"totals": {"runs": runs, "wins": wins, "kills": total_kills},
		"options": {"volume": volume, "music_volume": music_volume, "fullscreen": fullscreen, "window_scale": window_scale},
		"intro_seen": intro_seen,
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
	var options: Variant = data.get("options")
	if options is Dictionary:
		var volume_value: Variant = (options as Dictionary).get("volume")
		if typeof(volume_value) == TYPE_FLOAT or typeof(volume_value) == TYPE_INT:
			profile.volume = clampf(float(volume_value), 0.0, 1.0)
		var music_value: Variant = (options as Dictionary).get("music_volume")
		if typeof(music_value) == TYPE_FLOAT or typeof(music_value) == TYPE_INT:
			profile.music_volume = clampf(float(music_value), 0.0, 1.0)
		var fullscreen_value: Variant = (options as Dictionary).get("fullscreen")
		profile.fullscreen = typeof(fullscreen_value) == TYPE_BOOL and fullscreen_value
		var scale_value: Variant = (options as Dictionary).get("window_scale")
		if typeof(scale_value) == TYPE_FLOAT or typeof(scale_value) == TYPE_INT:
			profile.window_scale = clampi(int(scale_value), WindowScales.MIN_SCALE, WindowScales.MAX_SCALE)
	var intro_value: Variant = data.get("intro_seen")
	profile.intro_seen = typeof(intro_value) == TYPE_BOOL and intro_value
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
