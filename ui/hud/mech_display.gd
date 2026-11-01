class_name MechDisplay
extends Control
## Barra de blindaje del armazón que maneja el jugador (debajo de los contadores). Escondida a pie;
## tiembla al recibir un golpe y parpadea con poco blindaje.

const OUTLINE_COLOR: Color = Color("120c16")
const EMPTY_COLOR: Color = Color("2a2430")
const SHAKE_TIME: float = 0.25
const LOW_FRACTION: float = 0.35

var _mech: MechData
var _fraction: float = 1.0
var _shake_left: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func set_mech(mech: MechData) -> void:
	_mech = mech
	visible = mech != null
	queue_redraw()


func set_armor(current: float, max_value: float) -> void:
	var fraction: float = clampf(current / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	if fraction < _fraction:
		_shake_left = SHAKE_TIME
	_fraction = fraction
	queue_redraw()


func armor_fraction() -> float:
	return _fraction


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_shake_left = maxf(0.0, _shake_left - delta)
	queue_redraw()


func _draw() -> void:
	if _mech == null:
		return
	var offset := Vector2(roundf(sin(_time * 60.0)) if _shake_left > 0.0 else 0.0, 0)
	var bar := Rect2(offset, size)
	draw_rect(bar, OUTLINE_COLOR)
	var inner: Rect2 = bar.grow(-1.0)
	draw_rect(inner, EMPTY_COLOR)
	var fill_color: Color = _mech.accent_color
	if _fraction < LOW_FRACTION and int(_time * 6.0) % 2 == 0:
		fill_color = fill_color.lightened(0.5)
	draw_rect(Rect2(inner.position, Vector2(roundf(inner.size.x * _fraction), inner.size.y)), fill_color)
