@tool
class_name SceneryShape
extends PlaceholderShape
## Una roca o un foso con el aspecto del piso (FloorTheme.scenery, dibujado por SceneryDrawing): cajón,
## tonel, tocón, bloque de hierro, fardo, bloque de piedra, hielo o peñasco; agua, raíces, lava,
## tablas rotas, grava, grieta de hielo o abismo. Con Scenery.PLAIN es el cuadrado de siempre. El
## `color` sigue siendo el de la roca (las astillas al romperla lo usan).

enum Part { OBSTACLE, PIT }

@export var part: Part = Part.OBSTACLE:
	set(value):
		part = value
		queue_redraw()
@export var scenery: FloorTheme.Scenery = FloorTheme.Scenery.PLAIN:
	set(value):
		scenery = value
		queue_redraw()
## Cambia detalles chicos (dónde cae una mancha, una grieta) para que no sean todas iguales.
@export var variant: int = 0:
	set(value):
		variant = value
		queue_redraw()


func _draw() -> void:
	if scenery == FloorTheme.Scenery.PLAIN:
		super._draw()
	elif part == Part.OBSTACLE:
		SceneryDrawing.draw_obstacle(self, scenery, color, outline_color, variant)
	else:
		SceneryDrawing.draw_pit(self, scenery, color, variant)
