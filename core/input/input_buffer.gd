class_name InputBuffer
extends RefCounted
## Recuerda las acciones apretadas hace poco, para que un input que llega un poco antes de poder
## ejecutarse (rodar justo antes de que termine el cooldown, disparar un tick antes) no se pierda.
##
## El tiempo avanza con advance(delta): durante el hit-stop delta es 0, así que no se vence.

## Segundos que se recuerda cada pulsación (0.1 s = 6 ticks).
var window: float
var _ages: Dictionary[StringName, float] = {}


func _init(window_seconds: float = 0.1) -> void:
	window = window_seconds


func press(action: StringName) -> void:
	_ages[action] = 0.0


func advance(delta: float) -> void:
	for action: StringName in _ages.keys():
		var age: float = _ages[action] + delta
		if age > window:
			_ages.erase(action)
		else:
			_ages[action] = age


func is_buffered(action: StringName) -> bool:
	return _ages.has(action)


## Si la acción está en el buffer la saca y devuelve true. Llamarlo justo al ejecutarla.
func consume(action: StringName) -> bool:
	return _ages.erase(action)


func clear() -> void:
	_ages.clear()
