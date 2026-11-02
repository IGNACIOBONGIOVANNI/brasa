class_name Game
extends Node2D
## Una run: conecta el HUD con el jugador (y con el piso, si hay FloorController), cuenta el tiempo
## jugado, maneja la pausa y registra los comandos generales del menú de debug (F3). La escena de
## tests `tests/fixtures/arena.tscn` usa este mismo script con una sala fija, sin piso ni pausa.
## El mundo (salas, entidades, balas, efectos y cámara) vive en el SubViewport `world`, que se dibuja
## a 320x180 y se agranda con píxeles enteros; el HUD y los menús van afuera, a la resolución de la
## ventana, así el texto se ve nítido.
## Con piso, también pone la música: el tema del piso, el del jefe mientras hay uno vivo y silencio
## al morir. La luz de la sala es la penumbra del piso, oscurecida por la regla (Apagón) o por un jefe
## que la apaga (EventBus.darkness_requested); gana la más oscura.
## Guardado de la run (con piso): `save_run` guarda una foto (RunSnapshot) al entrar a cada sala, al
## limpiarla y, con `suspend`, al salir; en medio de una pelea no (queda la de cuando se entró: al
## seguir, la pelea se repite). Con `resume_from` arranca desde una foto.

## Desde la pausa: guardar y volver al menú, abandonar la run o guardar y salir del juego (los
## atiende Main).
signal menu_requested
signal abandon_requested
signal quit_requested

const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const PEDESTAL_SCENE: PackedScene = preload("res://entities/pickups/item_pedestal.tscn")
## Cuánto da el comando de debug de recursos.
const DEV_RESOURCES: int = 5
## Dónde aparece el pedestal de debug respecto del jugador.
const DEV_PEDESTAL_OFFSET: Vector2 = Vector2(0, -28)
## Al morir la música se apaga en este tiempo.
const DEATH_MUSIC_FADE: float = 1.2

@onready var world: SubViewport = $WorldView/World
@onready var player: Player = $WorldView/World/Entities/Player
@onready var floor_controller: FloorController = get_node_or_null(^"FloorController") as FloorController
@onready var _entities: Node2D = $WorldView/World/Entities
@onready var _hud: Hud = $Hud
@onready var _pause: PauseMenu = get_node_or_null(^"PauseMenu") as PauseMenu
@onready var _inventory: InventoryMenu = get_node_or_null(^"Inventory") as InventoryMenu
@onready var _ambient: CanvasModulate = get_node_or_null(^"WorldView/World/Ambient") as CanvasModulate
@onready var _motes: AmbientMotes = get_node_or_null(^"WorldView/World/GameCamera/Motes") as AmbientMotes

## Run guardada desde la que arranca (null = run nueva).
var resume: RunSnapshot
var _run_over: bool = false
var _rule_darkness: float = 0.0
var _boss_darkness: float = 0.0
var _light_tween: Tween


func _ready() -> void:
	_hud.bind_player(player)
	if floor_controller != null:
		_hud.bind_floor(floor_controller)
		EventBus.floor_changed.connect(_apply_floor_mood)
		_apply_floor_mood(floor_controller.floor_index)
		EventBus.boss_spawned.connect(_on_boss_spawned)
		EventBus.boss_defeated.connect(_on_boss_defeated)
		EventBus.player_died.connect(_on_player_died)
		EventBus.room_rule_changed.connect(_on_room_rule_changed)
		EventBus.darkness_requested.connect(_on_darkness_requested)
		EventBus.room_entered.connect(_on_room_entered)
		EventBus.room_cleared.connect(_on_room_cleared)
		EventBus.run_ended.connect(_on_run_ended)
		if resume != null:
			_restore_player(resume)
		# La primera sala ya se entró antes de conectar room_entered: se guarda acá.
		save_run()
	if _pause != null:
		_pause.menu_requested.connect(menu_requested.emit)
		_pause.quit_requested.connect(quit_requested.emit)
		_pause.abandon_requested.connect(abandon_requested.emit)
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


