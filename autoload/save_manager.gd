extends Node
## El progreso entre runs: el MetaProfile y su archivo. Arranca en memoria (perfil nuevo, sin disco)
## hasta que Main llama a `open()` con la ruta del guardado. Guarda después de cada cambio: run
## terminada, compra en el Taller, personaje elegido, opciones. También aplica las opciones (volumen
## del bus Master y pantalla completa).
## Los tests lo dejan siempre en memoria (tests/pre_run_hook.gd) para no tocar el guardado real.

signal profile_changed

const DEFAULT_PATH: String = "user://save.json"
const MASTER_BUS: int = 0
## Lo que ocupan la barra de título y los bordes de la ventana (no entra en el lugar libre del monitor).
const WINDOW_DECORATION: Vector2i = Vector2i(16, 40)
## Pantalla que se supone sin monitor (tests y corridas headless).
const HEADLESS_SCREEN: Vector2i = Vector2i(1920, 1040)

var profile: MetaProfile = MetaProfile.new()
var config: MetaConfig
## Archivo del perfil; vacío = solo en memoria.
var path: String = ""
var _store: SaveStore
var _memory_only: bool = false


func _ready() -> void:
	config = MetaConfig.get_default()


## Abre el perfil guardado en `save_path` (si no existe, uno nuevo que se va a guardar ahí). Con
## una ruta vacía, perfil nuevo solo en memoria.
func open(save_path: String) -> void:
	profile = MetaProfile.new()
	path = "" if _memory_only else save_path
	_store = null
	if not path.is_empty():
		_store = SaveStore.new(path)
		var data: Dictionary = _store.read()
		match _store.status:
			SaveStore.Status.CORRUPT:
				push_warning("El guardado %s estaba roto: quedó aparte (%s) y se empieza de cero." % [path, SaveStore.CORRUPT_SUFFIX])
			SaveStore.Status.TOO_NEW:
				push_warning("El guardado %s es de una versión más nueva del juego: no se va a guardar nada encima." % path)
				_store = null
		if not data.is_empty():
			profile = MetaProfile.from_dict(data)
	apply_options()
	profile_changed.emit()


## A partir de acá nunca toca el disco (los tests lo llaman antes de correr).
func use_memory_only() -> void:
	_memory_only = true
	open("")


func is_persistent() -> bool:
	return _store != null


func save() -> void:
	if _store == null:
		return
	var error: Error = _store.write(profile.to_dict())
	if error != OK:
		push_warning("No se pudo guardar el progreso en %s (error %d)." % [path, error])


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


func set_volume(volume: float) -> void:
	profile.volume = clampf(volume, 0.0, 1.0)
	apply_options()
	_changed()


func mark_intro_seen() -> void:
	if profile.intro_seen:
		return
	profile.intro_seen = true
	_changed()


func set_fullscreen(fullscreen: bool) -> void:
	profile.fullscreen = fullscreen
	apply_options()
	_changed()


func set_window_scale(scale: int) -> void:
	profile.window_scale = scale
	apply_options()
	_changed()


## Las escalas de ventana que entran en el monitor (sin pantalla, como en un monitor de 1080p).
func available_window_scales() -> Array[int]:
	if DisplayServer.get_name() == "headless":
		return WindowScales.available(HEADLESS_SCREEN)
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	return WindowScales.available(usable.size - WINDOW_DECORATION)


## El tamaño de ventana que se usa de verdad: el elegido, o el más grande que entre si no entra.
func window_size() -> Vector2i:
	return WindowScales.size_of(WindowScales.fit(profile.window_scale, available_window_scales()))


## Lleva las opciones del perfil al audio y a la ventana.
func apply_options() -> void:
	AudioServer.set_bus_mute(MASTER_BUS, profile.volume <= 0.0)
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(maxf(profile.volume, 0.0001)))
	if DisplayServer.get_name() == "headless":
		return
	var current: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var is_fullscreen: bool = current == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or current == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if is_fullscreen != profile.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if profile.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if profile.fullscreen:
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
	var catalog := load(RunState.CATALOG_PATH) as ItemCatalog
	for item: ItemData in catalog.items:
		if item.locked:
			profile.unlocked_items[item.id] = true
	for character: CharacterData in config.characters:
		if character.locked:
			profile.unlocked_characters[character.id] = true
	_changed()


## Menú de debug: perfil nuevo (se guarda vacío). Las opciones se mantienen.
func reset_progress() -> void:
	var previous: MetaProfile = profile
	profile = MetaProfile.new()
	profile.volume = previous.volume
	profile.fullscreen = previous.fullscreen
	profile.window_scale = previous.window_scale
	_changed()


func _changed() -> void:
	save()
	profile_changed.emit()
