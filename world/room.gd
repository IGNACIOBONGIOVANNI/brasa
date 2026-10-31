class_name Room
extends Node2D
## Una sala del piso armada desde su plantilla. Maneja su combate: la primera vez que se entra, si
## hay enemigos, cierra las puertas y larga las oleadas; cuando muere el último enemigo de la
## última oleada abre las puertas y sortea un premio (stream LOOT). Los enemigos a veces sueltan
## una moneda. En el tesoro y la tienda pone los pedestales con los items sorteados del piso.

signal door_entered(side: Vector2i)
signal door_unlock_requested(side: Vector2i)
signal cleared

enum Phase { UNVISITED, FIGHTING, CLEARED }

const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const PICKUP_SCENE: PackedScene = preload("res://entities/pickups/pickup.tscn")
const PEDESTAL_SCENE: PackedScene = preload("res://entities/pickups/item_pedestal.tscn")
const DOOR_SCENE: PackedScene = preload("res://world/door.tscn")
const NEXT_WAVE_DELAY: float = 0.6
const CLEAR_DELAY: float = 0.35

var slot: RoomSlot
var grid: RoomGrid
var phase: Phase = Phase.UNVISITED
var doors: Dictionary[Vector2i, Door] = {}
var _theme: FloorTheme
var _entities: Node2D
var _wave: int = 0
var _enemies: Array[Enemy] = []
## Cambia cada vez que se reinicia el combate, así un timer viejo no larga una oleada fuera de tiempo.
var _combat_id: int = 0


## Arma la sala; llamar antes de agregarla al árbol. `neighbors`: tipo de la sala detrás de cada
## puerta. `door_modes`: cómo arranca cada puerta que no esté abierta (HIDDEN para la secreta,
## LOCKED para la tienda). `entities`: contenedor (con y-sort) donde van los enemigos.
func setup(room_slot: RoomSlot, theme: FloorTheme, neighbors: Dictionary[Vector2i, RoomSlot.Kind],
		door_modes: Dictionary[Vector2i, Door.Mode], entities: Node2D) -> void:
	slot = room_slot
	_theme = theme
	_entities = entities
	grid = RoomTemplateParser.parse(slot.template.layout)
	RoomBuilder.style_floor($Floor as PlaceholderShape, theme)
	var sides: Array[Vector2i] = []
	for side: Vector2i in neighbors:
		sides.append(side)
	RoomBuilder.build_walls($Walls as Node2D, sides, theme)
	RoomBuilder.build_obstacles($Obstacles as Node2D, grid, theme)
	for side: Vector2i in sides:
		var door := DOOR_SCENE.instantiate() as Door
		door.setup(side, neighbors[side], door_modes.get(side, Door.Mode.OPEN), theme)
		door.position = RoomBuilder.door_position(side)
		door.player_entered.connect(_on_door_player_entered.bind(side))
		door.unlock_requested.connect(_on_door_unlock_requested.bind(side))
		($Doors as Node2D).add_child(door)
		doors[side] = door
	for marker: RoomGrid.PickupMarker in grid.pickups:
		spawn_pickup(theme.pickup_for_symbol(marker.symbol), RoomGrid.cell_center(marker.cell), false)
	var for_sale: bool = slot.kind == RoomSlot.Kind.SHOP
	for i: int in mini(grid.item_spots.size(), slot.offers.size()):
		var pedestal := PEDESTAL_SCENE.instantiate() as ItemPedestal
		var item: ItemData = slot.offers[i]
		pedestal.set_item(item, item.price if for_sale else 0)
		pedestal.position = RoomGrid.cell_center(grid.item_spots[i])
		($Pickups as Node2D).add_child(pedestal)


## Dónde aparece el jugador si llega sin cruzar una puerta (inicio o debug), en coordenadas locales.
func spawn_point() -> Vector2:
	return RoomGrid.cell_center(grid.nearest_walkable(RoomGrid.CENTER))


## Dónde aparece el jugador al entrar por la puerta de ese lado, en coordenadas globales.
func entry_point(side: Vector2i) -> Vector2:
	return to_global(RoomBuilder.entry_point(side))


