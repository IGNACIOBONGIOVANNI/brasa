class_name ShockRing
extends Node2D
## Una onda de sonido que sale del jefe (TollMove): un anillo de `thickness` px que se agranda a `speed`
## px/s hasta `max_radius`, con un hueco de `gap` radianes hacia `gap_angle`. Lastima a quien quede
## sobre el anillo fuera del hueco (rodando no). Se ve siempre (sin sombra).

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const COLOR: Color = Color("e8b45a")
const CORE_COLOR: Color = Color("fff1c4")
const REACH: float = 3.0

var speed: float = 70.0
var max_radius: float = 170.0
var thickness: float = 4.0
var damage: float = 1.0
var gap_angle: float = 0.0
var gap: float = 0.9
var radius: float = 0.0


func _ready() -> void:
	add_to_group(BossMove.HAZARD_GROUP)
	material = UNSHADED


func _physics_process(delta: float) -> void:
	radius += speed * delta
	if radius >= max_radius:
		queue_free()
		return
	BossMove.hurt_players(get_tree(), damage, global_position, touches)


## true si `point` (global) queda sobre el anillo y fuera del hueco.
func touches(point: Vector2) -> bool:
	var offset: Vector2 = point - global_position
	if absf(offset.length() - radius) > thickness * 0.5 + REACH:
		return false
	return absf(angle_difference(offset.angle(), gap_angle)) > gap * 0.5


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var fade: float = 1.0 - clampf(radius / max_radius, 0.0, 1.0) * 0.6
	var from: float = gap_angle + gap * 0.5
	var to: float = gap_angle + TAU - gap * 0.5
	var points: int = maxi(12, int(radius * 0.6))
	draw_arc(Vector2.ZERO, radius, from, to, points, Color(COLOR, 0.85 * fade), thickness)
	draw_arc(Vector2.ZERO, radius, from, to, points, Color(CORE_COLOR, 0.7 * fade), 1.0)
	draw_arc(Vector2.ZERO, maxf(0.0, radius - thickness - 2.0), from, to, points, Color(COLOR, 0.25 * fade), 1.0)
