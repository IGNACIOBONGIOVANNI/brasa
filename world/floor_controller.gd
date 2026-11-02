class_name FloorController
extends Node
## Arma y maneja los pisos de la run (RunConfig): genera cada layout (FloorGenerator, TemplatePicker y
## RulePicker con el stream FLOOR del piso; las especiales extra salen de FloorTheme.extra_rooms),
## construye cada sala la primera vez que se entra (después quedan armadas, con sus rocas rotas y sus
## pickups), sortea los items del tesoro, la tienda, la secreta, el jefe, la Prueba y el Altar y el
## armazón del Galpón (stream LOOT), mueve la cámara de sala en sala al cruzar una puerta, destapa las puertas a la
## secreta con explosiones, abre la tienda con una llave y guarda lo que muestra el minimapa.
## Al vencer al jefe pone la salida: trampilla al piso siguiente o, en el último, la que gana la run.
## Run guardada: `capture` pasa el piso a un RunSnapshot y, con `resume` puesto antes de entrar al
## árbol, el primer piso que arma es el de la foto (mismo layout por la seed, lo sorteado y lo visto
## de la foto; cada sala guardada se repone al armarla) y pone al jugador en su sala.

signal map_changed

const ROOM_SCENE: PackedScene = preload("res://world/room.tscn")
## Distancia entre centros de salas vecinas: más que una pantalla, así nunca se ve la de al lado.
const ROOM_STRIDE: Vector2 = Vector2(320, 192)
const TRANSITION_TIME: float = 0.3
## Margen extra (además del radio de la explosión) para destapar una puerta oculta.
const SECRET_REVEAL_MARGIN: float = 16.0
## Pedestales de la tienda y del altar.
const SHOP_OFFERS: int = 3
const ALTAR_OFFERS: int = 2
const PARKED_MECH_SCENE: PackedScene = preload("res://entities/mechs/parked_mech.tscn")
## Dónde aparece el armazón del menú de debug respecto del jugador.
const DEV_MECH_OFFSET: Vector2 = Vector2(0, -30)

@export var run: RunConfig
@export var rooms_root: Node2D
@export var entities: Node2D
@export var player: Player
@export var camera: Camera2D
## Fundido entre pisos (opcional).
@export var fade: ScreenFade

var floor_index: int = 0
var theme: FloorTheme
var layout: FloorLayout
var current_cell: Vector2i
var visited: Dictionary[Vector2i, bool] = {}
var discovered_secrets: Dictionary[Vector2i, bool] = {}
var map_revealed: bool = false
var _rooms: Dictionary[Vector2i, Room] = {}
## Conexiones con barrera (secreta o tienda) ya abiertas (clave: las dos celdas ordenadas).
var _opened_edges: Dictionary[Vector4i, bool] = {}
var _transitioning: bool = false
## Run guardada a seguir (la pone Game antes de entrar al árbol).
var resume: RunSnapshot
## Salas de la foto que todavía no se volvieron a armar (se reponen al entrar).
var _saved_rooms: Dictionary[Vector2i, RunSnapshot.RoomState] = {}
var _items_by_id: Dictionary[StringName, ItemData] = {}
var _mechs_by_id: Dictionary[StringName, MechData] = {}


func _ready() -> void:
	EventBus.exploded.connect(_on_exploded)
	_register_dev_commands()
	var catalog := load(RunState.CATALOG_PATH) as ItemCatalog
	for item: ItemData in catalog.items:
		_items_by_id[item.id] = item
	if catalog.filler != null:
		_items_by_id[catalog.filler.id] = catalog.filler
	for mech: MechData in run.mechs:
		_mechs_by_id[mech.id] = mech
	if resume != null and resume.floor_index >= 0 and resume.floor_index < run.floors.size():
		load_floor(resume.floor_index, resume)
	else:
		load_floor(0)


func _exit_tree() -> void:
	if _transitioning:
		get_tree().paused = false


func is_last_floor() -> bool:
	return floor_index >= run.floors.size() - 1


