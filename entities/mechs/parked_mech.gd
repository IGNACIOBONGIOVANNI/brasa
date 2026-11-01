class_name ParkedMech
extends Area2D
## Un armazón parado, sin piloto: en el Galpón o donde el jugador saltó afuera (con el blindaje que le
## quedaba). Tocarlo lo sube; después de bajarse hay que alejarse antes de volver a subir.

## Recién bajado, no se vuelve a subir antes de esto (aunque todavía no se haya alejado).
const REBOARD_DELAY: float = 0.5

var data: MechData
var armor: float = 0.0
## Hasta que el jugador se aleje no se vuelve a subir (recién se bajó).
var _waiting_exit: bool = false
var _delay: float = 0.0

@onready var _visual: ParkedMechVisual = $Visual


## Llamar antes de agregarlo al árbol. `armor_left` negativo = blindaje completo. `just_left`: el
## jugador recién saltó afuera.
func setup(mech: MechData, armor_left: float = -1.0, just_left: bool = false) -> void:
	data = mech
	armor = mech.armor if armor_left < 0.0 else armor_left
	_waiting_exit = just_left
	_delay = REBOARD_DELAY if just_left else 0.0


func _ready() -> void:
	assert(data != null, "ParkedMech: falta llamar setup()")
	_visual.configure(data, armor / data.armor)


func _physics_process(delta: float) -> void:
	_delay = maxf(0.0, _delay - delta)
	var player: Player = null
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			player = body as Player
	if player == null:
		if _delay <= 0.0:
			_waiting_exit = false
		return
	if _waiting_exit or _delay > 0.0 or player.is_dead() or player.is_piloting():
		return
	player.board(data, armor)
	queue_free()
