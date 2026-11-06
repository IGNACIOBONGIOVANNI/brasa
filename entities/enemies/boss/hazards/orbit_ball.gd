class_name OrbitBall
extends Node2D
## Una bola de hierro que gira alrededor del jefe (OrbitersMove): sale pegada a él, se aleja hasta
## `max_radius` y vuelve, girando a `turn_speed` radianes por segundo, durante `life` s. Lastima al
## tocarla (en `radius`). Si el jefe ya no está, se deshace.

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const IRON: Color = Color("4a4652")
const OUTLINE: Color = Color("1b1420")
const CHAIN: Color = Color("8a8f99")
const REACH: float = 3.0
const MIN_RADIUS: float = 14.0

var owner_id: int = 0
var angle: float = 0.0
var turn_speed: float = 2.5
var max_radius: float = 60.0
var life: float = 3.0
var radius: float = 5.0
var damage: float = 1.0
var _time: float = 0.0
var _orbit: float = MIN_RADIUS


func _ready() -> void:
	add_to_group(BossMove.HAZARD_GROUP)
	material = UNSHADED


func _physics_process(delta: float) -> void:
	_time += delta
	var center := instance_from_id(owner_id) as Node2D
	if center == null or _time >= life:
		queue_free()
		return
	angle += turn_speed * delta
	# Se abre y se cierra una vez en toda su vida (sin, de 0 a PI).
	_orbit = MIN_RADIUS + (max_radius - MIN_RADIUS) * sin(PI * clampf(_time / life, 0.0, 1.0))
	global_position = center.global_position + Vector2(0, -4) + Vector2.from_angle(angle) * _orbit
	BossMove.hurt_players(get_tree(), damage, global_position,
			func(at: Vector2) -> bool: return at.distance_to(global_position) <= radius + REACH)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# La cadena hasta el jefe (de a puntos) y la bola con un brillo.
	var back: Vector2 = -Vector2.from_angle(angle) * _orbit
	for k: int in 5:
		draw_rect(Rect2((back * (k + 1) / 6.0).round(), Vector2.ONE), CHAIN)
	draw_circle(Vector2.ZERO, radius + 1.0, OUTLINE)
	draw_circle(Vector2.ZERO, radius, IRON)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.35), maxf(1.0, radius * 0.3), IRON.lightened(0.4))
