class_name DangerOverlay
extends Control
## Bordes rojos de peligro sobre toda la pantalla: un destello al recibir daño y, con la vida baja,
## un latido (borde que late y sonido del corazón). No toma el mouse.

const COLOR: Color = Color("e0464e")
const FLASH_TIME: float = 0.25
const FLASH_ALPHA: float = 0.45
## Segundos entre latidos con la vida baja.
const HEARTBEAT_INTERVAL: float = 0.9
const HEARTBEAT_ALPHA: float = 0.5
## Grosor de cada franja del borde y cuántas hay (cada una más transparente).
const BAND: float = 4.0
const BANDS: int = 3

var _flash_left: float = 0.0
var _low_health: bool = false
var _beat_left: float = 0.0
## 1 justo en el latido, baja a 0 hasta el siguiente.
var _beat: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func flash() -> void:
	_flash_left = FLASH_TIME
	queue_redraw()


func set_low_health(low: bool) -> void:
	if low == _low_health:
		return
	_low_health = low
	_beat_left = 0.0
	_beat = 0.0
	queue_redraw()


func is_low_health() -> bool:
	return _low_health


func _process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	if _low_health:
		_beat_left -= delta
		if _beat_left <= 0.0:
			_beat_left = HEARTBEAT_INTERVAL
			_beat = 1.0
			AudioManager.play_sfx(&"heartbeat")
		_beat = maxf(0.0, _beat - delta / HEARTBEAT_INTERVAL)
	if _flash_left > 0.0 or _low_health:
		queue_redraw()


func _draw() -> void:
	var alpha: float = maxf(FLASH_ALPHA * _flash_left / FLASH_TIME, HEARTBEAT_ALPHA * _beat if _low_health else 0.0)
	if alpha <= 0.0:
		return
	for i: int in BANDS:
		var inset: float = BAND * i
		var rect := Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)
		draw_rect(rect, Color(COLOR, alpha * (1.0 - float(i) / BANDS)), false, BAND)
