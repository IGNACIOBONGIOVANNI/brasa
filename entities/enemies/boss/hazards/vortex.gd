class_name Vortex
extends Node2D
## El remolino del ojo del huracán (VortexMove): brazos de viento que giran hacia el centro, más
## tenues durante el aviso. Solo se ve; el tirón lo hace el movimiento.

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const COLOR: Color = Color("dfe9f5")
const ARMS: int = 5

var radius: float = 120.0
## 0 = aviso (tenue), 1 = soplando.
var strength: float = 0.3
var spin_speed: float = 2.5
var _time: float = 0.0


func _ready() -> void:
	add_to_group(BossMove.HAZARD_GROUP)
	material = UNSHADED


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var spin: float = -_time * spin_speed
	for arm: int in ARMS:
		var points := PackedVector2Array()
		for k: int in 14:
			var t: float = float(k) / 13.0
			var angle: float = spin + TAU * arm / ARMS + t * 2.6
			points.append(Vector2.from_angle(angle) * radius * (1.0 - t * 0.85))
		draw_polyline(points, Color(COLOR, 0.12 + 0.3 * strength), 1.0)
	var pull: float = fmod(_time * 0.8, 1.0)
	draw_arc(Vector2.ZERO, radius * (1.0 - pull), 0.0, TAU, 32, Color(COLOR, 0.25 * strength * pull), 1.0)
