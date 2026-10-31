class_name PlayerDeadState
extends State
## Muerte: el jugador queda tirado, se avisa por EventBus y main.gd reinicia la run.

const DEATH_TRAUMA: float = 0.8
const DEATH_HITSTOP: float = 0.15
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")

@onready var player: Player = owner as Player


func enter(_previous: StringName) -> void:
	player.input_buffer.clear()
	player.weapon.release()
	player.flash.blink(0.0)
	player.visual.set_dead(true)
	EventBus.shake_requested.emit(DEATH_TRAUMA)
	EventBus.hitstop_requested.emit(DEATH_HITSTOP)
	AudioManager.play_sfx(&"player_die")
	var burst := Fx.spawn(get_tree(), BURST_SCENE, player.global_position) as CPUParticles2D
	burst.color = player.visual.body_color
	burst.amount = 20
	EventBus.player_died.emit()


func physics_update(delta: float) -> void:
	# Termina de deslizarse por el empujón del golpe y queda quieto.
	player.move_toward_velocity(Vector2.ZERO, delta)
