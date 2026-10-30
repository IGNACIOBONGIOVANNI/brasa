@tool
class_name PlayerVisual
extends Node2D
## Placeholder del jugador dibujado por código: sombra, cuerpo, ojos y arma que sigue la mira.
## Se reemplaza por un sprite animado manteniendo set_aim() y play_fire().

const FLASH_TIME: float = 0.05
const RECOIL_PIXELS: float = 2.0
## Píxeles por segundo que recupera el arma después del retroceso.
const RECOIL_RECOVERY: float = 20.0

@export var body_color: Color = Color("e8c170")
@export var outline_color: Color = Color("1b1420")
@export var gun_color: Color = Color("8a8a9e")
@export var flash_color: Color = Color("fff6d5")

var aim_direction: Vector2 = Vector2.RIGHT
var _flash_left: float = 0.0
var _recoil: float = 0.0


func set_aim(direction: Vector2) -> void:
	if direction != aim_direction:
		aim_direction = direction
		queue_redraw()


func play_fire() -> void:
	_flash_left = FLASH_TIME
	_recoil = RECOIL_PIXELS
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_left > 0.0 or _recoil > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
		_recoil = maxf(0.0, _recoil - RECOIL_RECOVERY * delta)
		queue_redraw()


func _draw() -> void:
	# Sombra achatada en los pies.
	draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	# Si apunta hacia arriba, el arma queda detrás del cuerpo.
	var gun_behind: bool = aim_direction.y < -0.3
	if gun_behind:
		_draw_gun()
	draw_circle(Vector2(0, -2), 6.0, outline_color)
	draw_circle(Vector2(0, -2), 5.0, body_color)
	var look: Vector2 = (aim_direction * 1.5).round()
	draw_rect(Rect2(Vector2(-3, -4) + look, Vector2(1, 2)), outline_color)
	draw_rect(Rect2(Vector2(1, -4) + look, Vector2(1, 2)), outline_color)
	if not gun_behind:
		_draw_gun()


func _draw_gun() -> void:
	draw_set_transform(Vector2(0, -1), aim_direction.angle())
	var start: float = 4.0 - _recoil
	draw_rect(Rect2(start - 1.0, -2.0, 8.0, 4.0), outline_color)
	draw_rect(Rect2(start, -1.0, 6.0, 2.0), gun_color)
	if _flash_left > 0.0:
		draw_circle(Vector2(start + 8.0, 0.0), 2.5, flash_color)
	draw_set_transform(Vector2.ZERO)
