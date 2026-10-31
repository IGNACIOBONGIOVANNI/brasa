@tool
class_name EnemyVisual
extends Node2D
## Placeholder de enemigo dibujado por código. El estilo sale de EnemyData.visual_style:
## HORNED (cuernos, embiste), EYE (un ojo grande que sigue al jugador), LANTERN (rombo con núcleo).
## Muestra la aparición, el aplastamiento al recibir un golpe y un "!" durante el telegraph.
## Se reemplaza por un sprite animado manteniendo la misma interfaz.

const ALERT_COLOR: Color = Color("ffd166")
const OUTLINE_COLOR: Color = Color("1b1420")
const HORN_COLOR: Color = Color("e8dcc0")
const EYE_WHITE: Color = Color("f2efe6")
const HIT_SQUASH_TIME: float = 0.12
## Centro del cuerpo respecto del origen (que está en los pies).
const BODY_OFFSET: Vector2 = Vector2(0, -2)

@export var style: EnemyData.VisualStyle = EnemyData.VisualStyle.HORNED:
	set(value):
		style = value
		queue_redraw()
@export var radius: float = 7.0:
	set(value):
		radius = value
		queue_redraw()
@export var body_color: Color = Color("c4553f"):
	set(value):
		body_color = value
		queue_redraw()

var look_direction: Vector2 = Vector2.DOWN
var _alert: bool = false
var _charging: bool = false
var _squash_left: float = 0.0
var _spawn_duration: float = 0.0
var _spawn_left: float = 0.0
var _time: float = 0.0


func configure(data: EnemyData) -> void:
	style = data.visual_style
	radius = data.visual_radius
	body_color = data.body_color


func set_look(direction: Vector2) -> void:
	look_direction = direction


func set_alert(alert: bool) -> void:
	_alert = alert


func set_charging(charging: bool) -> void:
	_charging = charging


func play_hit() -> void:
	_squash_left = HIT_SQUASH_TIME


## Crece desde chiquito durante `duration` segundos.
func play_spawn(duration: float) -> void:
	_spawn_duration = duration
	_spawn_left = duration


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_squash_left = maxf(0.0, _squash_left - delta)
	_spawn_left = maxf(0.0, _spawn_left - delta)
	queue_redraw()


func _draw() -> void:
	var appear: float = 1.0
	if _spawn_duration > 0.0:
		appear = 1.0 - _spawn_left / _spawn_duration
	# Sombra.
	draw_set_transform(Vector2(0, radius * 0.6), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius * 0.9 * appear, Color(0, 0, 0, 0.35))
	# Cuerpo: aplastado al recibir un golpe, inclinado hacia adelante al embestir.
	var squash: float = _squash_left / HIT_SQUASH_TIME
	var body_scale := Vector2(1.0 + 0.25 * squash, 1.0 - 0.2 * squash) * lerpf(0.3, 1.0, appear)
	var lean: Vector2 = look_direction * 1.5 if _charging else Vector2.ZERO
	draw_set_transform(BODY_OFFSET + lean, 0.0, body_scale)
	match style:
		EnemyData.VisualStyle.HORNED:
			_draw_horned()
		EnemyData.VisualStyle.EYE:
			_draw_eye()
		EnemyData.VisualStyle.LANTERN:
			_draw_lantern()
	draw_set_transform(Vector2.ZERO)
	if _alert:
		var origin := Vector2(0, BODY_OFFSET.y - radius - 7.0)
		PixelBitmap.paint_outlined(self, PixelIcons.ALERT, origin, ALERT_COLOR, OUTLINE_COLOR)


func _draw_horned() -> void:
	for side: float in [-1.0, 1.0]:
		var horn := PackedVector2Array([
			Vector2(side * radius * 0.35, -radius * 0.7),
			Vector2(side * radius * 1.05, -radius * 1.3),
			Vector2(side * radius * 0.8, -radius * 0.3),
		])
		draw_colored_polygon(horn, HORN_COLOR)
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius - 1.0, body_color)
	var look: Vector2 = (look_direction * 2.0).round()
	draw_rect(Rect2(Vector2(-4, -1) + look, Vector2(2, 1)), OUTLINE_COLOR)
	draw_rect(Rect2(Vector2(2, -1) + look, Vector2(2, 1)), OUTLINE_COLOR)


func _draw_eye() -> void:
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius - 1.0, body_color)
	var eye_center: Vector2 = (look_direction * 1.0).round()
	draw_circle(eye_center, radius * 0.55, EYE_WHITE)
	draw_circle(eye_center + (look_direction * radius * 0.25).round(), radius * 0.25, OUTLINE_COLOR)


func _draw_lantern() -> void:
	var outer: float = radius
	draw_colored_polygon(_diamond(outer + 1.0), OUTLINE_COLOR)
	draw_colored_polygon(_diamond(outer), body_color)
	var glow: float = 0.5 + 0.5 * sin(_time * 4.0)
	draw_circle(Vector2.ZERO, radius * 0.45, body_color.lightened(0.3 + 0.3 * glow))
	draw_circle(Vector2.ZERO, radius * 0.2, Color.WHITE)


func _diamond(size: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -size), Vector2(size, 0), Vector2(0, size), Vector2(-size, 0)])