## Arma el piso `index` desde cero (borra el anterior) y pone al jugador en la sala inicial. Con
## `saved` (una run guardada en este piso) repone lo de la foto y lo pone donde estaba.
func load_floor(index: int, saved: RunSnapshot = null) -> void:
	floor_index = index
	theme = run.floors[index]
	RunState.floor_index = index
	RunState.floor_name = theme.display_name
	_clear_world()
	GameRNG.set_floor(index)
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.FLOOR)
	layout = FloorGenerator.generate(rng, _params(rng))
	TemplatePicker.assign(layout, theme.templates, rng, theme.difficulty_bonus)
	RulePicker.assign(layout, run.room_rules, theme.rule_chance, rng)
	var start_cell: Vector2i = layout.start
	if saved != null:
		_restore_floor(saved)
		if layout.has_room(saved.cell):
			start_cell = saved.cell
	else:
		_roll_offers()
	var room: Room = _ensure_room(start_cell)
	if saved != null and start_cell == saved.cell:
		player.global_position = room.to_global(saved.position)
	else:
		player.global_position = room.to_global(room.spawn_point())
	player.stop_motion()
	camera.global_position = room.global_position
	_enter(start_cell)
	EventBus.floor_changed.emit(index)


## Pasa lo del piso a la foto: sala y lugar del jugador, lo sorteado en cada sala, lo visto, las
## barreras abiertas y cada sala armada (con los armazones que quedaron parados en ella; las salas de
## una foto anterior que todavía no se volvieron a armar van como estaban).
func capture(snapshot: RunSnapshot) -> void:
	snapshot.floor_index = floor_index
	snapshot.cell = current_cell
	snapshot.position = current_room().to_local(player.global_position)
	snapshot.offers.clear()
	snapshot.hangar_mechs.clear()
	for cell: Vector2i in layout.slots:
		var slot: RoomSlot = layout.get_slot(cell)
		if not slot.offers.is_empty():
			var ids: Array[StringName] = []
			for item: ItemData in slot.offers:
				ids.append(item.id)
			snapshot.offers[cell] = ids
		if slot.mech != null:
			snapshot.hangar_mechs[cell] = slot.mech.id
	snapshot.visited.assign(visited.keys())
	snapshot.discovered_secrets.assign(discovered_secrets.keys())
	snapshot.map_revealed = map_revealed
	snapshot.opened_edges.assign(_opened_edges.keys())
	snapshot.rooms.clear()
	for cell: Vector2i in _saved_rooms:
		snapshot.rooms[cell] = _saved_rooms[cell]
	for cell: Vector2i in _rooms:
		snapshot.rooms[cell] = _rooms[cell].capture()
	for child: Node in entities.get_children():
		var parked := child as ParkedMech
		if parked == null or parked.is_queued_for_deletion():
			continue
		var cell: Vector2i = cell_at(parked.global_position)
		if snapshot.rooms.has(cell) and _rooms.has(cell):
			snapshot.rooms[cell].mechs.append(_rooms[cell].capture_mech(parked))


## Celda de la sala que contiene ese punto global.
func cell_at(global_point: Vector2) -> Vector2i:
	return layout.start + Vector2i((rooms_root.to_local(global_point) / ROOM_STRIDE).round())


## Lo de la foto que no sale de la seed: lo sorteado en cada sala, lo visto, las barreras abiertas y
## las salas ya armadas (se reponen cuando se arman).
func _restore_floor(saved: RunSnapshot) -> void:
	for cell: Vector2i in layout.slots:
		var slot: RoomSlot = layout.get_slot(cell)
		slot.offers.clear()
		for id: Variant in saved.offers.get(cell, []):
			var item: ItemData = _items_by_id.get(StringName(str(id)))
			if item != null:
				slot.offers.append(item)
		slot.mech = _mechs_by_id.get(saved.hangar_mechs.get(cell, &""))
	for cell: Vector2i in saved.visited:
		if layout.has_room(cell):
			visited[cell] = true
	for cell: Vector2i in saved.discovered_secrets:
		if layout.has_room(cell):
			discovered_secrets[cell] = true
	map_revealed = saved.map_revealed
	for edge: Vector4i in saved.opened_edges:
		_opened_edges[edge] = true
	for cell: Vector2i in saved.rooms:
		if layout.has_room(cell):
			_saved_rooms[cell] = saved.rooms[cell]


