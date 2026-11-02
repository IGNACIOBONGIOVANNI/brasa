extends Node
## El guardado: las cuatro partidas (SaveSlots), la que está abierta (su MetaProfile y su archivo) y
## las opciones, que son las mismas para todas (GameOptions, en options.json). Arranca todo en
## memoria hasta que Main llama a `use_slots()` con la carpeta (o a `open()` con un archivo suelto).
## La partida abierta se guarda después de cada cambio (run terminada, compra en el Taller, personaje
## elegido); las opciones, al cambiarlas. También aplica las opciones (volumen del bus Master, de la
## música, pantalla completa y resolución).
## Los tests lo dejan en memoria (tests/pre_run_hook.gd): la carpeta real nunca se toca.
## Cada guardado tiene al lado su run a medias (RunSnapshot, `save_run` / `load_run` / `clear_run`):
## slot_N_run.json, o en memoria si el perfil está en memoria.

## Cambió la partida abierta, su progreso o las opciones (los menús se rearman).
signal profile_changed

## Carpeta del guardado real (partidas y opciones).
const DEFAULT_DIR: String = "user://"
const MASTER_BUS: int = 0
## Lo que ocupan la barra de título y los bordes de la ventana (no entra en el lugar libre del monitor).
const WINDOW_DECORATION: Vector2i = Vector2i(16, 40)
## Pantalla que se supone sin monitor (tests y corridas headless).
const HEADLESS_SCREEN: Vector2i = Vector2i(1920, 1040)


var profile: MetaProfile = MetaProfile.new()
var options: GameOptions = GameOptions.new()
var config: MetaConfig
## Partida abierta (1 a SaveSlots.COUNT); 0 = ninguna (archivo suelto, memoria o la pantalla de
## partidas).
var slot: int = 0
## Las partidas en disco; null = sin disco (todo en memoria).
var slots: SaveSlots = null
## Archivo del perfil abierto; vacío = solo en memoria.
var path: String = ""
var _store: SaveStore
var _run_store: SaveStore
## La run a medias cuando no hay archivo (memoria, tests).
var _memory_run: Dictionary = {}
var _options_store: SaveStore
var _memory_only: bool = false
var _catalog: ItemCatalog


func _ready() -> void:
	config = MetaConfig.get_default()
	_catalog = load(RunState.CATALOG_PATH) as ItemCatalog


## Usa las partidas y las opciones de la carpeta `dir` ("" = todo en memoria, sin partidas). Lee las
## opciones y las aplica; no abre ninguna partida (el perfil queda nuevo, en memoria, hasta
## `open_slot`). Si quedó un guardado de antes de las partidas, pasa a ser la partida 1.
func use_slots(dir: String) -> void:
	if _memory_only and _is_real(dir.path_join(SaveSlots.OPTIONS_FILE)):
		dir = ""
	slots = null
	_options_store = null
	options = GameOptions.new()
	if not dir.is_empty():
		slots = SaveSlots.new(dir)
		slots.migrate_legacy()
		_options_store = SaveStore.new(slots.options_path())
		_options_store.steps.clear()
		var data: Dictionary = _options_store.read()
		if _options_store.status == SaveStore.Status.TOO_NEW:
			_options_store = null
		elif not data.is_empty():
			options = GameOptions.from_dict(data)
	apply_options()
	open("")


func has_slots() -> bool:
	return slots != null


## Abre la partida `slot_index` (si está vacía, empieza de cero y se crea al guardar algo).
func open_slot(slot_index: int) -> void:
	open(slots.slot_path(slot_index))
	slot = slot_index
	options.last_slot = slot_index
	_save_options()


## Cierra la partida abierta (para volver a la pantalla de partidas).
func close_slot() -> void:
	open("")


## La partida a la que vuelve el juego: la última abierta, o la 1.
func last_slot() -> int:
	return options.last_slot if options.last_slot > 0 else 1


