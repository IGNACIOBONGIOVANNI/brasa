class_name ThreadBall
extends Node2D
## Un ovillo que rueda solo (ThreadTrailMove): va derecho a `speed` px/s, rebota en los bordes de
## `area` y deja atrás un hilo tirante que corta; cada tramo dura `trail_time` s. Lastima el ovillo y
## el hilo (el tramo pegado al ovillo no, así no corta donde recién pasa). Dura `life` s y después se
## deshace, con el hilo que se va apagando.

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const OUTLINE: Color = Color("1b1420")
const REACH: float = 2.5
## Cada cuánto deja un punto de hilo.
const STEP: float = 5.0
## El hilo más nuevo (estos puntos) todavía no corta.
const SAFE_POINTS: int = 2

var color: Color = Color("d9506a")
var direction: Vector2 = Vector2.RIGHT
var speed: float = 90.0
var life: float = 3.0
var trail_time: float = 2.0
var radius: float = 5.0
var damage: float = 1.0
var area: Rect2 = Rect2(-120, -72, 240, 144)
var _time: float = 0.0
var _points: PackedVector2Array = []
var _born: PackedFloat32Array = []


func _ready() -> void:
	add_to_group(BossMove.HAZARD_GROUP)
	material = UNSHADED


func _physics_process(delta: float) -> void:
	_time += delta
	while not _born.is_empty() and _time - _born[0] > trail_time:
		_points.remove_at(0)
		_born.remove_at(0)
	if _time < life:
		_roll(delta)
	elif _points.is_empty():
		queue_free()
		return
	BossMove.hurt_players(get_tree(), damage, global_position, touches)


func _roll(delta: float) -> void:
	var next: Vector2 = global_position + direction * speed * delta
	var inner: Rect2 = area.grow(-radius)
	if next.x < inner.position.x or next.x > inner.end.x:
		direction.x = -direction.x
	if next.y < inner.position.y or next.y > inner.end.y:
		direction.y = -direction.y
	global_position = Vector2(clampf(next.x, inner.position.x, inner.end.x), clampf(next.y, inner.position.y, inner.end.y))
	if _points.is_empty() or _points[-1].distance_to(global_position) >= STEP:
		_points.append(global_position)
		_born.append(_time)


## true si `point` (global) toca el ovillo o un tramo del hilo que ya corta.
func touches(point: Vector2) -> bool:
	if _time < life and point.distance_to(global_position) <= radius + REACH:
		return true
	for i: int in _points.size() - 1 - SAFE_POINTS:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, _points[i], _points[i + 1])
		if closest.distance_to(point) <= REACH:
			return true
	return false


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Los puntos del hilo son globales: se dibujan corridos a donde está el ovillo.
	for i: int in _points.size() - 1:
		var age: float = (_time - _born[i]) / trail_time
		var alpha: float = clampf(1.0 - age, 0.15, 1.0)
		var from: Vector2 = _points[i] - global_position
		var to: Vector2 = _points[i + 1] - global_position
		draw_line(from, to, Color(OUTLINE, 0.6 * alpha), 3.0)
		draw_line(from, to, Color(color.lightened(0.25), alpha), 1.0)
	if _time >= life:
		return
	var spin: float = _time * 10.0
	draw_circle(Vector2.ZERO, radius + 1.0, OUTLINE)
	draw_circle(Vector2.ZERO, radius, color)
	for k: int in 3:
		var axis: Vector2 = Vector2.from_angle(spin + PI * k / 3.0) * (radius - 1.0)
		draw_line(-axis, axis, color.darkened(0.3), 1.0)
