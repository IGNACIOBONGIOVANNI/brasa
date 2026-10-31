class_name HitStop
extends Node
## Congela el juego unos instantes en los golpes fuertes (Engine.time_scale = 0).
##
## Cuenta ticks de física reales: con time_scale en 0 los ticks siguen ocurriendo (con delta 0),
## así que dura lo mismo en cualquier monitor y en Movie Maker. Si llegan dos pedidos se queda el
## más largo. Al salir del árbol siempre devuelve el tiempo a la normalidad.

var _ticks_left: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.hitstop_requested.connect(request)


func request(duration: float) -> void:
	_ticks_left = maxi(_ticks_left, ceili(duration * Engine.physics_ticks_per_second))
	if _ticks_left > 0:
		Engine.time_scale = 0.0


func _physics_process(_delta: float) -> void:
	if _ticks_left <= 0:
		return
	_ticks_left -= 1
	if _ticks_left == 0:
		Engine.time_scale = 1.0


func _exit_tree() -> void:
	_ticks_left = 0
	Engine.time_scale = 1.0
