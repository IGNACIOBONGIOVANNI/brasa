class_name FloorController
extends Node
## Arma y maneja el piso: genera el layout (FloorGenerator + TemplatePicker con el stream FLOOR),
## construye cada sala la primera vez que se entra (después quedan armadas, con sus rocas rotas y
## sus pickups), mueve la cámara de sala en sala al cruzar una puerta, destapa las puertas a la
## secreta con explosiones y guarda lo que muestra el minimapa.

signal map_changed

const ROOM_SCENE: PackedScene = preload("res://world/room.tscn")
## Distancia entre centros de salas vecinas: más que una pantalla, así nunca se ve la de al lado.
const ROOM_STRIDE: Vector2 = Vector2(320, 192)
const TRANSITION_TIME: float = 0.3
## Margen extra (además del radio de la explosión) para destapar una puerta oculta.
const SECRET_REVEAL_MARGIN: float = 16.0

@export var theme: FloorTheme
@export var rooms_root: Node2D
@export var entities: Node2D
@export var player: Player
@export var camera: Camera2D

var layout: FloorLayout
var current_cell: Vector2i
var visited: Dictionary[Vector2i, bool] = {}
var discovered_secrets: Dictionary[Vector2i, bool] = {}
var map_revealed: bool = false
var _rooms: Dictionary[Vector2i, Room] = {}
## Conexiones con la secreta ya destapadas (clave: las dos celdas ordenadas).
var _opened_secret_edges: Dictionary[Vector4i, bool] = {}
var _transitioning: bool = false


func _ready() -> void:
	EventBus.exploded.connect(_on_exploded)
	GameRNG.set_floor(0)
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.FLOOR)
	layout = FloorGenerator.generate(rng, _params())
	TemplatePicker.assign(layout, theme.templates, rng)
	_register_dev_commands()
	var room: Room = _ensure_room(layout.start)
	player.global_position = room.to_global(room.spawn_point())
	camera.global_position = room.global_position
	_enter(layout.start)


func _exit_tree() -> void:
	if _transitioning:
		get_tree().paused = false


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
	var hidden_sides: Array[Vector2i] = []
	for next: Vector2i in layout.neighbors(cell):
		neighbors[next - cell] = layout.get_slot(next).kind
		if _is_hidden_edge(cell, next):
			hidden_sides.append(next - cell)
	var room := ROOM_SCENE.instantiate() as Room
	room.position = room_position(cell)
	room.setup(layout.get_slot(cell), theme, neighbors, hidden_sides, entities)
	room.door_entered.connect(_on_room_door_entered.bind(cell))
	rooms_root.add_child(room)
	_rooms[cell] = room
	return room


static func _edge_key(a: Vector2i, b: Vector2i) -> Vector4i:
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		return Vector4i(a.x, a.y, b.x, b.y)
	return Vector4i(b.x, b.y, a.x, a.y)


func _is_hidden_edge(a: Vector2i, b: Vector2i) -> bool:
	var touches_secret: bool = layout.get_slot(a).kind == RoomSlot.Kind.SECRET \
			or layout.get_slot(b).kind == RoomSlot.Kind.SECRET
	return touches_secret and not _opened_secret_edges.has(_edge_key(a, b))


## Destapa la conexión entre dos salas (una es la secreta), en las dos salas si ya están armadas.
func _open_secret_edge(a: Vector2i, b: Vector2i) -> void:
	if not _is_hidden_edge(a, b):
		return
	_opened_secret_edges[_edge_key(a, b)] = true
	for pair: Vector4i in [Vector4i(a.x, a.y, b.x, b.y), Vector4i(b.x, b.y, a.x, a.y)]:
		var room: Room = get_room(Vector2i(pair.x, pair.y))
		if room != null:
			room.reveal_door(Vector2i(pair.z - pair.x, pair.w - pair.y))
	for cell: Vector2i in [a, b]:
		if layout.get_slot(cell).kind == RoomSlot.Kind.SECRET:
			discovered_secrets[cell] = true
	map_changed.emit()


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
			_open_secret_edge(current_cell, current_cell + side)
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


func _go_to_kind(kind: RoomSlot.Kind) -> void:
	var cell: Vector2i = layout.first_of_kind(kind)
	if kind == RoomSlot.Kind.SECRET:
		for next: Vector2i in layout.neighbors(cell):
			_open_secret_edge(cell, next)
	move_to(cell)


func _reveal_map() -> void:
	map_revealed = true
	map_changed.emit()


func _clear_current_room() -> void:
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		(node as Enemy).health.kill()
