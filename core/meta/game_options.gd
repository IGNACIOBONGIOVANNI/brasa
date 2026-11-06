class_name GameOptions
extends RefCounted
## Las opciones del juego, las mismas para todas las partidas: volumen general y de la música,
## pantalla completa, resolución, cuánto tiembla la pantalla y la última partida abierta. Pasan a y desde el diccionario de
## options.json; al leer toleran claves que falten y tipos raros (quedan en su valor por defecto).

## Versión del archivo de opciones (aparte de la del perfil, SaveSchema).
const VERSION: int = 1
const DEFAULT_MUSIC_VOLUME: float = 0.8
## Cuánto tiembla la pantalla (explosiones, golpes, jefes): fuerte, suave o nada. Cada toque en Opciones
## pasa al siguiente.
const SHAKE_LEVELS: Array[float] = [1.0, 0.5, 0.0]
const SHAKE_NAMES: PackedStringArray = ["fuerte", "suave", "no"]

## Volumen general, de 0 a 1.
var volume: float = 1.0
## Volumen de la música, de 0 a 1 (encima del general).
var music_volume: float = DEFAULT_MUSIC_VOLUME
var fullscreen: bool = false
## Tamaño de la ventana en múltiplos de 320x180 (ver WindowScales).
var window_scale: int = WindowScales.DEFAULT_SCALE
## Multiplica el temblor de la cámara (uno de SHAKE_LEVELS).
var screen_shake: float = 1.0
## Última partida abierta (1 a SaveSlots.COUNT; 0 = ninguna): la pantalla de partidas arranca ahí.
var last_slot: int = 0


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"volume": volume,
		"music_volume": music_volume,
		"fullscreen": fullscreen,
		"window_scale": window_scale,
		"screen_shake": screen_shake,
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
	var shake_value: Variant = data.get("screen_shake")
	if _is_number(shake_value):
		options.screen_shake = nearest_shake(float(shake_value))
	var slot_value: Variant = data.get("last_slot")
	if _is_number(slot_value):
		options.last_slot = clampi(int(slot_value), 0, SaveSlots.COUNT)
	return options


## El nivel de temblor más cercano a `value` (así un archivo editado a mano no deja valores raros).
static func nearest_shake(value: float) -> float:
	var best: float = SHAKE_LEVELS[0]
	for level: float in SHAKE_LEVELS:
		if absf(level - value) < absf(best - value):
			best = level
	return best


## El nivel que sigue a `current` (después de "no" vuelve a "fuerte").
static func next_shake(current: float) -> float:
	var index: int = SHAKE_LEVELS.find(nearest_shake(current))
	return SHAKE_LEVELS[(index + 1) % SHAKE_LEVELS.size()]


static func shake_name(level: float) -> String:
	return SHAKE_NAMES[SHAKE_LEVELS.find(nearest_shake(level))]


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT
