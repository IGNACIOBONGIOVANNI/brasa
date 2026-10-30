extends Node
## Fuente única de aleatoriedad del juego. Nunca usar randf()/randi() globales.
##
## Al arrancar toma la seed de "-- --seed=N" si se pasó por línea de comandos; si no, una al azar.

var _streams: RngStreams = RngStreams.new(
	RngStreams.seed_from_args(OS.get_cmdline_user_args(), RngStreams.random_seed())
)


func start_run(run_seed: int) -> void:
	_streams = RngStreams.new(run_seed)


func get_run_seed() -> int:
	return _streams.run_seed


func set_floor(index: int) -> void:
	_streams.set_floor(index)


## Stream con nombre: RngStreams.FLOOR, LOOT, COMBAT o COSMETIC.
func stream(stream_name: StringName) -> RandomNumberGenerator:
	return _streams.get_stream(stream_name)
