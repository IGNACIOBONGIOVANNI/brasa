extends Node
## Raíz del juego. Hito 1: arranca una run y carga directamente la escena de juego.
## Desde el hito 5 maneja el flujo menú → run → resumen.

const GAME_SCENE: PackedScene = preload("res://main/game.tscn")


func _ready() -> void:
	RunState.start_run()
	add_child(GAME_SCENE.instantiate())
