class_name PulseWave
extends Node2D
## Anillo que se expande desde el jugador cuando usa un Pulso.

const DURATION: float = 0.35
const MAX_RADIUS: float = 170.0

@export var color: Color = Color("a8e6ff")

var _age: float = 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var t: float = clampf(_age / DURATION, 0.0, 1.0)
	var radius: float = MAX_RADIUS * (1.0 - pow(1.0 - t, 3.0))
	draw_circle(Vector2.ZERO, radius, Color(color, 0.15 * (1.0 - t)))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, 1.0 - t), lerpf(4.0, 1.0, t))
