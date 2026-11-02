class_name RoomScenery
extends Node2D
## El escenario de una sala según su piso (FloorTheme.scenery, dibujado por SceneryDrawing): `part`
## FLOOR son los detalles del piso (debajo de todo) y WALLS las paredes con sus cosas, más un hijo sin
## sombra (`glow`) con lo que brilla o se mueve (velas, gotas, hongos, lava, faroles, nieve que
## brilla, banderines), que solo se anima mientras la sala es la actual (`set_animated`). Lo fijo se
## dibuja una sola vez. Con Scenery.PLAIN no dibuja nada (las paredes quedan como siempre).

enum Part { FLOOR, WALLS }

const UNSHADED: Material = preload("res://fx/unshaded.tres")

@export var part: Part = Part.WALLS

var scenery: FloorTheme.Scenery = FloorTheme.Scenery.PLAIN
var _theme: FloorTheme
var _rects: Array[Rect2] = []
var _salt: int = 0
var _time: float = 0.0
var _glow: Node2D


func _ready() -> void:
	set_process(false)


## `rects`: los tramos de pared (RoomBuilder.wall_layout); `salt`: la semilla de la sala.
func setup(theme: FloorTheme, rects: Array[Rect2], salt: int) -> void:
	_theme = theme
	scenery = theme.scenery
	_rects = rects
	_salt = salt
	if part == Part.WALLS and scenery != FloorTheme.Scenery.PLAIN:
		_glow = Node2D.new()
		_glow.name = "Glow"
		_glow.material = UNSHADED
		_glow.draw.connect(_draw_glow)
		add_child(_glow)
	queue_redraw()


## Solo la sala actual anima lo suyo.
func set_animated(animated: bool) -> void:
	set_process(animated and _glow != null)


func _process(delta: float) -> void:
	_time += delta
	_glow.queue_redraw()


func _draw() -> void:
	if _theme == null or scenery == FloorTheme.Scenery.PLAIN:
		return
	if part == Part.FLOOR:
		SceneryDrawing.draw_floor(self, scenery, _theme, _salt)
	else:
		SceneryDrawing.draw_walls(self, _rects, scenery, _theme, _salt)


func _draw_glow() -> void:
	SceneryDrawing.draw_glow(_glow, _rects, scenery, _salt, _time)
