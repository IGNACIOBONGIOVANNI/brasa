class_name EnemyTelegraphState
extends State
## Aviso antes de cada ataque: se frena, parpadea, muestra un "!" y suena.

const PULSE_COLOR: Color = Color("ffd166")

var _time_left: float = 0.0

@onready var enemy: Enemy = owner as Enemy


func enter(_previous: StringName) -> void:
	_time_left = enemy.data.telegraph_time
	enemy.flash.start_pulse(PULSE_COLOR)
	enemy.visual.set_alert(true)
	AudioManager.play_sfx(&"telegraph", 0.05)


func exit() -> void:
	enemy.flash.stop_pulse()
	enemy.visual.set_alert(false)


func physics_update(delta: float) -> void:
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	enemy.look_at_target()
	_time_left -= delta
	if _time_left <= 0.0:
		machine.transition_to(&"Attack")
