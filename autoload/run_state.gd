extends Node
## Estado de la run en curso. Hito 1: solo los stats del jugador.

signal stats_changed(stats: StatBlock)

var stats: StatBlock = StatBlock.new()


func start_run() -> void:
	stats = StatBlock.new()
	stats_changed.emit(stats)