## Sigue una run guardada: llamar antes de agregar la escena al árbol.
func resume_from(snapshot: RunSnapshot) -> void:
	resume = snapshot
	($FloorController as FloorController).resume = snapshot


## true si se puede guardar la run ahora: hay piso, el jugador vive, no terminó y no está cambiando
## de sala o de piso.
func can_save_run() -> bool:
	return floor_controller != null and not _run_over and not player.is_dead() \
			and not floor_controller.is_transitioning() and floor_controller.current_room() != null


## Guarda la run tal como está. Devuelve si guardó.
func save_run() -> bool:
	if not can_save_run():
		return false
	var snapshot := RunSnapshot.new()
	RunState.capture(snapshot)
	floor_controller.capture(snapshot)
	snapshot.health = player.health.current
	snapshot.mech = player.mech.id if player.mech != null else &""
	snapshot.mech_armor = player.mech_armor.current
	SaveManager.save_run(snapshot.to_dict())
	return true


## Al salir de la run (al menú o del juego): guarda, salvo en medio de una pelea (ahí queda la foto de
## cuando se entró a la sala, así la pelea se repite entera).
func suspend() -> void:
	if can_save_run() and floor_controller.current_room().phase != Room.Phase.FIGHTING:
		save_run()


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


## Cuánto está oscurecida la sala ahora (0 = la penumbra normal del piso).
func darkness() -> float:
	return maxf(_rule_darkness, _boss_darkness)


## La vida y el armazón que tenía en la run guardada (el resto ya lo repusieron RunState y el piso).
func _restore_player(snapshot: RunSnapshot) -> void:
	player.health.setup(player.health.max_health, maxf(snapshot.health, 1.0))
	for mech: MechData in floor_controller.run.mechs:
		if mech.id == snapshot.mech:
			player.board(mech, snapshot.mech_armor)


func _on_room_entered(_cell: Vector2i) -> void:
	save_run()


func _on_room_cleared(_cell: Vector2i) -> void:
	save_run()


func _on_run_ended(_victory: bool) -> void:
	_run_over = true


## Penumbra, partículas de ambiente y música del piso.
func _apply_floor_mood(index: int) -> void:
	var theme: FloorTheme = floor_controller.run.floors[index]
	_rule_darkness = 0.0
	_boss_darkness = 0.0
	_refresh_light(0.0)
	if _motes != null:
		_motes.configure(theme)
	AudioManager.play_music(theme.music)


## Apagón: la sala queda más oscura mientras dura el combate.
func _on_room_rule_changed(rule: RoomRule) -> void:
	_rule_darkness = rule.darkness if rule != null else 0.0
	_refresh_light(0.0)


func _on_darkness_requested(amount: float, fade: float) -> void:
	_boss_darkness = amount
	_refresh_light(fade)


## Pone la luz de la sala según la penumbra del piso y lo que la oscurezca, de a poco si `fade` > 0.
func _refresh_light(fade: float) -> void:
	if _ambient == null:
		return
	var light: Color = floor_controller.theme.ambient_light.darkened(darkness())
	if _light_tween != null:
		_light_tween.kill()
	if fade <= 0.0:
		_ambient.color = light
		return
	_light_tween = create_tween()
	_light_tween.tween_property(_ambient, ^"color", light, fade)


func _on_boss_spawned(_boss: Node2D) -> void:
	AudioManager.play_music(floor_controller.theme.boss_music)


## Al morir el jefe también vuelve la luz (si la había apagado).
func _on_boss_defeated(_boss: Node2D) -> void:
	AudioManager.play_music(floor_controller.theme.music)
	_boss_darkness = 0.0
	_refresh_light(0.3)


func _on_player_died() -> void:
	AudioManager.stop_music(DEATH_MUSIC_FADE)


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