## Progreso de la partida `slot_index` sin abrirla (la abierta, con lo que tiene en memoria).
func slot_info(slot_index: int) -> SaveSlots.Info:
	var info := SaveSlots.Info.new()
	var slot_profile: MetaProfile = profile
	if slot_index != slot:
		if slots == null or not slots.is_used(slot_index):
			return info
		slot_profile = MetaProfile.from_dict(slots.read(slot_index))
	info.used = slot_index != slot or _store_has_file()
	info.completion = completion_of(slot_profile)
	info.runs = slot_profile.runs
	info.wins = slot_profile.wins
	info.sparks = slot_profile.sparks
	return info


## Borra la partida `slot_index` (si es la abierta, queda cerrada).
func delete_slot(slot_index: int) -> void:
	if slots == null:
		return
	if slot_index == slot:
		close_slot()
	slots.delete(slot_index)
	profile_changed.emit()


## Cuánto de la partida abierta está hecho (0 a 1).
func completion() -> float:
	return completion_of(profile)


func completion_of(some_profile: MetaProfile) -> float:
	return MetaRules.completion(some_profile, config.achievements, config.characters, _catalog.items)


## Abre el perfil guardado en `save_path` (si no existe, uno nuevo que se va a guardar ahí), sin
## partida. Con una ruta vacía, perfil nuevo solo en memoria.
func open(save_path: String) -> void:
	profile = MetaProfile.new()
	slot = 0
	path = "" if _memory_only and _is_real(save_path) else save_path
	_store = null
	_run_store = null
	_memory_run = {}
	if not path.is_empty():
		_store = SaveStore.new(path)
		_run_store = SaveStore.new(SaveSlots.run_path_for(path))
		_run_store.steps.clear()
		var data: Dictionary = _store.read()
		match _store.status:
			SaveStore.Status.CORRUPT:
				push_warning("El guardado %s estaba roto: quedó aparte (%s) y se empieza de cero." % [path, SaveStore.CORRUPT_SUFFIX])
			SaveStore.Status.TOO_NEW:
				push_warning("El guardado %s es de una versión más nueva del juego: no se va a guardar nada encima." % path)
				_store = null
				_run_store = null
		if not data.is_empty():
			profile = MetaProfile.from_dict(data)
	profile_changed.emit()


## A partir de acá nunca toca la carpeta del guardado real (los tests lo llaman antes de correr).
func use_memory_only() -> void:
	_memory_only = true
	use_slots("")


func is_persistent() -> bool:
	return _store != null


func save() -> void:
	if _store == null:
		return
	var error: Error = _store.write(profile.to_dict())
	if error != OK:
		push_warning("No se pudo guardar el progreso en %s (error %d)." % [path, error])


## true si la partida abierta tiene una run a medias.
func has_saved_run() -> bool:
	if _run_store == null:
		return not _memory_run.is_empty()
	return SaveSlots.has_file(_run_store.path)


## Guarda la run a medias (RunSnapshot.to_dict) de la partida abierta.
func save_run(data: Dictionary) -> void:
	if _run_store == null:
		_memory_run = data.duplicate(true)
		return
	var error: Error = _run_store.write(data)
	if error != OK:
		push_warning("No se pudo guardar la run en %s (error %d)." % [_run_store.path, error])


## La run a medias guardada (vacío si no hay o no se puede leer).
func load_run() -> Dictionary:
	if _run_store == null:
		return _memory_run.duplicate(true)
	return _run_store.read()


## Borra la run a medias (terminó, se abandonó o se empezó otra).
func clear_run() -> void:
	_memory_run = {}
	if _run_store != null:
		_run_store.delete()


## Suma la run terminada, guarda y devuelve lo ganado.
func record_run(record: RunRecord) -> MetaProfile.RunRewards:
	var rewards: MetaProfile.RunRewards = profile.record_run(record, config.achievements)
	_changed()
	return rewards


