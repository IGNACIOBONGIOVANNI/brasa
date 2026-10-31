@tool
class_name DoorVisual
extends Node2D
## Dibujo placeholder de una puerta, orientada como la de la pared de arriba (el interior de la sala
## queda hacia +y). Abierta: hueco oscuro con marco del color de la sala de al lado. Cerrada: además
## rejas. Oculta: igual que la pared, con un par de grietas apenas visibles.

const SIZE: Vector2 = Vector2(32, 16)
const POST_WIDTH: float = 3.0
const BAR_SPACING: float = 5.0
const HOLE_COLOR: Color = Color("08060b")

@export var mode: Door.Mode = Door.Mode.OPEN:
	set(value):
		mode = value
		queue_redraw()
@export var frame_color: Color = Color("6a6078"):
	set(value):
		frame_color = value
		queue_redraw()
@export var wall_color: Color = Color(0.29, 0.247, 0.333):
	set(value):
		wall_color = value
		queue_redraw()
@export var outline_color: Color = Color(0.106, 0.078, 0.125):
	set(value):
		outline_color = value
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(-SIZE * 0.5, SIZE)
	if mode == Door.Mode.HIDDEN:
		_draw_hidden(rect)
		return
	draw_rect(rect, HOLE_COLOR)
	if mode == Door.Mode.CLOSED:
		var x: float = rect.position.x + POST_WIDTH + 2.0
		while x < rect.end.x - POST_WIDTH - 1.0:
			draw_rect(Rect2(x, rect.position.y, 1.0, SIZE.y), frame_color.darkened(0.2))
			x += BAR_SPACING
	for post_x: float in [rect.position.x, rect.end.x - POST_WIDTH]:
		var post := Rect2(post_x, rect.position.y, POST_WIDTH, SIZE.y)
		draw_rect(post.grow(1.0), outline_color)
		draw_rect(post, frame_color)


func _draw_hidden(rect: Rect2) -> void:
	# Un píxel más ancho para tapar los bordes de los tramos de pared de los costados.
	draw_rect(rect.grow_individual(1.0, 0.0, 1.0, 0.0), wall_color)
	draw_rect(Rect2(rect.position.x - 1.0, rect.position.y, SIZE.x + 2.0, 1.0), outline_color)
	draw_rect(Rect2(rect.position.x - 1.0, rect.end.y - 1.0, SIZE.x + 2.0, 1.0), outline_color)
	var crack: Color = wall_color.darkened(0.25)
	draw_line(Vector2(-6, -4), Vector2(-2, 0), crack, 1.0)
	draw_line(Vector2(-2, 0), Vector2(-4, 4), crack, 1.0)
	draw_line(Vector2(5, -2), Vector2(8, 2), crack, 1.0)
