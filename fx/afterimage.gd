class_name Afterimage
extends Node2D
## Fantasma que deja el jugador al rodar: un círculo de su color que se desvanece.

const LIFETIME: float = 0.22
const START_ALPHA: float = 0.5

var color: Color = Color.WHITE
var radius: float = 5.0
var _left: float = LIFETIME


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(color, START_ALPHA * _left / LIFETIME))
