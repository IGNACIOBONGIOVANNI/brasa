class_name Hud
extends CanvasLayer
## HUD de la run: corazones, cargas de Pulso, monedas/bombas/llaves (arriba a la izquierda, sobre la
## pared) y el minimapa (arriba a la derecha).

var _floor: FloorController

@onready var _hearts: HeartsDisplay = $Hearts
@onready var _pulses: PulseDisplay = $Pulses
@onready var _counters: CountersDisplay = $Counters
@onready var _minimap: Minimap = $Minimap


func bind_player(player: Player) -> void:
	player.health.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health.current, player.health.max_health)
	RunState.blanks_changed.connect(_pulses.set_count)
	_pulses.set_count(RunState.blanks)
	RunState.inventory_changed.connect(_counters.set_values)
	_counters.set_values(RunState.coins, RunState.bombs, RunState.keys)


func bind_floor(floor_controller: FloorController) -> void:
	_floor = floor_controller
	_floor.map_changed.connect(_refresh_minimap)
	_refresh_minimap()


func _on_health_changed(current: float, max_value: float) -> void:
	_hearts.set_health(roundi(current), roundi(max_value))


func _refresh_minimap() -> void:
	var layout: FloorLayout = _floor.layout
	var kinds: Dictionary[Vector2i, RoomSlot.Kind] = {}
	for cell: Vector2i in layout.slots:
		kinds[cell] = layout.slots[cell].kind
	var states: Dictionary[Vector2i, MinimapModel.CellState] = MinimapModel.compute(layout, _floor.visited,
			_floor.current_cell, _floor.discovered_secrets, _floor.map_revealed)
	_minimap.set_map(states, kinds)
