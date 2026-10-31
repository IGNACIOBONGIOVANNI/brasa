class_name PlayerRollState
extends State
## Rodar: avanza rápido en la dirección del movimiento (o de la mira si está quieto) y es
## invulnerable todo el trayecto. No se puede disparar mientras dura. Al terminar empieza el cooldown.

## Velocidad al final del rol respecto de la inicial: arranca rápido y frena.
const END_SPEED_FACTOR: float = 0.55
const DUST_SCENE: PackedScene = preload("res://fx/dust_puff.tscn")
const AFTERIMAGE_SCENE: PackedScene = preload("res://fx/afterimage.tscn")
## Cada cuánto queda un fantasma del jugador mientras rueda.
const AFTERIMAGE_INTERVAL: float = 0.04

var _direction: Vector2 = Vector2.RIGHT
var _time_left: float = 0.0
var _afterimage_left: float = 0.0

@onready var player: Player = owner as Player


func enter(_previous: StringName) -> void:
	var move_input: Vector2 = player.read_move_input()
	_direction = (move_input if move_input != Vector2.ZERO else player.aim_direction).normalized()
	_time_left = player.roll_time
	player.health.grant_invulnerability(player.roll_time)
	player.weapon.release()
	player.cancel_bomb()
	player.visual.set_rolling(true)
	AudioManager.play_sfx(&"roll", 0.08)
	Fx.spawn(get_tree(), DUST_SCENE, player.global_position + Vector2(0, 4))


func exit() -> void:
	player.visual.set_rolling(false)
	player.start_roll_cooldown()
	# Sale caminando en la misma dirección, sin frenazo.
	player.move_velocity = _direction * minf(player.move_velocity.length(), RunState.stats.move_speed)


func physics_update(delta: float) -> void:
	_time_left -= delta
	_afterimage_left -= delta
	if _afterimage_left <= 0.0:
		_afterimage_left = AFTERIMAGE_INTERVAL
		var ghost := Fx.spawn(get_tree(), AFTERIMAGE_SCENE, player.global_position, Fx.DECALS_GROUP) as Afterimage
		ghost.color = player.visual.body_color
	var progress: float = 1.0 - clampf(_time_left / player.roll_time, 0.0, 1.0)
	player.move_velocity = _direction * player.roll_speed * lerpf(1.0, END_SPEED_FACTOR, progress)
	player.apply_velocity()
	player.update_aim()
	if _time_left <= 0.0:
		machine.transition_to(&"Move")
