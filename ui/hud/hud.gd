class_name Hud
extends CanvasLayer
## HUD de la run. Arriba a la izquierda (sobre la pared): corazones, cargas de Pulso, monedas/bombas/
## llaves y el activo con su carga. Arriba a la derecha: el minimapa. Abajo (sobre la pared): los
## items pasivos a la izquierda y el arma con su munición a la derecha. El cartel (item agarrado,
## piso nuevo o jefe que aparece), la barra del jefe y los bordes rojos de peligro (golpe y vida baja).

## Con esta vida o menos (en medios corazones) suena el latido.
const LOW_HEALTH: float = 2.0
const BOSS_INTRO_TRAUMA: float = 0.35

var _floor: FloorController
var _last_health: float = -1.0

@onready var _hearts: HeartsDisplay = $Hearts
@onready var _pulses: PulseDisplay = $Pulses
@onready var _counters: CountersDisplay = $Counters
@onready var _active: ActiveDisplay = $Active
@onready var _items: ItemsDisplay = $Items
@onready var _weapon: WeaponDisplay = $Weapon
@onready var _banner: ItemBanner = $Banner
@onready var _boss_bar: BossBar = $BossBar
@onready var _minimap: Minimap = $Minimap
@onready var _danger: DangerOverlay = $Danger


func bind_player(player: Player) -> void:
	player.health.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health.current, player.health.max_health)
	RunState.blanks_changed.connect(_pulses.set_count)
	_pulses.set_count(RunState.blanks)
	RunState.inventory_changed.connect(_counters.set_values)
	_counters.set_values(RunState.coins, RunState.bombs, RunState.keys)
	RunState.items_changed.connect(_refresh_items)
	RunState.active_changed.connect(_refresh_active)
	RunState.weapons_changed.connect(_refresh_weapon)
	EventBus.item_picked.connect(_banner.show_item)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_defeated.connect(_boss_bar.untrack)
	_refresh_items()
	_refresh_active()
	_refresh_weapon()


func bind_floor(floor_controller: FloorController) -> void:
	_floor = floor_controller
	_floor.map_changed.connect(_refresh_minimap)
	EventBus.floor_changed.connect(_on_floor_changed)
	_on_floor_changed(_floor.floor_index)
	_refresh_minimap()


func _on_health_changed(current: float, max_value: float) -> void:
	_hearts.set_health(roundi(current), roundi(max_value))
	if _last_health >= 0.0 and current < _last_health:
		_danger.flash()
	_last_health = current
	_danger.set_low_health(current > 0.0 and current <= LOW_HEALTH)


func _on_boss_spawned(boss: Node2D) -> void:
	_boss_bar.track(boss)
	var data := boss.get(&"data") as EnemyData
	if data != null:
		_banner.show_text(data.display_name, "Jefe")
	AudioManager.play_sfx(&"boss_intro")
	EventBus.shake_requested.emit(BOSS_INTRO_TRAUMA)


func _refresh_items() -> void:
	_items.set_items(RunState.items)


func _refresh_active() -> void:
	_active.set_active(RunState.active_item, RunState.active_charge)


func _refresh_weapon() -> void:
	_weapon.set_slot(RunState.current_weapon_slot())


func _refresh_minimap() -> void:
	var layout: FloorLayout = _floor.layout
	var kinds: Dictionary[Vector2i, RoomSlot.Kind] = {}
	for cell: Vector2i in layout.slots:
		kinds[cell] = layout.slots[cell].kind
	var states: Dictionary[Vector2i, MinimapModel.CellState] = MinimapModel.compute(layout, _floor.visited,
			_floor.current_cell, _floor.discovered_secrets, _floor.map_revealed)
	_minimap.set_map(states, kinds)


func _on_floor_changed(index: int) -> void:
	_banner.show_text("Piso %d" % (index + 1), RunState.floor_name)
