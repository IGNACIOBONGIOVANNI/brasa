@tool
class_name PulseDisplay
extends Control
## Cargas de Pulso del HUD: un rombo por carga.

const ICON: PackedStringArray = [
	"..#..",
	".###.",
	"#####",
	".###.",
	"..#..",
]
const SPACING: int = 7

@export var color: Color = Color("a8e6ff")
@export var outline_color: Color = Color("120c16")
@export var count: int = 2:
	set(value):
		count = value
		queue_redraw()


func set_count(value: int) -> void:
	count = value


func _draw() -> void:
	for i: int in count:
		PixelBitmap.paint_outlined(self, ICON, Vector2(i * SPACING, 0), color, outline_color)
