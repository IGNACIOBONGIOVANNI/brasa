class_name WindowScales
extends RefCounted
## Tamaños de ventana que se pueden elegir: múltiplos enteros de la resolución del juego (320x180), así
## todos los píxeles quedan del mismo tamaño. Solo los que entran en la pantalla.

const BASE: Vector2i = Vector2i(320, 180)
## 1280x720, el tamaño con el que arranca el juego.
const DEFAULT_SCALE: int = 4
const MIN_SCALE: int = 2
const MAX_SCALE: int = 12


static func size_of(scale: int) -> Vector2i:
	return BASE * scale


## Escalas que entran en `screen` (el lugar libre del monitor). Siempre hay al menos MIN_SCALE.
static func available(screen: Vector2i) -> Array[int]:
	var result: Array[int] = []
	for scale: int in range(MIN_SCALE, MAX_SCALE + 1):
		var window: Vector2i = size_of(scale)
		if window.x <= screen.x and window.y <= screen.y:
			result.append(scale)
	if result.is_empty():
		result.append(MIN_SCALE)
	return result


## La siguiente más grande de `options`; después de la última vuelve a la primera.
static func next(current: int, options: Array[int]) -> int:
	for scale: int in options:
		if scale > current:
			return scale
	return options[0]


## Cuántas veces entra el juego (320x180) en una ventana de ese tamaño, en enteros (como lo agranda
## Godot con la escala entera).
static func scale_for(window: Vector2i) -> int:
	return maxi(1, mini(floori(window.x / float(BASE.x)), floori(window.y / float(BASE.y))))


## A qué resolución se dibujan las letras (en veces 320x180) para que cada píxel de letra ocupe una
## cantidad entera de píxeles de pantalla: medio píxel del mundo cuando la escala es par (4 → letras a
## 2x) y lo más parecido cuando es impar (3 → a 3x, 5 → a 2,5x). Así nunca quedan píxeles desparejos.
static func text_oversampling(scale: int) -> float:
	var text_pixel: int = maxi(1, floori(scale / 2.0))
	return float(scale) / text_pixel


## La más grande de `options` que no pasa de `wanted` (si el monitor es más chico que la guardada).
static func fit(wanted: int, options: Array[int]) -> int:
	var best: int = options[0]
	for scale: int in options:
		if scale <= wanted:
			best = scale
	return best
