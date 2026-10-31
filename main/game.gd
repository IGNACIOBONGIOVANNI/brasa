class_name Game
extends Node2D
## Una run: conecta el HUD con el jugador (y con el piso, si hay FloorController), cuenta el tiempo
## jugado, maneja la pausa y registra los comandos generales del menú de debug (F3). La escena de
## tests `tests/fixtures/arena.tscn` usa este mismo script con una sala fija, sin piso ni pausa.
## El mundo (salas, entidades, balas, efectos y cámara) vive en el SubViewport `world`, que se dibuja
## a 320x180 y se agranda con píxeles enteros; el HUD y los menús van afuera, a la resolución de la
## ventana, así el texto se ve nítido.

## Desde la pausa: volver al menú o salir del juego (los atiende Main).
signal menu_requested
signal quit_requested

const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const PEDESTAL_SCENE: PackedScene = preload("res://entities/pickups/item_pedestal.tscn")
## Cuánto da el comando de debug de recursos.
const DEV_RESOURCES: int = 5
## Dónde aparece el pedestal de debug respecto del jugador.
const DEV_PEDESTAL_OFFSET: Vector2 = Vector2(0, -28)

@onready var world: SubViewport = $WorldView/World
@onready var player: Player = $WorldView/World/Entities/Player
@onready var floor_controller: FloorController = get_node_or_null(^"FloorController") as FloorController
@onready var _entities: Node2D = $WorldView/World/Entities
@onready var _hud: Hud = $Hud
@onready var _pause: PauseMenu = get_node_or_null(^"PauseMenu") as PauseMenu
@onready var _inventory: InventoryMenu = get_node_or_null(^"Inventory") as InventoryMenu
@onready var _ambient: CanvasModulate = get_node_or_null(^"WorldView/World/Ambient") as CanvasModulate
@onready var _motes: AmbientMotes = get_node_or_null(^"WorldView/World/GameCamera/Motes") as AmbientMotes


func _ready() -> void:
	_hud.bind_player(player)
	if floor_controller != null:
		_hud.bind_floor(floor_controller)
		EventBus.floor_changed.connect(_apply_floor_mood)
		_apply_floor_mood(floor_controller.floor_index)
	if _pause != null:
		_pause.menu_requested.connect(menu_requested.emit)
		_pause.quit_requested.connect(quit_requested.emit)
		_pause.inventory_requested.connect(_open_inventory_from_pause)
	Debug.add_command(self, "Curar al jugador", _heal_player)
	Debug.add_command(self, "Invulnerable si/no", _toggle_invulnerable)
	Debug.add_command(self, "Recargar Pulsos", _refill_pulses)
	Debug.add_command(self, "+5 monedas, bombas y llaves", _give_resources)
	Debug.add_command(self, "Cargar activo", RunState.charge_active.bind(99))
	Debug.add_command(self, "Matar al jugador", player.health.kill)
	var catalog := load(RunState.CATALOG_PATH) as ItemCatalog
	for item: ItemData in catalog.items + [catalog.filler]:
		Debug.add_command(self, "Items/%s" % item.display_name, spawn_item_pedestal.bind(item))


## Pone un pedestal gratis con `item` arriba del jugador (menú de debug).
func spawn_item_pedestal(item: ItemData) -> ItemPedestal:
	var pedestal := PEDESTAL_SCENE.instantiate() as ItemPedestal
	pedestal.set_item(item, 0)
	pedestal.position = _entities.to_local(player.global_position + DEV_PEDESTAL_OFFSET)
	_entities.add_child(pedestal)
	return pedestal


func spawn_enemy(data: EnemyData, at: Vector2) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = data
	enemy.position = at
	_entities.add_child(enemy)
	return enemy


## Penumbra y partículas de ambiente del piso.
func _apply_floor_mood(index: int) -> void:
	var theme: FloorTheme = floor_controller.run.floors[index]
	if _ambient != null:
		_ambient.color = theme.ambient_light
	if _motes != null:
		_motes.configure(theme)


func _open_inventory_from_pause() -> void:
	_pause.close()
	_inventory.open()


func _heal_player() -> void:
	player.health.heal(player.health.max_health)


func _toggle_invulnerable() -> void:
	player.health.always_invulnerable = not player.health.always_invulnerable


func _refill_pulses() -> void:
	RunState.set_blanks(RunState.START_BLANKS)


func _give_resources() -> void:
	RunState.add_coins(DEV_RESOURCES)
	RunState.add_bombs(DEV_RESOURCES)
	RunState.add_keys(DEV_RESOURCES)


## El tiempo de la run solo corre mientras se juega (la pausa y las transiciones lo frenan).
func _physics_process(delta: float) -> void:
	RunState.run_time += delta
