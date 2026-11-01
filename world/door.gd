class_name Door
extends Node2D
## Puerta entre dos salas, en el hueco de una pared. Se arma orientada como la de arriba y se rota
## según el lado. Abierta deja pasar y avisa cuando el jugador entra al hueco; cerrada (combate),
## oculta (sala secreta sin descubrir) o con candado (tienda) bloquea como una pared. Con candado,
## avisa cuando el jugador la toca desde adentro para abrirla con una llave.

signal player_entered
signal unlock_requested

enum Mode { OPEN, CLOSED, HIDDEN, LOCKED }

const DUST_SCENE: PackedScene = preload("res://fx/dust_puff.tscn")
## Dónde se levanta el polvo, a cada lado del hueco de la puerta.
const DUST_OFFSETS: Array[Vector2] = [Vector2(-10, 0), Vector2(10, 0)]
## Color del marco según la sala del otro lado.
const FRAME_COLORS: Dictionary[RoomSlot.Kind, Color] = {
	RoomSlot.Kind.BOSS: Color("b33a3a"),
	RoomSlot.Kind.TREASURE: Color("e2b84a"),
	RoomSlot.Kind.SHOP: Color("5fb36a"),
	RoomSlot.Kind.CHALLENGE: Color("e07a3a"),
	RoomSlot.Kind.ALTAR: Color("b03a62"),
	RoomSlot.Kind.WELL: Color("ffb35c"),
}

var side: Vector2i = Vector2i.UP
var leads_to: RoomSlot.Kind = RoomSlot.Kind.NORMAL
var mode: Mode = Mode.OPEN

@onready var _blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D
@onready var _trigger: Area2D = $Trigger
@onready var _unlock_area: Area2D = $UnlockArea
@onready var _visual: DoorVisual = $Visual


## Rotación para que el interior de la sala quede del lado correcto.
static func side_rotation(door_side: Vector2i) -> float:
	if door_side == Vector2i.RIGHT:
		return PI * 0.5
	if door_side == Vector2i.DOWN:
		return PI
	if door_side == Vector2i.LEFT:
		return -PI * 0.5
	return 0.0


## Llamar antes de agregarla al árbol.
func setup(door_side: Vector2i, kind: RoomSlot.Kind, initial_mode: Mode, theme: FloorTheme) -> void:
	side = door_side
	leads_to = kind
	mode = initial_mode
	rotation = side_rotation(door_side)
	var visual := $Visual as DoorVisual
	visual.wall_color = theme.wall_color
	visual.outline_color = theme.outline_color
	visual.frame_color = FRAME_COLORS.get(kind, theme.wall_color.lightened(0.25))


func _ready() -> void:
	_trigger.body_entered.connect(_on_trigger_body_entered)
	_unlock_area.body_entered.connect(_on_unlock_area_body_entered)
	_apply_mode()


func set_mode(new_mode: Mode) -> void:
	var was_open: bool = mode == Mode.OPEN
	mode = new_mode
	if is_node_ready():
		_apply_mode()
		if was_open != (mode == Mode.OPEN):
			_puff()


## Polvo al abrirse o cerrarse (solo visual).
func _puff() -> void:
	for offset: Vector2 in DUST_OFFSETS:
		var dust := Fx.spawn(get_tree(), DUST_SCENE, to_global(offset)) as CPUParticles2D
		dust.amount = 8


func _apply_mode() -> void:
	_blocker_shape.set_deferred(&"disabled", mode == Mode.OPEN)
	_visual.mode = mode


func _on_trigger_body_entered(body: Node2D) -> void:
	if mode == Mode.OPEN and body is Player:
		player_entered.emit()


func _on_unlock_area_body_entered(body: Node2D) -> void:
	if mode == Mode.LOCKED and body is Player:
		unlock_requested.emit()
