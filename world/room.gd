class_name Room
extends Node2D
## Una sala del piso armada desde su plantilla. Maneja su combate: la primera vez que se entra, si
## hay enemigos, cierra las puertas y larga las oleadas; cuando muere el último enemigo de la
## última oleada abre las puertas y sortea un premio (stream LOOT). Los enemigos a veces sueltan
## una moneda. En el tesoro, la tienda, la secreta y el Altar pone los pedestales con los items
## sorteados del piso (en el Altar se pagan con vida y al llevarse uno los otros desaparecen); en el
## Pozo, el pozo; en la sala del jefe y en la Prueba el pedestal aparece recién al ganar (la salida
## del jefe la pone FloorController). En el Galpón, el armazón parado.
## Trampas: las arma RoomBuilder (la del piso en cada "^"); solo funcionan en la sala actual
## (set_present) y al volver arrancan de nuevo.
## Regla (RoomSlot.rule): se anuncia por EventBus.room_rule_changed al cerrarse las puertas, cambia la
## vida y el ritmo de los enemigos y, al limpiar, suelta sus pickups extra (con Contrarreloj, solo si
## se limpió a tiempo).
## Run guardada: `capture` saca lo que cambió en la sala (limpia o no, pedestales, pickups, rocas rotas,
## pozo, armazones parados) y `restore` lo repone en una sala recién armada.

signal door_entered(side: Vector2i)
signal door_unlock_requested(side: Vector2i)
signal cleared

enum Phase { UNVISITED, FIGHTING, CLEARED }

const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const PICKUP_SCENE: PackedScene = preload("res://entities/pickups/pickup.tscn")
const PEDESTAL_SCENE: PackedScene = preload("res://entities/pickups/item_pedestal.tscn")
const DOOR_SCENE: PackedScene = preload("res://world/door.tscn")
const EXIT_SCENE: PackedScene = preload("res://entities/exit/trapdoor.tscn")
const WELL_SCENE: PackedScene = preload("res://entities/pickups/well.tscn")
const PARKED_MECH_SCENE: PackedScene = preload("res://entities/mechs/parked_mech.tscn")
## Lo que cuesta cada item del Altar, en medios corazones de vida máxima (el contenedor entero).
const ALTAR_HEALTH_PRICE: int = 2
## Dónde se buscan lugares para los pickups extra de la regla, alrededor del centro.
const BONUS_OFFSETS: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(-2, 1), Vector2i(2, 1)]
const NEXT_WAVE_DELAY: float = 0.6
const CLEAR_DELAY: float = 0.35
const BOSS_HEART_OFFSET: Vector2 = Vector2(0, 32)
## Celdas de distancia a los enemigos de la plantilla al aparecer sin cruzar una puerta.
const SPAWN_CLEARANCE: int = 3
## Hacia dónde se buscan los lugares del brasero frío (una esquina) y de la boca del Cenicero.
const BRAZIER_TARGET: Vector2i = Vector2i(1, 1)
const CHUTE_TARGET: Vector2i = Vector2i(12, 7)
## Celdas frente a las cuatro puertas (ahí nunca va nada del escenario).
const DOOR_FRONTS: Array[Vector2i] = [Vector2i(7, 0), Vector2i(7, 8), Vector2i(0, 4), Vector2i(14, 4)]

