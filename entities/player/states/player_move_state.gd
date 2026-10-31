class_name PlayerMoveState
extends State
## Estado normal: caminar, apuntar, disparar, usar un Pulso y empezar a rodar.

@onready var player: Player = owner as Player


func physics_update(delta: float) -> void:
	player.move_toward_velocity(player.read_move_input() * RunState.stats.move_speed, delta)
	player.update_aim()
	# Si todavía no puede rodar, el botón queda en el buffer unos ticks.
	if player.can_roll() and player.input_buffer.consume(&"dodge"):
		machine.transition_to(&"Roll")
		return
	player.try_pulse()
	player.try_shoot()
