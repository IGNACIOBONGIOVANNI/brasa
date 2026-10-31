class_name BombAim
extends Node2D
## Marca de dónde va a caer la bomba mientras se mantiene el botón: un arco punteado desde el jugador
## y, en el piso, el radio de la explosión. Se dibuja en coordenadas globales.

const ARC_HEIGHT: float = 18.0
const DOTS: int = 12
const COLOR: Color = Color("ff9a3c")

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _shown: bool = false
var _time: float = 0.0


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO


func is_shown() -> bool:
	return _shown


func show_at(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	_shown = true
	queue_redraw()


func hide_aim() -> void:
	if _shown:
		_shown = false
		queue_redraw()


func _process(delta: float) -> void:
	if _shown:
		_time += delta
		queue_redraw()


func _draw() -> void:
	if not _shown:
		return
	# Los puntos avanzan por el arco, así se lee hacia dónde va.
	var shift: float = fmod(_time * 2.0, 1.0)
	for i: int in DOTS:
		var t: float = (i + shift) / DOTS
		var point: Vector2 = _from.lerp(_to, t) + Vector2(0, -ARC_HEIGHT * 4.0 * t * (1.0 - t))
		draw_rect(Rect2(point.round(), Vector2.ONE), Color(COLOR, 0.8))
	var pulse: float = 0.45 + 0.25 * sin(_time * 10.0)
	draw_circle(_to, Bomb.RADIUS, Color(COLOR, 0.08))
	draw_arc(_to, Bomb.RADIUS, 0.0, TAU, 32, Color(COLOR, pulse), 1.0)
	draw_rect(Rect2(_to.round() - Vector2(1, 0), Vector2(3, 1)), COLOR)
	draw_rect(Rect2(_to.round() - Vector2(0, 1), Vector2(1, 3)), COLOR)