var slot: RoomSlot
var grid: RoomGrid
## Caminos para los enemigos (las rocas rotas se destapan).
var nav: RoomNav
var phase: Phase = Phase.UNVISITED
var doors: Dictionary[Vector2i, Door] = {}
var _theme: FloorTheme
var _entities: Node2D
var _wave: int = 0
var _enemies: Array[Enemy] = []
## Cambia cada vez que se reinicia el combate, así un timer viejo no larga una oleada fuera de tiempo.
var _combat_id: int = 0
## Segundos peleando con la regla (para Contrarreloj).
var _rule_time: float = 0.0


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
	var salt: int = hash("%s/%s/%s" % [theme.id, slot.template.id, slot.cell])
	var no_walls: Array[Rect2] = []
	($FloorScenery as RoomScenery).setup(theme, no_walls, salt)
	($WallScenery as RoomScenery).setup(theme, RoomBuilder.wall_layout(sides), salt)
	RoomBuilder.build_obstacles($Obstacles as Node2D, grid, theme)
	nav = RoomNav.from_grid(grid)
	for child: Node in ($Obstacles as Node2D).get_children():
		var rock := child as Rock
		if rock != null:
			rock.tree_exiting.connect(nav.set_open.bind(RoomNav.cell_of(rock.position), true))
	RoomBuilder.build_traps($Traps as Node2D, grid, theme)
	set_present(false)
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
	if slot.kind == RoomSlot.Kind.WELL and not grid.item_spots.is_empty():
		var well := WELL_SCENE.instantiate() as Well
		well.position = RoomGrid.cell_center(grid.item_spots[0])
		($Pickups as Node2D).add_child(well)
	elif slot.kind == RoomSlot.Kind.HANGAR and slot.mech != null and not grid.item_spots.is_empty():
		var parked := PARKED_MECH_SCENE.instantiate() as ParkedMech
		parked.setup(slot.mech)
		parked.position = RoomGrid.cell_center(grid.item_spots[0])
		($Pickups as Node2D).add_child(parked)
	elif slot.kind != RoomSlot.Kind.BOSS and slot.kind != RoomSlot.Kind.CHALLENGE:
		_spawn_offers()


func _physics_process(delta: float) -> void:
	if phase != Phase.FIGHTING or slot.rule == null:
		return
	var had_time: bool = rule_time_left() > 0.0
	_rule_time += delta
	if had_time and slot.rule.time_limit > 0.0 and rule_time_left() <= 0.0:
		AudioManager.play_sfx(&"empty")


## Las trampas solo andan en la sala donde está el jugador; al volver arrancan quietas.
func set_present(present: bool) -> void:
	($WallScenery as RoomScenery).set_animated(present)
	var traps := $Traps as Node2D
	traps.process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED
	if present:
		for child: Node in traps.get_children():
			(child as Trap).reset()


func trap_count() -> int:
	return ($Traps as Node2D).get_child_count()


## Segundos que quedan para el premio extra de Contrarreloj (INF si la regla no tiene límite).
func rule_time_left() -> float:
	if slot.rule == null or slot.rule.time_limit <= 0.0:
		return INF
	return maxf(0.0, slot.rule.time_limit - _rule_time)


## Pedestales con los items de la sala: gratis, en la tienda con precio y en el Altar con vida.
func _spawn_offers() -> void:
	var for_sale: bool = slot.kind == RoomSlot.Kind.SHOP
	var altar: bool = slot.kind == RoomSlot.Kind.ALTAR
	for i: int in mini(grid.item_spots.size(), slot.offers.size()):
		var item: ItemData = slot.offers[i]
		_make_pedestal(item, item.shop_price() if for_sale else 0, ALTAR_HEALTH_PRICE if altar else 0,
				RoomGrid.cell_center(grid.item_spots[i]))


## Un pedestal en `local_position`. Los que se pagan con vida son del Altar: al llevarse uno, los
## otros desaparecen.
func _make_pedestal(item: ItemData, price: int, health_price: int, local_position: Vector2) -> ItemPedestal:
	var pedestal := PEDESTAL_SCENE.instantiate() as ItemPedestal
	pedestal.set_item(item, price, health_price)
	pedestal.position = local_position
	if health_price > 0:
		pedestal.item_taken.connect(_on_altar_taken.bind(pedestal), CONNECT_ONE_SHOT)
	($Pickups as Node2D).add_child(pedestal)
	return pedestal


