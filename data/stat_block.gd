class_name StatBlock
extends Resource
## Stats de un personaje. Los valores por defecto son los base; los items los modifican con
## StatModifier y StatCalculator recalcula todo desde cero. Los comportamientos de bala (rebote,
## perforación, teledirigido) también son stats, así cualquier combinación funciona sola.

## Nombres de todos los stats (los que puede tocar un StatModifier).
const STAT_NAMES: Array[StringName] = [
	&"damage", &"fire_rate", &"shot_range", &"shot_speed", &"move_speed", &"luck", &"max_health",
	&"bounces", &"pierce", &"homing", &"shot_size",
]

## Daño por bala.
@export var damage: float = 2.0
## Disparos por segundo.
@export var fire_rate: float = 3.0
## Distancia que recorre una bala antes de desaparecer, en píxeles.
@export var shot_range: float = 150.0
## Velocidad de la bala, en píxeles por segundo.
@export var shot_speed: float = 210.0
## Velocidad de movimiento, en píxeles por segundo.
@export var move_speed: float = 90.0
## Suerte: sesga drops y probabilidades.
@export var luck: float = 0.0
## Vida máxima en medios corazones.
@export var max_health: float = 6.0
## Veces que una bala rebota en las paredes antes de morir.
@export var bounces: float = 0.0
## Enemigos que una bala atraviesa antes de morir.
@export var pierce: float = 0.0
## Qué tanto doblan las balas hacia el enemigo más cercano (0 = nada, 1 = mucho).
@export var homing: float = 0.0
## Multiplicador del tamaño de las balas.
@export var shot_size: float = 1.0
