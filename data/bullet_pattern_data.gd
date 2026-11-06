class_name BulletPatternData
extends Resource
## Patrón de balas enemigas: forma, cantidad, ráfagas y cómo es cada bala.
## Las direcciones las calcula PatternMath:
## - RING: `count` balas repartidas en 360°; las ráfagas impares se corren media separación.
## - SPIRAL: como RING, pero cada ráfaga gira `rotation_step_degrees`.
## - FAN: `count` balas en un abanico de `spread_degrees` centrado en el objetivo.
## - AIMED: una bala por ráfaga directo al objetivo (re-apunta en cada ráfaga).

enum Kind { RING, SPIRAL, FAN, AIMED }

@export var id: StringName = &""
@export var kind: Kind = Kind.AIMED
## Balas por ráfaga (RING, SPIRAL y FAN).
@export_range(1, 64) var count: int = 1
## Ancho total del abanico (FAN).
@export_range(0.0, 360.0) var spread_degrees: float = 60.0
## Giro de cada ráfaga respecto de la anterior (SPIRAL).
@export var rotation_step_degrees: float = 15.0
## Giro fijo respecto de la referencia (el objetivo, o la derecha en RING y SPIRAL).
@export var angle_offset_degrees: float = 0.0
@export_range(1, 64) var volleys: int = 1
## Segundos entre ráfagas.
@export var volley_interval: float = 0.2
@export var sfx_id: StringName = &"enemy_shoot"

@export_group("Bala")
## Daño en medios corazones.
@export var damage: float = 1.0
@export var bullet_speed: float = 90.0
@export var bullet_range: float = 260.0
@export var knockback: float = 110.0
@export var bullet_radius: float = 3.0
@export var bullet_color: Color = Color("ff6b8a")
## Rebotes en las paredes antes de morir.
@export_range(0, 8) var bounces: int = 0
## Qué tanto dobla hacia el jugador (0 a 1): las balas que persiguen.
@export_range(0.0, 1.0) var homing: float = 0.0
## Balas que esperan: a los `stall_after` s de salir se frenan en el aire `stall_time` s y después
## salen derecho hacia donde está el jugador (0 = no se frenan).
@export var stall_after: float = 0.0
@export var stall_time: float = 0.0