## Primera visita: si hay enemigos cierra las puertas y larga la primera oleada.
func enter() -> void:
	if phase != Phase.UNVISITED:
		return
	if grid.enemies.is_empty():
		phase = Phase.CLEARED
		return
	phase = Phase.FIGHTING
	_set_doors(Door.Mode.CLOSED)
	AudioManager.play_sfx(&"door_close")
	_spawn_wave(0, _combat_id)


## Saca a los enemigos que queden y deja la sala como sin visitar (al teletransportarse en debug).
func reset_combat() -> void:
	if phase != Phase.FIGHTING:
		return
	_combat_id += 1
	for enemy: Enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	phase = Phase.UNVISITED
	_set_doors(Door.Mode.OPEN)


## Destapa una puerta oculta o abre una con candado: queda cerrada si se está peleando, si no abierta.
func open_barrier(side: Vector2i) -> void:
	var door: Door = doors.get(side)
	if door != null and (door.mode == Door.Mode.HIDDEN or door.mode == Door.Mode.LOCKED):
		door.set_mode(Door.Mode.CLOSED if phase == Phase.FIGHTING else Door.Mode.OPEN)


func spawn_pickup(data: PickupData, local_position: Vector2, pop: bool) -> Pickup:
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.data = data
	pickup.position = local_position
	($Pickups as Node2D).add_child(pickup)
	if pop:
		pickup.pop()
	return pickup


## Abre o cierra las puertas comunes; las ocultas y las con candado no se tocan.
func _set_doors(new_mode: Door.Mode) -> void:
	for door: Door in doors.values():
		if door.mode == Door.Mode.OPEN or door.mode == Door.Mode.CLOSED:
			door.set_mode(new_mode)


func _spawn_wave(index: int, combat_id: int) -> void:
	if phase != Phase.FIGHTING or combat_id != _combat_id:
		return
	_wave = index
	_enemies.clear()
	for marker: RoomGrid.EnemyMarker in grid.enemies:
		if marker.wave != index:
			continue
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		enemy.data = _theme.enemy_for_symbol(marker.symbol)
		enemy.position = _entities.to_local(to_global(RoomGrid.cell_center(marker.cell)))
		_entities.add_child(enemy)
		enemy.health.died.connect(_on_enemy_died.bind(enemy))
		_enemies.append(enemy)
	if _enemies.is_empty():
		_on_wave_done()


func _on_enemy_died(enemy: Enemy) -> void:
	_enemies.erase(enemy)
	if GameRNG.stream(RngStreams.LOOT).randf() < _theme.enemy_coin_chance:
		# Llega desde un callback de física: el pickup (un Area2D) se agrega diferido.
		var coin: PickupData = _theme.pickup_of_kind(PickupData.Kind.COIN)
		spawn_pickup.call_deferred(coin, to_local(enemy.global_position), true)
	if _enemies.is_empty() and phase == Phase.FIGHTING:
		_on_wave_done()


## Los timers no corren con el juego en pausa (menú de debug, transición de sala).
func _on_wave_done() -> void:
	if _wave + 1 < grid.wave_count():
		get_tree().create_timer(NEXT_WAVE_DELAY, false).timeout.connect(_spawn_wave.bind(_wave + 1, _combat_id))
	else:
		get_tree().create_timer(CLEAR_DELAY, false).timeout.connect(_clear.bind(_combat_id))


func _clear(combat_id: int) -> void:
	if phase != Phase.FIGHTING or combat_id != _combat_id:
		return
	phase = Phase.CLEARED
	_set_doors(Door.Mode.OPEN)
	AudioManager.play_sfx(&"door_open")
	AudioManager.play_sfx(&"room_clear")
	var reward: PickupData = RoomReward.roll(GameRNG.stream(RngStreams.LOOT), _theme.pickups, _theme.room_reward_chance)
	if reward != null:
		spawn_pickup(reward, spawn_point(), true)
	EventBus.room_cleared.emit(slot.cell)
	cleared.emit()


func _on_door_player_entered(side: Vector2i) -> void:
	door_entered.emit(side)


func _on_door_unlock_requested(side: Vector2i) -> void:
	door_unlock_requested.emit(side)
