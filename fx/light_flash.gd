class_name LightFlash
extends PointLight2D
## Destello de luz que se apaga solo (explosiones, Pulso, muertes). Configurar color, energía,
## tamaño y duración antes de que entre al árbol (Fx.spawn devuelve el nodo antes de agregarlo).

var duration: float = 0.3
var _left: float = 0.0
var _start_energy: float = 1.0


func _ready() -> void:
	_left = duration
	_start_energy = energy


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	energy = _start_energy * _left / duration