## Lo que cambió en la sala, para guardar la run.
func capture() -> RunSnapshot.RoomState:
	var state := RunSnapshot.RoomState.new()
	state.cleared = phase == Phase.CLEARED
	for child: Node in ($Pickups as Node2D).get_children():
		if child.is_queued_for_deletion():
			continue
		var at: Vector2 = to_local((child as Node2D).global_position)
		if child is ItemPedestal:
			var pedestal := child as ItemPedestal
			var saved_pedestal := RunSnapshot.PedestalState.new()
			saved_pedestal.item = pedestal.item.id if pedestal.item != null else &""
			saved_pedestal.price = pedestal.price
			saved_pedestal.health_price = pedestal.health_price
			saved_pedestal.position = at
			state.pedestals.append(saved_pedestal)
		elif child is Pickup:
			var saved_pickup := RunSnapshot.PickupState.new()
			saved_pickup.id = (child as Pickup).data.id
			saved_pickup.position = at
			state.pickups.append(saved_pickup)
		elif child is ParkedMech:
			state.mechs.append(capture_mech(child as ParkedMech))
		elif child is Well:
			state.well_dry = (child as Well).dry
	var standing: Dictionary[Vector2i, bool] = {}
	for child: Node in ($Obstacles as Node2D).get_children():
		if child is Rock and not child.is_queued_for_deletion():
			standing[RoomNav.cell_of((child as Rock).position)] = true
	for y: int in RoomGrid.HEIGHT:
		for x: int in RoomGrid.WIDTH:
			var cell := Vector2i(x, y)
			if grid.cell_at(cell) == RoomGrid.Cell.ROCK and not standing.has(cell):
				state.broken_rocks.append(cell)
	return state


## Un armazón parado en esta sala (también los que quedaron en el contenedor de entidades).
func capture_mech(parked: ParkedMech) -> RunSnapshot.MechState:
	var saved := RunSnapshot.MechState.new()
	saved.id = parked.data.id
	saved.armor = parked.armor
	saved.position = to_local(parked.global_position)
	return saved


## Deja la sala recién armada como estaba en la run guardada: saca los pedestales, pickups y
## armazones de la plantilla y pone los guardados, rompe las rocas rotas, seca el pozo y, si se había
## limpiado, no se vuelve a pelear. Llamar después de `setup`.
func restore(state: RunSnapshot.RoomState, items: Dictionary[StringName, ItemData], mechs: Dictionary[StringName, MechData]) -> void:
	var pickups := $Pickups as Node2D
	for child: Node in pickups.get_children():
		if child is ItemPedestal or child is Pickup or child is ParkedMech:
			pickups.remove_child(child)
			child.queue_free()
	for saved_pedestal: RunSnapshot.PedestalState in state.pedestals:
		var item: ItemData = items.get(saved_pedestal.item)
		_make_pedestal(item, saved_pedestal.price, saved_pedestal.health_price, saved_pedestal.position)
	for saved_pickup: RunSnapshot.PickupState in state.pickups:
		var data: PickupData = _pickup_by_id(saved_pickup.id)
		if data != null:
			spawn_pickup(data, saved_pickup.position, false)
	for saved_mech: RunSnapshot.MechState in state.mechs:
		var mech: MechData = mechs.get(saved_mech.id)
		if mech != null:
			var parked := PARKED_MECH_SCENE.instantiate() as ParkedMech
			parked.setup(mech, saved_mech.armor)
			parked.position = saved_mech.position
			pickups.add_child(parked)
	var obstacles := $Obstacles as Node2D
	for child: Node in obstacles.get_children():
		var rock := child as Rock
		if rock != null and state.broken_rocks.has(RoomNav.cell_of(rock.position)):
			obstacles.remove_child(rock)
			rock.queue_free()
	for cell: Vector2i in state.broken_rocks:
		nav.set_open(cell, true)
	if state.well_dry:
		for child: Node in pickups.get_children():
			if child is Well:
				(child as Well).set_dry()
	if state.cleared:
		phase = Phase.CLEARED


func _pickup_by_id(id: StringName) -> PickupData:
	for pickup: PickupData in _theme.pickups:
		if pickup.id == id:
			return pickup
	return null


