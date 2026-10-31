class_name FloorController
extends Node
## Arma y maneja los pisos de la run (RunConfig): genera cada layout (FloorGenerator + TemplatePicker
## con el stream FLOOR del piso), construye cada sala la primera vez que se entra (después quedan
## armadas, con sus rocas rotas y sus pickups), sortea los items del tesoro, la tienda y el jefe
## (stream LOOT), mueve la cámara de sala en sala al cruzar una puerta, destapa las puertas a la
## secreta con explosiones, abre la tienda con una llave y guarda lo que muestra el minimapa.
## Al vencer al jefe pone la salida: trampilla al piso siguiente o, en el último, la que gana la run.

signal map_changed

const ROOM_SCENE: PackedScene = preload("res://world/room.tscn")
## Distancia entre centros de salas vecinas: más que una pantalla, así nunca se ve la de al lado.
const ROOM_STRIDE: Vector2 = Vector2(320, 192)
const TRANSITION_TIME: float = 0.3
## Margen extra (además del radio de la explosión) para destapar una puerta oculta.
const SECRET_REVEAL_MARGIN: float = 16.0
## Pedestales de la tienda.
const SHOP_OFFERS: int = 3

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


func _ready() -> void:
	EventBus.exploded.connect(_on_exploded)
	_register_dev_commands()
	load_floor(0)


func _exit_tree() -> void:
	if _transitioning:
		get_tree().paused = false


func is_last_floor() -> bool:
	return floor_index >= run.floors.size() - 1


## Arma el piso `index` desde cero (borra el anterior) y pone al jugador en la sala inicial.
func load_floor(index: int) -> void:
	floor_index = index
	theme = run.floors[index]
	RunState.floor_index = index
	RunState.floor_name = theme.display_name
	_clear_world()
	GameRNG.set_floor(index)
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.FLOOR)
	layout = FloorGenerator.generate(rng, _params())
	TemplatePicker.assign(layout, theme.templates, rng, theme.difficulty_bonus)
	_roll_offers()
	var room: Room = _ensure_room(layout.start)
	player.global_position = room.to_global(room.spawn_point())
	player.stop_motion()
	camera.global_position = room.global_position
	_enter(layout.start)
	EventBus.floor_changed.emit(index)


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
	visited.clear()
	discovered_secrets.clear()
	_opened_edges.clear()
	map_revealed = false
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


func _params() -> FloorParams:
	var params := FloorParams.new()
	params.room_count_min = theme.room_count_min
	params.room_count_max = theme.room_count_max
	params.min_boss_distance = theme.min_boss_distance
	return params


func _enter(cell: Vector2i) -> void:
	current_cell = cell
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
	room.door_entered.connect(_on_room_door_entered.bind(cell))
	room.door_unlock_requested.connect(_on_room_door_unlock_requested.bind(cell))
	room.cleared.connect(_on_room_cleared.bind(cell))
	rooms_root.add_child(room)
	_rooms[cell] = room
	return room


## Un pedestal en el tesoro, tres en la tienda y el premio del jefe, sorteados al generar el piso.
func _roll_offers() -> void:
	var loot: RandomNumberGenerator = GameRNG.stream(RngStreams.LOOT)
	for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.TREASURE):
		layout.get_slot(cell).offers.append(RunState.item_pool.draw(ItemData.POOL_TREASURE, loot))
	for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.SHOP):
		for _i: int in SHOP_OFFERS:
			layout.get_slot(cell).offers.append(RunState.item_pool.draw(ItemData.POOL_SHOP, loot))
	for cell: Vector2i in layout.cells_of_kind(RoomSlot.Kind.BOSS):
		layout.get_slot(cell).offers.append(RunState.item_pool.draw(ItemData.POOL_BOSS, loot))


## Al vencer al jefe aparece la salida: al piso siguiente, o la que gana la run en el último.
func _on_room_cleared(cell: Vector2i) -> void:
	if layout.get_slot(cell).kind != RoomSlot.Kind.BOSS:
		return
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
	Debug.add_command(self, "Volver al inicio", _go_to_kind.bind(RoomSlot.Kind.START))
	Debug.add_command(self, "Revelar mapa", _reveal_map)
	Debug.add_command(self, "Limpiar sala", _clear_current_room)
	Debug.add_command(self, "Siguiente piso (o ganar)", _on_exit_entered)


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
