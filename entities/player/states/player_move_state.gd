class_name PlayerMoveState
extends State
## Estado normal: caminar, apuntar, disparar, usar un Pulso, poner una bomba, recargar, cambiar de
## arma, usar el activo y empezar a rodar (arriba de un armazón, rodar es saltar afuera).

## Desde esta velocidad cuenta como caminando (las patas del armazón se mueven).
const WALK_SPEED: float = 5.0

@onready var player: Player = owner as Player


func physics_update(delta: float) -> void:
	player.move_toward_velocity(player.read_move_input() * player.move_speed(), delta)
	player.visual.set_walking(player.move_velocity.length() > WALK_SPEED)
	player.leave_steps(delta)
	player.update_aim()
	# Si todavía no puede rodar, el botón queda en el buffer unos ticks.
	if player.can_roll() and player.input_buffer.consume(&"dodge"):
		player.eject()
		machine.transition_to(&"Roll")
		return
	player.try_pulse()
	player.try_bomb(delta)
	player.try_weapon_actions()
	player.try_shoot(delta)
