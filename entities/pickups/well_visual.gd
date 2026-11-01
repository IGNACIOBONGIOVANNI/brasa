@tool
class_name WellVisual
extends Node2D
## Placeholder del Pozo de brasas: aro de piedra con agua que brilla y burbujea; seco, solo el hueco.

const STONE_COLOR: Color = Color("6b6278")
const STONE_TOP_COLOR: Color = Color("847a92")
const OUTLINE_COLOR: Color = Color("120c16")
const WATER_COLOR: Color = Color("ff9a3c")
const WATER_LIGHT_COLOR: Color = Color("ffd27a")
const DRY_COLOR: Color = Color("1a1320")
const BUBBLE_SPEED: float = 3.0

@export var dry: bool = false:
	set(value):
		dry = value
		queue_redraw()

var _time: float = 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or dry:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, 9.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, 8.0, STONE_COLOR)
	draw_arc(Vector2.ZERO, 7.5, PI, TAU, 12, STONE_TOP_COLOR, 1.0)
	draw_circle(Vector2.ZERO, 5.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, 4.0, DRY_COLOR if dry else WATER_COLOR)
	draw_set_transform(Vector2.ZERO)
	if dry:
		return
	for i: int in 3:
		var t: float = fmod(_time * BUBBLE_SPEED + i * 1.3, 3.0)
		if t < 1.0:
			var at := Vector2(-2 + i * 2, 1 - roundf(t * 3.0))
			draw_rect(Rect2(at, Vector2.ONE), WATER_LIGHT_COLOR)
