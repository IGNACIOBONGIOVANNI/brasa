class_name EnemyTelegraphState
extends State
## Aviso antes de cada ataque: se frena, parpadea, muestra un "!" y suena. Los de rayo (BEAM) además
## muestran la línea por donde va a salir: sigue al jugador y en el último tramo queda fija, así se
## puede esquivar.

const PULSE_COLOR: Color = Color("ffd166")
## BEAM: fracción final del aviso con la línea ya fija.
const BEAM_LOCK: float = 0.35

var _time_left: float = 0.0

@onready var enemy: Enemy = owner as Enemy


func enter(_previous: StringName) -> void:
	_time_left = enemy.behavior.telegraph_time
	enemy.flash.start_pulse(PULSE_COLOR)
	enemy.visual.set_alert(true)
	AudioManager.play_sfx(&"telegraph", 0.05)
	_aim_beam()


func exit() -> void:
	enemy.flash.stop_pulse()
	enemy.visual.set_alert(false)


func physics_update(delta: float) -> void:
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	enemy.look_at_target()
	_time_left -= delta
	if enemy.behavior.attack_kind == EnemyData.AttackKind.BEAM:
		if _time_left > enemy.behavior.telegraph_time * BEAM_LOCK:
			_aim_beam()
		enemy.beam.preview(enemy.beam_origin(), enemy.beam_direction)
	if _time_left <= 0.0:
		machine.transition_to(&"Attack")


func _aim_beam() -> void:
	var offset: Vector2 = enemy.to_target()
	if offset != Vector2.ZERO:
		enemy.beam_direction = offset.normalized()
