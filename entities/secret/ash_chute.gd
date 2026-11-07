class_name AshChute
extends Area2D
## La boca del Cenicero (camino secreto): una rejilla en el piso de la sala del jefe del piso de la boca
## (RunConfig.secret_gate_floor), tapada con hollín duro. Se ve desde que se entra a la sala, con una
## llama grabada (la misma del Ascua). Con la sala limpia, pisarla con el Ascua la gasta
## (RunState.spend_ember) y el hollín arde hasta abrirse; sin el Ascua, un cartel avisa que sin fuego no
## cede. Abierta, hay que salir y volver a pisarla para bajar (`descended`), así nadie baja sin querer
## antes de agarrar el premio del jefe.

signal descended

enum Mode { SEALED, BURNING, OPEN }

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const BURN_TIME: float = 1.2
const SIZE: Vector2 = Vector2(16, 12)
const SEALED_TITLE: String = "Boca tapiada"
const SEALED_HINT: String = "Hollín frío, duro como piedra. Sin fuego no cede."
const OPEN_TITLE: String = "La boca del Cenicero"
const OPEN_HINT: String = "El Ascua prende el hollín. Abajo, algo barre."
const OUTLINE_COLOR: Color = Color("120c16")
const IRON_COLOR: Color = Color("4a4552")
const SOOT_COLOR: Color = Color("1e1a22")
const MARK_COLOR: Color = Color("ff8a3d")
const HOLE_COLOR: Color = Color("050308")

var room: Room
var mode: Mode = Mode.SEALED
var _burn_left: float = 0.0
var _touching: bool = false
var _needs_exit: bool = false
var _used: bool = false
var _time: float = 0.0


func _ready() -> void:
	material = UNSHADED
	collision_layer = PhysicsLayers.TRIGGER
	collision_mask = PhysicsLayers.PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE - Vector2(2, 2)
	shape.shape = rect
	add_child(shape)
	if RunState.secret == RunState.Secret.OPENED:
		mode = Mode.OPEN


func _physics_process(delta: float) -> void:
	if mode == Mode.BURNING:
		_burn_left -= delta
		if _burn_left <= 0.0:
			mode = Mode.OPEN
			_needs_exit = _player_on()
			AudioManager.play_sfx(&"exit_open")
			EventBus.shake_requested.emit(0.3)
		return
	var on: bool = _player_on()
	var entering: bool = on and not _touching
	_touching = on
	if not on:
		_needs_exit = false
		return
	if not _room_clear():
		return
	if mode == Mode.OPEN:
		if not _needs_exit and not _used:
			_used = true
			descended.emit()
		return
	if not entering:
		return
	if RunState.spend_ember():
		_burn()
	else:
		EventBus.message_requested.emit(SEALED_TITLE, SEALED_HINT)


## El Ascua prende el hollín: arde un momento y queda abierta.
func _burn() -> void:
	mode = Mode.BURNING
	_burn_left = BURN_TIME
	EventBus.message_requested.emit(OPEN_TITLE, OPEN_HINT)
	AudioManager.play_sfx(&"molten")
	AudioManager.play_sfx(&"secret_found")
	var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position) as CPUParticles2D
	burst.color = MARK_COLOR


func _room_clear() -> bool:
	return room == null or room.phase == Room.Phase.CLEARED


func _player_on() -> bool:
	for body: Node2D in get_overlapping_bodies():
		if body is Player and not (body as Player).is_dead():
			return true
	return false


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-SIZE * 0.5, SIZE)
	draw_rect(rect.grow(1.0), OUTLINE_COLOR)
	if mode == Mode.OPEN:
		# El pozo abierto: oscuro, con un resplandor de brasas allá abajo y ceniza que sube.
		draw_rect(rect, IRON_COLOR.darkened(0.3))
		draw_rect(rect.grow(-1.0), HOLE_COLOR)
		var glow: float = 0.5 + 0.3 * sin(_time * 2.5)
		draw_rect(Rect2(-4, 1, 8, 3), Color(MARK_COLOR.darkened(0.4), glow))
		draw_rect(Rect2(-2, 2, 4, 1), Color(MARK_COLOR, glow))
		for k: int in 3:
			var rise: float = fmod(_time * 10.0 + k * 5.0, 14.0)
			draw_rect(Rect2(Vector2(-4 + k * 4, 3.0 - rise).round(), Vector2.ONE), Color(0.7, 0.66, 0.72, 0.8 * (1.0 - rise / 14.0)))
		return
	# Rejilla de hierro tapada de hollín, con una llama grabada.
	draw_rect(rect, IRON_COLOR)
	draw_rect(rect.grow(-1.0), SOOT_COLOR)
	for x: int in [-5, -2, 1, 4]:
		draw_line(Vector2(x, rect.position.y + 1), Vector2(x, rect.end.y - 1), IRON_COLOR.darkened(0.2), 1.0)
	var heat: float = 0.0
	if mode == Mode.BURNING:
		heat = 1.0 - _burn_left / BURN_TIME
		# El hollín se pone al rojo desde el medio hacia afuera y se desarma.
		draw_rect(Rect2(-SIZE.x * 0.5 * heat, -SIZE.y * 0.5 * heat, SIZE.x * heat, SIZE.y * heat).grow(-1.0),
				Color(MARK_COLOR, 0.8 * (1.0 - heat * 0.5)))
		for k: int in 5:
			var rise: float = fmod(_time * 30.0 + k * 7.0, 20.0)
			draw_rect(Rect2(Vector2(-6 + k * 3, -rise).round(), Vector2.ONE), Color(1.0, 0.82, 0.4, 1.0 - rise / 20.0))
	var mark: float = 0.3 + 0.15 * sin(_time * 2.0) + heat * 0.6
	var flame := PackedVector2Array([Vector2(0, -4), Vector2(2, -1), Vector2(2, 2), Vector2(0, 3), Vector2(-2, 2),
			Vector2(-2, -1), Vector2(0, -4)])
	draw_polyline(flame, Color(MARK_COLOR, mark), 1.0)
