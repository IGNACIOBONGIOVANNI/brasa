extends Node
## Estado de la run en curso: stats del jugador, cargas de Pulso y monedas, bombas y llaves.
## La vida vive en el HealthComponent del jugador.

signal stats_changed(stats: StatBlock)
signal blanks_changed(count: int)
signal inventory_changed(coins: int, bombs: int, keys: int)

## Cargas de Pulso al empezar la run.
const START_BLANKS: int = 2
const START_BOMBS: int = 1
const MAX_COUNT: int = 99

var stats: StatBlock = StatBlock.new()
var blanks: int = START_BLANKS
var coins: int = 0
var bombs: int = START_BOMBS
var keys: int = 0


func start_run() -> void:
	stats = StatBlock.new()
	blanks = START_BLANKS
	coins = 0
	bombs = START_BOMBS
	keys = 0
	stats_changed.emit(stats)
	blanks_changed.emit(blanks)
	_inventory_changed()


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


## Gasta una bomba. Devuelve false si no quedaba ninguna.
func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	_inventory_changed()
	return true


func add_coins(amount: int) -> void:
	coins = clampi(coins + amount, 0, MAX_COUNT)
	_inventory_changed()


func add_bombs(amount: int) -> void:
	bombs = clampi(bombs + amount, 0, MAX_COUNT)
	_inventory_changed()


func add_keys(amount: int) -> void:
	keys = clampi(keys + amount, 0, MAX_COUNT)
	_inventory_changed()


func _inventory_changed() -> void:
	inventory_changed.emit(coins, bombs, keys)