## En el Altar se elige uno: los demás pedestales desaparecen.
func _on_altar_taken(chosen: ItemPedestal) -> void:
	for node: Node in ($Pickups as Node2D).get_children():
		var pedestal := node as ItemPedestal
		if pedestal != null and pedestal != chosen:
			pedestal.vanish()


## Pone la salida (trampilla o salida final) en el centro de la sala.
func spawn_exit(final: bool) -> Trapdoor:
	var exit := EXIT_SCENE.instantiate() as Trapdoor
	exit.final = final
	exit.position = RoomGrid.cell_center(RoomGrid.CENTER)
	($Pickups as Node2D).add_child(exit)
	return exit


## El brasero frío del camino secreto, en una esquina (FloorController lo pone en su sala): tapa el
## paso, así que su celda queda cerrada para los caminos de los enemigos.
func add_brazier() -> Brazier:
	var cell: Vector2i = prop_cell(BRAZIER_TARGET)
	var brazier := Brazier.new()
	brazier.position = RoomGrid.cell_center(cell)
	($Pickups as Node2D).add_child(brazier)
	nav.set_open(cell, false)
	return brazier


## La boca tapiada que baja al piso secreto (en la sala del jefe del piso de la boca).
func add_chute() -> AshChute:
	var chute := AshChute.new()
	chute.room = self
	chute.position = RoomGrid.cell_center(prop_cell(CHUTE_TARGET))
	($Pickups as Node2D).add_child(chute)
	return chute


## Una celda cerca de `target` para algo del escenario: se camina, no es lugar de pedestal, trampa ni
## pickup, no está frente a una puerta ni pegada a un enemigo, y todas sus vecinas dentro de la sala se
## caminan (así, aunque tape el paso, no corta ningún camino).
func prop_cell(target: Vector2i) -> Vector2i:
	var taken: Dictionary[Vector2i, bool] = {}
	for marker: RoomGrid.PickupMarker in grid.pickups:
		taken[marker.cell] = true
	var best: Vector2i = grid.nearest_walkable(target, 2)
	var best_distance: int = 1 << 30
	for y: int in RoomGrid.HEIGHT:
		for x: int in RoomGrid.WIDTH:
			var cell := Vector2i(x, y)
			var distance: int = (cell - target).length_squared()
			if distance < best_distance and not taken.has(cell) and grid.nearest_walkable(cell, 2) == cell 					and _open_around(cell) and not _near_door(cell):
				best = cell
				best_distance = distance
	return best


func _open_around(cell: Vector2i) -> bool:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var next: Vector2i = cell + Vector2i(dx, dy)
			var inside: bool = next.x >= 0 and next.y >= 0 and next.x < RoomGrid.WIDTH and next.y < RoomGrid.HEIGHT
			if inside and not grid.is_walkable(next):
				return false
	return true


func _near_door(cell: Vector2i) -> bool:
	for front: Vector2i in DOOR_FRONTS:
		var gap: Vector2i = (front - cell).abs()
		if maxi(gap.x, gap.y) <= 1:
			return true
	return false


## Dónde aparece el jugador si llega sin cruzar una puerta (inicio o debug), en coordenadas locales.
func spawn_point() -> Vector2:
	return RoomGrid.cell_center(grid.nearest_walkable(RoomGrid.CENTER, SPAWN_CLEARANCE))


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
	_rule_time = 0.0
	if slot.rule != null:
		EventBus.room_rule_changed.emit(slot.rule)
		AudioManager.play_sfx(&"rule")
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
	if slot.rule != null:
		EventBus.room_rule_changed.emit(null)


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
		enemy.health_multiplier = _theme.enemy_health_mult
		enemy.bullet_speed_multiplier = _theme.enemy_bullet_speed_mult
		if slot.rule != null:
			enemy.health_multiplier *= slot.rule.enemy_health_mult
			enemy.pace = slot.rule.enemy_pace
		enemy.nav = nav
		enemy.nav_origin = global_position
		enemy.play_intro = slot.kind == RoomSlot.Kind.BOSS
		enemy.position = _entities.to_local(to_global(RoomGrid.cell_center(marker.cell)))
		_entities.add_child(enemy)
		_register_enemy(enemy)
	if _enemies.is_empty():
		_on_wave_done()


