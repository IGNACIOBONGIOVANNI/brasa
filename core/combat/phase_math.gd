class_name PhaseMath
extends RefCounted
## Fases de un jefe: cada una empieza cuando la vida baja de su umbral (fracción de la vida máxima).


## Índice de la fase que corresponde a `health_fraction` (vida actual / máxima). `thresholds` va de
## mayor a menor y el primero suele ser 1.0. Si la vida está por encima de todos, la fase 0.
static func phase_for(health_fraction: float, thresholds: Array[float]) -> int:
	var phase: int = 0
	for i: int in thresholds.size():
		if health_fraction <= thresholds[i]:
			phase = i
	return phase