## Compra un item en el Taller. Devuelve false si no se podía.
func buy(item: ItemData) -> bool:
	if not profile.buy(item):
		return false
	_changed()
	return true


## El último personaje elegido (o el de por defecto si no hay o ya no está disponible).
func selected_character() -> CharacterData:
	var character: CharacterData = config.character_by_id(profile.last_character)
	if character == null or not profile.is_character_available(character):
		return config.default_character()
	return character


func select_character(character: CharacterData) -> void:
	if profile.last_character == character.id:
		return
	profile.last_character = character.id
	_changed()


func mark_intro_seen() -> void:
	if profile.intro_seen:
		return
	profile.intro_seen = true
	_changed()


func set_volume(volume: float) -> void:
	options.volume = clampf(volume, 0.0, 1.0)
	_options_changed()


func set_music_volume(volume: float) -> void:
	options.music_volume = clampf(volume, 0.0, 1.0)
	_options_changed()


func set_fullscreen(fullscreen: bool) -> void:
	options.fullscreen = fullscreen
	_options_changed()


func set_window_scale(scale: int) -> void:
	options.window_scale = scale
	_options_changed()


## Las escalas de ventana que entran en el monitor (sin pantalla, como en un monitor de 1080p).
func available_window_scales() -> Array[int]:
	if DisplayServer.get_name() == "headless":
		return WindowScales.available(HEADLESS_SCREEN)
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	return WindowScales.available(usable.size - WINDOW_DECORATION)


## El tamaño de ventana que se usa de verdad: el elegido, o el más grande que entre si no entra.
func window_size() -> Vector2i:
	return WindowScales.size_of(WindowScales.fit(options.window_scale, available_window_scales()))


## Lleva las opciones al audio y a la ventana.
func apply_options() -> void:
	AudioServer.set_bus_mute(MASTER_BUS, options.volume <= 0.0)
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(maxf(options.volume, 0.0001)))
	AudioManager.set_music_volume(options.music_volume)
	if DisplayServer.get_name() == "headless":
		return
	var current: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var is_fullscreen: bool = current == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or current == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if is_fullscreen != options.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if options.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if options.fullscreen:
		return
	# En ventana: el tamaño elegido, centrada en el monitor.
	var size: Vector2i = window_size()
	if DisplayServer.window_get_size() != size:
		DisplayServer.window_set_size(size)
		var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		DisplayServer.window_set_position(usable.position + Vector2i(Vector2(usable.size - size) * 0.5))


## Menú de debug.
func add_sparks(amount: int) -> void:
	profile.sparks += amount
	_changed()


## Menú de debug: todos los items y personajes disponibles (los logros quedan como estaban).
func unlock_everything() -> void:
	for item: ItemData in _catalog.items:
		if item.locked:
			profile.unlocked_items[item.id] = true
	for character: CharacterData in config.characters:
		if character.locked:
			profile.unlocked_characters[character.id] = true
	_changed()


## Menú de debug: la partida abierta vuelve a cero (se guarda vacía).
func reset_progress() -> void:
	profile = MetaProfile.new()
	_changed()


func _changed() -> void:
	save()
	profile_changed.emit()


func _options_changed() -> void:
	apply_options()
	_save_options()
	profile_changed.emit()


func _save_options() -> void:
	if _options_store == null:
		return
	var error: Error = _options_store.write(options.to_dict())
	if error != OK:
		push_warning("No se pudieron guardar las opciones en %s (error %d)." % [_options_store.path, error])


## true si el perfil abierto ya tiene archivo (una partida recién elegida no lo tiene hasta guardar).
func _store_has_file() -> bool:
	return _store != null and SaveSlots.has_file(_store.path)


## Un archivo de la carpeta del guardado real (no de una subcarpeta, como las de los tests).
static func _is_real(file_path: String) -> bool:
	return file_path.begins_with(DEFAULT_DIR) and not file_path.trim_prefix(DEFAULT_DIR).contains("/")