## Baja al piso siguiente con un fundido (el juego queda en pausa mientras tanto). Las cargas de
## Pulso vuelven a estar completas en cada piso.
func advance_floor() -> void:
	if _transitioning or is_last_floor():
		return
	_transitioning = true
	get_tree().paused = true
	if fade != null:
		await fade.fade_out()
	load_floor(floor_index + 1)
	RunState.set_blanks(RunState.START_BLANKS)
	if fade != null:
		await fade.fade_in()
	get_tree().paused = false
	_transitioning = false


## Saca todo lo del piso anterior: salas, enemigos, bombas, balas, efectos y manchas.
func _clear_world() -> void:
	_rooms.clear()
	_saved_rooms.clear()
	visited.clear()
	discovered_secrets.clear()
	_opened_edges.clear()
	map_revealed = false
	EventBus.room_rule_changed.emit(null)
	for container: Node in [rooms_root, entities]:
		for child: Node in container.get_children():
			if child != player:
				container.remove_child(child)
				child.queue_free()
	for group: StringName in [Bullet.PROJECTILES_GROUP, Fx.EFFECTS_GROUP, Fx.DECALS_GROUP]:
		var holder: Node = get_tree().get_first_node_in_group(group)
		if holder != null:
			for child: Node in holder.get_children():
				holder.remove_child(child)
				child.queue_free()


func is_transitioning() -> bool:
	return _transitioning


func get_room(cell: Vector2i) -> Room:
	return _rooms.get(cell)


func current_room() -> Room:
	return get_room(current_cell)


func room_position(cell: Vector2i) -> Vector2:
	return Vector2(cell - layout.start) * ROOM_STRIDE


## Va a otra sala. Con `direction` es cruzando una puerta (aparece del otro lado); con ZERO
## aparece en el centro (comandos de debug). Pausa el juego mientras se mueve la cámara.
func move_to(cell: Vector2i, direction: Vector2i = Vector2i.ZERO) -> void:
	if _transitioning or not layout.has_room(cell):
		return
	_transitioning = true
	current_room().reset_combat()
	get_tree().paused = true
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		node.queue_free()
	var room: Room = _ensure_room(cell)
	if direction == Vector2i.ZERO:
		player.global_position = room.to_global(room.spawn_point())
	else:
		player.global_position = room.entry_point(-direction)
	player.stop_motion()
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(camera, ^"global_position", room.global_position, TRANSITION_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	get_tree().paused = false
	_transitioning = false
	_enter(cell)


func _params(rng: RandomNumberGenerator) -> FloorParams:
	var params := FloorParams.new()
	params.room_count_min = theme.room_count_min
	params.room_count_max = theme.room_count_max
	params.min_boss_distance = theme.min_boss_distance
	params.extra_rooms = FloorGenerator.pick_extra_rooms(theme.extra_rooms, theme.extra_room_count, rng)
	return params


func _enter(cell: Vector2i) -> void:
	current_cell = cell
	for built: Vector2i in _rooms:
		_rooms[built].set_present(built == cell)
	visited[cell] = true
	if layout.get_slot(cell).kind == RoomSlot.Kind.SECRET:
		discovered_secrets[cell] = true
	get_room(cell).enter()
	EventBus.room_entered.emit(cell)
	map_changed.emit()


func _ensure_room(cell: Vector2i) -> Room:
	if _rooms.has(cell):
		return _rooms[cell]
	var neighbors: Dictionary[Vector2i, RoomSlot.Kind] = {}
	var door_modes: Dictionary[Vector2i, Door.Mode] = {}
	for next: Vector2i in layout.neighbors(cell):
		neighbors[next - cell] = layout.get_slot(next).kind
		door_modes[next - cell] = _barrier(cell, next)
	var room := ROOM_SCENE.instantiate() as Room
	room.position = room_position(cell)
	room.setup(layout.get_slot(cell), theme, neighbors, door_modes, entities)
	var saved: RunSnapshot.RoomState = _saved_rooms.get(cell)
	if saved != null:
		_saved_rooms.erase(cell)
		room.restore(saved, _items_by_id, _mechs_by_id)
	room.door_entered.connect(_on_room_door_entered.bind(cell))
	room.door_unlock_requested.connect(_on_room_door_unlock_requested.bind(cell))
	room.cleared.connect(_on_room_cleared.bind(cell))
	rooms_root.add_child(room)
	_rooms[cell] = room
	if saved != null and saved.cleared and layout.get_slot(cell).kind == RoomSlot.Kind.BOSS:
		_spawn_exit(cell)
	return room


## Un pedestal en el tesoro, tres en la tienda, uno en la secreta, el premio del jefe, el de la Prueba
## y dos en el Altar, sorteados al generar el piso.
func _roll_offers() -> void:
	var loot: RandomNumberGenerator = GameRNG.stream(RngStreams.LOOT)
	for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.TREASURE):
		layout.get_slot(cell).offers.append(RunState.item_pool.draw(ItemData.POOL_TREASURE, loot))
	for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.SHOP):
		for _i: int in SHOP_OFFERS:
			layout.get_slot(cell).offers.append(RunState.item_pool.draw(ItemData.POOL_SHOP, loot))
	for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.SECRET):
		layout.get_slot(cell).offers.append(RunState.item_pool.draw(ItemData.POOL_SECRET, loot))
	for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.BOSS):
		layout.get_slot(cell).offers.append(RunState.item_pool.draw(ItemData.POOL_BOSS, loot))
	for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.CHALLENGE):
		layout.get_slot(cell).offers.append(RunState.item_pool.draw(ItemData.POOL_TREASURE, loot))
	for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.ALTAR):
		for _i: int in ALTAR_OFFERS:
			layout.get_slot(cell).offers.append(RunState.item_pool.draw(ItemData.POOL_BOSS, loot))
	if not run.mechs.is_empty():
		for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.HANGAR):
			layout.get_slot(cell).mech = run.mechs[loot.randi_range(0, run.mechs.size() - 1)]


