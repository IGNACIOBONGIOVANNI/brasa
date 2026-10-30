class_name RngStreams
extends RefCounted
## Streams de aleatoriedad independientes derivados de una seed de run.
##
## Cada stream (piso, loot, combate, cosmético) tiene su propio RandomNumberGenerator.
## Su seed se deriva de (seed de la run, nombre del stream, índice de piso), así el piso N
## es idéntico con la misma seed sin importar cuánto se haya consumido de otros streams.

const FLOOR: StringName = &"floor"
const LOOT: StringName = &"loot"
const COMBAT: StringName = &"combat"
const COSMETIC: StringName = &"cosmetic"

const SEED_ARG_PREFIX: String = "--seed="

var run_seed: int
var floor_index: int = 0
var _streams: Dictionary[StringName, RandomNumberGenerator] = {}


func _init(seed_value: int) -> void:
	run_seed = seed_value


## Devuelve el stream pedido, creándolo la primera vez con su seed derivada.
func get_stream(stream_name: StringName) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		var rng := RandomNumberGenerator.new()
		rng.seed = derive_seed(run_seed, stream_name, floor_index)
		_streams[stream_name] = rng
	return _streams[stream_name]


## Pasa a otro piso: todos los streams se re-derivan para ese índice.
func set_floor(index: int) -> void:
	floor_index = index
	_streams.clear()


static func derive_seed(base_seed: int, stream_name: StringName, index: int) -> int:
	return hash([base_seed, String(stream_name), index])


## Seed nueva no determinista para empezar una run sin seed fija.
static func random_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()


## Busca "--seed=N" en los argumentos de usuario; si no está o no es un entero, devuelve fallback.
static func seed_from_args(args: PackedStringArray, fallback: int) -> int:
	for arg: String in args:
		if arg.begins_with(SEED_ARG_PREFIX):
			var value: String = arg.trim_prefix(SEED_ARG_PREFIX)
			if value.is_valid_int():
				return value.to_int()
	return fallback
