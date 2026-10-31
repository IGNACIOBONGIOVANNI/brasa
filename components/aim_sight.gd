class_name AimSight
extends Node2D
## Mira láser de las armas con `sight` (franco tirador): una línea fina desde la boca del arma hasta la
## primera pared o roca. Se dibuja en coordenadas globales.

const RANGE: float = 320.0
const COLOR: Color = Color(1.0, 0.3, 0.35, 0.4)

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _shown: bool = false


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO


func is_shown() -> bool:
	return _shown


func show_line(from: Vector2, direction: Vector2) -> void:
	_from = from
	var to: Vector2 = from + direction * RANGE
	var query := PhysicsRayQueryParameters2D.create(from, to, PhysicsLayers.WALL)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	_to = hit.position if not hit.is_empty() else to
	_shown = true
	queue_redraw()


func hide_line() -> void:
	if _shown:
		_shown = false
		queue_redraw()


func _draw() -> void:
	if _shown:
		draw_line(_from, _to, COLOR, 1.0)
		draw_rect(Rect2(_to.round() - Vector2.ONE, Vector2(2, 2)), Color(COLOR, 0.9))