## Al vencer al jefe aparece la salida: al piso siguiente, o la que gana la run en el último.
func _on_room_cleared(cell: Vector2i) -> void:
	if layout.get_slot(cell).kind == RoomSlot.Kind.BOSS:
		_spawn_exit(cell)


func _spawn_exit(cell: Vector2i) -> void:
	var exit: Trapdoor = get_room(cell).spawn_exit(is_last_floor())
	exit.entered.connect(_on_exit_entered)


func _on_exit_entered() -> void:
	if is_last_floor():
		EventBus.run_ended.emit(true)
	else:
		advance_floor()


static func _edge_key(a: Vector2i, b: Vector2i) -> Vector4i:
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		return Vector4i(a.x, a.y, b.x, b.y)
	return Vector4i(b.x, b.y, a.x, a.y)


## Cómo está la puerta entre dos salas vecinas: oculta si da a la secreta, con candado si da a la
## tienda, abierta si no (o si esa barrera ya se abrió).
func _barrier(a: Vector2i, b: Vector2i) -> Door.Mode:
	if _opened_edges.has(_edge_key(a, b)):
		return Door.Mode.OPEN
	var kinds: Array[RoomSlot.Kind] = [layout.get_slot(a).kind, layout.get_slot(b).kind]
	if kinds.has(RoomSlot.Kind.SECRET):
		return Door.Mode.HIDDEN
	if kinds.has(RoomSlot.Kind.SHOP):
		return Door.Mode.LOCKED
	return Door.Mode.OPEN


## Abre la barrera entre dos salas, en las dos si ya están armadas.
func _open_edge(a: Vector2i, b: Vector2i) -> void:
	if _barrier(a, b) == Door.Mode.OPEN:
		return
	_opened_edges[_edge_key(a, b)] = true
	for pair: Vector4i in [Vector4i(a.x, a.y, b.x, b.y), Vector4i(b.x, b.y, a.x, a.y)]:
		var room: Room = get_room(Vector2i(pair.x, pair.y))
		if room != null:
			room.open_barrier(Vector2i(pair.z - pair.x, pair.w - pair.y))
	for cell: Vector2i in [a, b]:
		if layout.get_slot(cell).kind == RoomSlot.Kind.SECRET:
			discovered_secrets[cell] = true
	map_changed.emit()


func _on_room_door_unlock_requested(side: Vector2i, cell: Vector2i) -> void:
	if cell != current_cell:
		return
	if RunState.use_key():
		_open_edge(cell, cell + side)
		AudioManager.play_sfx(&"unlock")
	else:
		AudioManager.play_sfx(&"empty")


