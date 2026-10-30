@tool
class_name PlaceholderShape
extends Node2D
## Forma simple dibujada por código para arte placeholder.
## Cuando haya arte real se reemplaza este nodo por un Sprite2D sin tocar la lógica.

enum Shape { CIRCLE, RECT }

@export var shape: Shape = Shape.CIRCLE:
	set(value):
		shape = value
		queue_redraw()
## Diámetro en CIRCLE (usa x), tamaño en RECT. Centrado en el origen.
@export var size: Vector2 = Vector2(8, 8):
	set(value):
		size = value
		queue_redraw()
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()
## Borde de 1 px. Transparente = sin borde.
@export var outline_color: Color = Color(0, 0, 0, 0):
	set(value):
		outline_color = value
		queue_redraw()
## Solo RECT: damero con celdas de checker_cell píxeles (para pisos). Transparente = sin damero.
@export var checker_color: Color = Color(0, 0, 0, 0):
	set(value):
		checker_color = value
		queue_redraw()
@export var checker_cell: int = 16:
	set(value):
		checker_cell = value
		queue_redraw()


func _draw() -> void:
	match shape:
		Shape.CIRCLE:
			_draw_circle_shape()
		Shape.RECT:
			_draw_rect_shape()


func _draw_circle_shape() -> void:
	var radius: float = size.x * 0.5
	if outline_color.a > 0.0:
		draw_circle(Vector2.ZERO, radius, outline_color)
		radius -= 1.0
	draw_circle(Vector2.ZERO, radius, color)


func _draw_rect_shape() -> void:
	var rect := Rect2(-size * 0.5, size)
	if outline_color.a > 0.0:
		draw_rect(rect, outline_color)
		rect = rect.grow(-1.0)
	draw_rect(rect, color)
	if checker_color.a <= 0.0 or checker_cell <= 0:
		return
	var columns: int = ceili(rect.size.x / checker_cell)
	var rows: int = ceili(rect.size.y / checker_cell)
	for y: int in rows:
		for x: int in columns:
			if (x + y) % 2 == 1:
				var cell := Rect2(rect.position + Vector2(x, y) * checker_cell, Vector2.ONE * checker_cell)
				draw_rect(cell.intersection(rect), checker_color)