## Cuenta al enemigo para la oleada, y también a los que cree (babosas, crías).
func _register_enemy(enemy: Enemy) -> void:
	enemy.killed.connect(_on_enemy_died.bind(enemy))
	enemy.spawned.connect(_register_enemy)
	_enemies.append(enemy)


func _on_enemy_died(enemy: Enemy) -> void:
	_enemies.erase(enemy)
	# Lo que desaparece con su invocador no suelta nada.
	if not enemy.dismissed and GameRNG.stream(RngStreams.LOOT).randf() < _theme.enemy_coin_chance:
		# Llega desde un callback de física: el pickup (un Area2D) se agrega diferido.
		var coin: PickupData = _theme.pickup_of_kind(PickupData.Kind.COIN)
		spawn_pickup.call_deferred(coin, to_local(enemy.global_position), true)
	if not enemy.dismissed and not enemy.data.drops.is_empty():
		_spawn_drops(enemy.data.drops, to_local(enemy.global_position))
	if _enemies.is_empty() and phase == Phase.FIGHTING:
		_on_wave_done()


## Lo que suelta seguro un enemigo al morir (los minijefes): cada cosa en un lugar libre distinto
## alrededor de donde cayó. Diferido, como las monedas.
func _spawn_drops(drops: Array[PickupData], local_position: Vector2) -> void:
	var center: Vector2i = grid.nearest_walkable(RoomNav.cell_of(local_position))
	var cells: Array[Vector2i] = [center]
	for offset: Vector2i in BONUS_OFFSETS:
		var cell: Vector2i = grid.nearest_walkable(center + offset)
		if not cells.has(cell):
			cells.append(cell)
	for i: int in drops.size():
		spawn_pickup.call_deferred(drops[i], RoomGrid.cell_center(cells[i % cells.size()]), true)


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
	if slot.rule != null:
		EventBus.room_rule_changed.emit(null)
		if slot.rule.earns_bonus(_rule_time):
			_spawn_bonus(slot.rule.bonus_rewards)
	if slot.kind == RoomSlot.Kind.CHALLENGE:
		_spawn_offers()
	elif slot.kind == RoomSlot.Kind.BOSS:
		# Premio del jefe: su item y un corazón seguro (debajo de donde aparece la salida).
		_spawn_offers()
		spawn_pickup(_theme.pickup_of_kind(PickupData.Kind.HEART), RoomGrid.cell_center(RoomGrid.CENTER) + BOSS_HEART_OFFSET, true)
	else:
		var reward: PickupData = RoomReward.roll(GameRNG.stream(RngStreams.LOOT), _theme.pickups, _theme.room_reward_chance)
		if reward != null:
			spawn_pickup(reward, spawn_point(), true)
	EventBus.room_cleared.emit(slot.cell)
	cleared.emit()


## Pickups seguros de la regla, cada uno en un lugar libre distinto cerca del centro.
func _spawn_bonus(count: int) -> void:
	var center: Vector2i = grid.nearest_walkable(RoomGrid.CENTER)
	var cells: Array[Vector2i] = []
	for offset: Vector2i in BONUS_OFFSETS:
		var cell: Vector2i = grid.nearest_walkable(RoomGrid.CENTER + offset)
		if cell != center and not cells.has(cell):
			cells.append(cell)
	var loot: RandomNumberGenerator = GameRNG.stream(RngStreams.LOOT)
	for i: int in count:
		var reward: PickupData = RoomReward.roll(loot, _theme.pickups, 1.0)
		if reward != null:
			var cell: Vector2i = cells[i % cells.size()] if not cells.is_empty() else center
			spawn_pickup(reward, RoomGrid.cell_center(cell), true)


func _on_door_player_entered(side: Vector2i) -> void:
	door_entered.emit(side)


func _on_door_unlock_requested(side: Vector2i) -> void:
	door_unlock_requested.emit(side)
