class_name FlickerLight
extends PointLight2D
## La luz que lleva el jugador (es una chispa): titila un poco y se aviva un instante con cada disparo
## (pulse). Solo visual: el titileo sale de senos, no del azar.

const FLICKER: float = 0.08
const PULSE_DECAY: float = 4.0

var _base_energy: float = 1.0
var _boost: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_base_energy = energy


## Se aviva `amount` de energía y vuelve sola.
func pulse(amount: float) -> void:
	_boost = maxf(_boost, amount)


func _process(delta: float) -> void:
	_time += delta
	_boost = maxf(0.0, _boost - PULSE_DECAY * delta)
	var flicker: float = FLICKER * (sin(_time * 11.0) * 0.6 + sin(_time * 23.0 + 1.3) * 0.4)
	energy = _base_energy + flicker + _boost
