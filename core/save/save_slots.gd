class_name SaveSlots
extends RefCounted
## Los espacios de guardado: cuatro partidas independientes (slot_1.json a slot_4.json, cada una un
## MetaProfile con su progreso) y las opciones de todas (options.json), en una misma carpeta.
## `migrate_legacy` pasa el guardado de antes de las partidas (save.json) a la partida 1.

const COUNT: int = 4
const OPTIONS_FILE: String = "options.json"
const LEGACY_FILE: String = "save.json"
## El guardado viejo no se borra: queda con este agregado, por las dudas.
const LEGACY_BACKUP_SUFFIX: String = ".bak"



## Lo que se ve de una partida sin abrirla.
class Info:
	var used: bool = false
	## De 0 a 1 (MetaRules.completion).
	var completion: float = 0.0
	var runs: int = 0
	var wins: int = 0
	var sparks: int = 0


var dir: String


func _init(p_dir: String) -> void:
	dir = p_dir


## Archivo de la partida `slot` (1 a COUNT).
func slot_path(slot: int) -> String:
	return dir.path_join("slot_%d.json" % slot)


func options_path() -> String:
	return dir.path_join(OPTIONS_FILE)


func legacy_path() -> String:
	return dir.path_join(LEGACY_FILE)


## true si la partida tiene algo guardado.
func is_used(slot: int) -> bool:
	return has_file(slot_path(slot))


## Lo guardado en la partida (ya migrado), o vacío si no hay nada o está roto (ver SaveStore).
func read(slot: int) -> Dictionary:
	return SaveStore.new(slot_path(slot)).read()


func delete(slot: int) -> void:
	SaveStore.new(slot_path(slot)).delete()


## Si quedó un save.json de antes y ninguna partida tiene nada, lo pasa a la partida 1 y sus opciones
## a options.json (si todavía no hay). El viejo queda como save.json.bak. true si migró.
func migrate_legacy() -> bool:
	var legacy := SaveStore.new(legacy_path())
	if not has_file(legacy.path):
		return false
	for slot: int in range(1, COUNT + 1):
		if is_used(slot):
			return false
	var data: Dictionary = legacy.read()
	if data.is_empty():
		return false
	var options: Variant = data.get("options")
	if options is Dictionary and not has_file(options_path()):
		SaveStore.new(options_path()).write(GameOptions.from_dict(options as Dictionary).to_dict())
	data.erase("options")
	if SaveStore.new(slot_path(1)).write(data) != OK:
		return false
	if FileAccess.file_exists(legacy.path):
		DirAccess.rename_absolute(legacy.path, legacy.path + LEGACY_BACKUP_SUFFIX)
	if FileAccess.file_exists(legacy.path + SaveStore.TEMP_SUFFIX):
		DirAccess.remove_absolute(legacy.path + SaveStore.TEMP_SUFFIX)
	return true


## El archivo o el temporal completo que dejó un corte (SaveStore lo recupera al leer).
static func has_file(path: String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + SaveStore.TEMP_SUFFIX)
