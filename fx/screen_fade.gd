class_name ScreenFade
extends CanvasLayer
## Fundido a negro de toda la pantalla (entre pisos). Funciona con el juego en pausa.

const DURATION: float = 0.4

var _rect: ColorRect


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func fade_out() -> void:
	await _fade_to(1.0)


func fade_in() -> void:
	await _fade_to(0.0)


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_rect, ^"color:a", alpha, DURATION)
	await tween.finished
