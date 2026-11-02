@tool
class_name HeartsDisplay
extends Control
## Corazones del HUD dibujados por código (llenos, medios o vacíos), en filas de PER_ROW (con mucha
## vida bajan a otra fila en vez de taparse con los contadores). Tiembla al perder vida.

## Columnas que se pintan en un medio corazón (incluye la del centro).
const HALF_COLUMNS: int = 4
const SPACING: int = 9
const PER_ROW: int = 4
const ROW_HEIGHT: int = 8
const SHAKE_TIME: float = 0.3
const SHAKE_PIXELS: float = 1.0

@export var full_color: Color = Color("e0464e")
@export var empty_color: Color = Color("3a2a3f")
@export var outline_color: Color = Color("120c16")
@export var half_hearts: int = 6:
	set(value):
		half_hearts = value
		queue_redraw()
@export var max_half_hearts: int = 6:
	set(value):
		max_half_hearts = value
		queue_redraw()

var _shake_left: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO


func set_health(current: int, max_value: int) -> void:
	if current < half_hearts:
		_shake_left = SHAKE_TIME
	half_hearts = current
	max_half_hearts = max_value


## Cuántas filas ocupan los corazones.
func rows() -> int:
	return maxi(1, ceili(ceilf(max_half_hearts / 2.0) / PER_ROW))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _shake_left <= 0.0:
		return
	_shake_left = maxf(0.0, _shake_left - delta)
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.COSMETIC)
	_shake_offset = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).round() * SHAKE_PIXELS
	if _shake_left <= 0.0:
		_shake_offset = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var states: Array[HealthMath.Heart] = HealthMath.heart_states(half_hearts, max_half_hearts)
	for i: int in states.size():
		var origin := Vector2((i % PER_ROW) * SPACING, floori(float(i) / PER_ROW) * ROW_HEIGHT) + _shake_offset
		PixelBitmap.paint_outlined(self, PixelIcons.HEART, origin, empty_color, outline_color)
		if states[i] == HealthMath.Heart.FULL:
			PixelBitmap.paint(self, PixelIcons.HEART, origin, full_color)
		elif states[i] == HealthMath.Heart.HALF:
			PixelBitmap.paint(self, PixelIcons.HEART, origin, full_color, 0, HALF_COLUMNS)
