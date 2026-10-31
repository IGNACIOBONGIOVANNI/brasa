class_name Trapdoor
extends Area2D
## Salida que aparece al vencer al jefe: una trampilla al piso siguiente o, en el último piso, la
## salida que termina la run. Tarda un momento en abrirse para que no se active sola si el jugador
## está parado justo ahí.

signal entered

const ARM_TIME: float = 0.8
const OUTLINE_COLOR: Color = Color("120c16")
const HOLE_COLOR: Color = Color("050308")
const FRAME_COLOR: Color = Color("6b6278")
const FINAL_COLOR: Color = Color("a8e6ff")
const SIZE: Vector2 = Vector2(18, 14)

## true = salida final (termina la run ganando).
var final: bool = false
var _arm_left: float = ARM_TIME
var _time: float = 0.0
var _used: bool = false


func _ready() -> void:
	AudioManager.play_sfx(&"exit_open")


func _physics_process(delta: float) -> void:
	_arm_left = maxf(0.0, _arm_left - delta)
	if _arm_left > 0.0 or _used:
		return
	for body: Node2D in get_overlapping_bodies():
		if body is Player and not (body as Player).is_dead():
			_used = true
			entered.emit()
			return


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var opening: float = 1.0 - _arm_left / ARM_TIME
	var rect := Rect2(-SIZE * 0.5 * opening, SIZE * opening)
	if final:
		var glow: float = 0.6 + 0.4 * sin(_time * 5.0)
		draw_circle(Vector2.ZERO, 11.0 * opening, Color(FINAL_COLOR, 0.25 * glow))
		draw_circle(Vector2.ZERO, 8.0 * opening, OUTLINE_COLOR)
		draw_circle(Vector2.ZERO, 7.0 * opening, Color(FINAL_COLOR, glow))
		draw_circle(Vector2.ZERO, 4.0 * opening, Color.WHITE)
		return
	draw_rect(rect.grow(2.0), OUTLINE_COLOR)
	draw_rect(rect.grow(1.0), FRAME_COLOR)
	draw_rect(rect, HOLE_COLOR)
	# Escalones que bajan.
	for i: int in 3:
		var y: float = rect.position.y + 3.0 + i * 4.0
		if y < rect.end.y - 1.0:
			draw_rect(Rect2(rect.position.x + 2.0, y, rect.size.x - 4.0, 1.0), FRAME_COLOR.darkened(0.5))