## Llega desde un callback de física (el trigger de la puerta): armar la sala nueva ahí no está
## permitido, así que el cambio se hace diferido.
func _on_room_door_entered(side: Vector2i, cell: Vector2i) -> void:
	if cell == current_cell:
		move_to.call_deferred(cell + side, side)


func _on_exploded(at: Vector2, radius: float) -> void:
	var room: Room = current_room()
	if room == null:
		return
	var found: bool = false
	for side: Vector2i in room.doors:
		var door: Door = room.doors[side]
		if door.mode == Door.Mode.HIDDEN and door.global_position.distance_to(at) <= radius + SECRET_REVEAL_MARGIN:
			_open_edge(current_cell, current_cell + side)
			found = true
	if found:
		AudioManager.play_sfx(&"secret_found")


# --- Menú de debug ---------------------------------------------------------------------------

func _register_dev_commands() -> void:
	Debug.add_command(self, "Ir a la sala del jefe", _go_to_kind.bind(RoomSlot.Kind.BOSS))
	Debug.add_command(self, "Ir al tesoro", _go_to_kind.bind(RoomSlot.Kind.TREASURE))
	Debug.add_command(self, "Ir a la tienda", _go_to_kind.bind(RoomSlot.Kind.SHOP))
	Debug.add_command(self, "Ir a la secreta", _go_to_kind.bind(RoomSlot.Kind.SECRET))
	Debug.add_command(self, "Ir a la Prueba (si hay)", _go_to_kind.bind(RoomSlot.Kind.CHALLENGE))
	Debug.add_command(self, "Ir al Altar (si hay)", _go_to_kind.bind(RoomSlot.Kind.ALTAR))
	Debug.add_command(self, "Ir al Pozo (si hay)", _go_to_kind.bind(RoomSlot.Kind.WELL))
	Debug.add_command(self, "Ir al Galpón (si hay)", _go_to_kind.bind(RoomSlot.Kind.HANGAR))
	for mech: MechData in run.mechs:
		Debug.add_command(self, "Mechas/%s" % mech.display_name, spawn_mech.bind(mech))
	for floor_theme: FloorTheme in run.floors:
		for enemy: EnemyData in floor_theme.enemies:
			var seen: Dictionary[BossAttack, bool] = {}
			for boss_phase: BossPhase in enemy.phases:
				for attack: BossAttack in boss_phase.attacks:
					if not seen.has(attack):
						seen[attack] = true
						Debug.add_command(self, "Jefes/%s: %s (%s)" % [enemy.display_name, attack.display_name, attack.id],
								force_boss_attack.bind(attack))
	Debug.add_command(self, "Volver al inicio", _go_to_kind.bind(RoomSlot.Kind.START))
	Debug.add_command(self, "Revelar mapa", _reveal_map)
	Debug.add_command(self, "Limpiar sala", _clear_current_room)
	Debug.add_command(self, "Siguiente piso (o ganar)", _on_exit_entered)


## Un armazón parado arriba del jugador (menú de debug).
func spawn_mech(mech: MechData) -> ParkedMech:
	var parked := Fx.spawn(get_tree(), PARKED_MECH_SCENE, player.global_position + DEV_MECH_OFFSET, Fx.ENTITIES_GROUP) as ParkedMech
	parked.setup(mech)
	return parked


## El jefe vivo que tenga ese movimiento lo hace ya (o apenas termine lo que está haciendo). Menú de
## debug, para probar cada movimiento sin esperar a que salga.
func force_boss_attack(attack: BossAttack) -> void:
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy.is_boss() and enemy.data.phases.any(func(p: BossPhase) -> bool: return p.attacks.has(attack)):
			enemy.force_attack(attack)


func _go_to_kind(kind: RoomSlot.Kind) -> void:
	var cell: Vector2i = layout.first_of_kind(kind)
	if kind == RoomSlot.Kind.SECRET or kind == RoomSlot.Kind.SHOP:
		for next: Vector2i in layout.neighbors(cell):
			_open_edge(cell, next)
	move_to(cell)


func _reveal_map() -> void:
	map_revealed = true
	map_changed.emit()


func _clear_current_room() -> void:
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		(node as Enemy).health.kill()
