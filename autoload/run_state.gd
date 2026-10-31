extends Node
## Estado de la run en curso: stats del jugador y cargas de Pulso.
## La vida vive en el HealthComponent del jugador.

signal stats_changed(stats: StatBlock)
signal blanks_changed(count: int)

## Cargas de Pulso al empezar la run.
const START_BLANKS: int = 2

var stats: StatBlock = StatBlock.new()
var blanks: int = START_BLANKS


func start_run() -> void:
	stats = StatBlock.new()
	blanks = START_BLANKS
	stats_changed.emit(stats)
	blanks_changed.emit(blanks)


## Gasta una carga de Pulso. Devuelve false si no quedaba ninguna.
func use_blank() -> bool:
	if blanks <= 0:
		return false
	blanks -= 1
	blanks_changed.emit(blanks)
	return true


func set_blanks(count: int) -> void:
	blanks = maxi(0, count)
	blanks_changed.emit(blanks)
