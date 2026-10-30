class_name StatBlock
extends Resource
## Stats de un personaje. Los items los modificarán (hito 4); los valores por defecto son los base.

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
## Suerte: sesga drops y probabilidades (se usa a partir del hito 3).
@export var luck: float = 0.0
