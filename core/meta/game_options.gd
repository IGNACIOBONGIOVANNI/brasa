class_name GameOptions
extends RefCounted
## Las opciones del juego, las mismas para todas las partidas: volumen general y de la música,
## pantalla completa, resolución y la última partida abierta. Pasan a y desde el diccionario de
## options.json; al leer toleran claves que falten y tipos raros (quedan en su valor por defecto).

## Versión del archivo de opciones (aparte de la del perfil, SaveSchema).
const VERSION: int = 1
const DEFAULT_MUSIC_VOLUME: float = 0.8

## Volumen general, de 0 a 1.
var volume: float = 1.0
## Volumen de la música, de 0 a 1 (encima del general).
var music_volume: float = DEFAULT_MUSIC_VOLUME
var fullscreen: bool = false
## Tamaño de la ventana en múltiplos de 320x180 (ver WindowScales).
var window_scale: int = WindowScales.DEFAULT_SCALE
## Última partida abierta (1 a SaveSlots.COUNT; 0 = ninguna): la pantalla de partidas arranca ahí.
var last_slot: int = 0


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"volume": volume,
		"music_volume": music_volume,
		"fullscreen": fullscreen,
		"window_scale": window_scale,
		"last_slot": last_slot,
	}


## También lee las opciones de un guardado de antes de las partidas (su clave "options").
static func from_dict(data: Dictionary) -> GameOptions:
	var options := GameOptions.new()
	var volume_value: Variant = data.get("volume")
	if _is_number(volume_value):
		options.volume = clampf(float(volume_value), 0.0, 1.0)
	var music_value: Variant = data.get("music_volume")
	if _is_number(music_value):
		options.music_volume = clampf(float(music_value), 0.0, 1.0)
	var fullscreen_value: Variant = data.get("fullscreen")
	options.fullscreen = typeof(fullscreen_value) == TYPE_BOOL and fullscreen_value
	var scale_value: Variant = data.get("window_scale")
	if _is_number(scale_value):
		options.window_scale = clampi(int(scale_value), WindowScales.MIN_SCALE, WindowScales.MAX_SCALE)
	var slot_value: Variant = data.get("last_slot")
	if _is_number(slot_value):
		options.last_slot = clampi(int(slot_value), 0, SaveSlots.COUNT)
	return options


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT
