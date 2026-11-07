class_name CinematicBars
extends Control
## Las franjas negras de arriba y abajo durante una cinemática (EventBus.cinematic_changed): entran
## deslizándose, tapan el HUD de arriba y de abajo y se van al terminar.

const HEIGHT: float = 40.0
const SLIDE_TIME: float = 0.3
const COLOR: Color = Color(0.0, 0.0, 0.0, 1.0)
## Rótulo chico abajo a la derecha: cómo saltearla.
const HINT_COLOR: Color = Color(0.85, 0.82, 0.9, 0.7)

var _active: bool = false
var _amount: float = 0.0
var _hint: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint = MenuBuilder.label("Enter o rodar: saltear", 7, HINT_COLOR)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_hint)
	EventBus.cinematic_changed.connect(_on_cinematic_changed)
	visible = false


func is_showing() -> bool:
	return _active


func _on_cinematic_changed(active: bool) -> void:
	_active = active
	if active:
		visible = true


func _process(delta: float) -> void:
	var target: float = 1.0 if _active else 0.0
	_amount = move_toward(_amount, target, delta / SLIDE_TIME)
	if _amount <= 0.0 and not _active:
		visible = false
	_hint.visible = _active and _amount >= 1.0
	_hint.position = Vector2(size.x - 108.0, size.y - HEIGHT * 0.5 - 5.0)
	_hint.size = Vector2(100.0, 10.0)
	queue_redraw()


func _draw() -> void:
	var height: float = roundf(HEIGHT * _amount)
	draw_rect(Rect2(0, 0, size.x, height), COLOR)
	draw_rect(Rect2(0, size.y - height, size.x, height), COLOR)
