class_name PlayerMoveState
extends State
## Estado normal: caminar, apuntar, disparar, usar un Pulso, poner una bomba, recargar, cambiar de
## arma, usar el activo y empezar a rodar.

@onready var player: Player = owner as Player


func physics_update(delta: float) -> void:
	player.move_toward_velocity(player.read_move_input() * RunState.stats.move_speed, delta)
	player.update_aim()
	# Si todavía no puede rodar, el botón queda en el buffer unos ticks.
	if player.can_roll() and player.input_buffer.consume(&"dodge"):
		machine.transition_to(&"Roll")
		return
	player.try_pulse()
	player.try_bomb()
	player.try_weapon_actions()
	player.try_shoot(delta)
