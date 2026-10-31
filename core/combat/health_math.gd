class_name HealthMath
extends RefCounted
## Cuentas de vida sin nodos (las usan HealthComponent y el HUD).
##
## La vida es un float: los enemigos reciben el daño del jugador (2.0 × multiplicadores) y el
## jugador cuenta en medios corazones (6.0 = 3 corazones), siempre con valores enteros.

enum Heart { EMPTY, HALF, FULL }


## Vida después de recibir `amount` de daño. El daño negativo se ignora y la vida no baja de 0.
static func damaged(current: float, amount: float) -> float:
	return maxf(0.0, current - maxf(0.0, amount))


## Vida después de curar `amount`, sin pasar del máximo. La curación negativa se ignora.
static func healed(current: float, amount: float, max_value: float) -> float:
	return minf(max_value, current + maxf(0.0, amount))


static func is_dead(current: float) -> bool:
	return current <= 0.0


## Cómo dibujar cada contenedor del HUD: cada uno vale 2 medios corazones.
static func heart_states(half_hearts: int, max_half_hearts: int) -> Array[Heart]:
	var states: Array[Heart] = []
	var containers: int = ceili(max_half_hearts / 2.0)
	var filled: int = clampi(half_hearts, 0, containers * 2)
	for i: int in containers:
		var in_container: int = clampi(filled - i * 2, 0, 2)
		if in_container == 2:
			states.append(Heart.FULL)
		elif in_container == 1:
			states.append(Heart.HALF)
		else:
			states.append(Heart.EMPTY)
	return states
