class_name PulseWave
extends Node2D
## Anillo que se expande y se desvanece: la onda del Pulso y la de las explosiones.

@export var color: Color = Color("a8e6ff")
@export var duration: float = 0.35
@export var max_radius: float = 170.0

var _age: float = 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var t: float = clampf(_age / duration, 0.0, 1.0)
	var radius: float = max_radius * (1.0 - pow(1.0 - t, 3.0))
	draw_circle(Vector2.ZERO, radius, Color(color, 0.15 * (1.0 - t)))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, 1.0 - t), lerpf(4.0, 1.0, t))
