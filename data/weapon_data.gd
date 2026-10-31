class_name WeaponData
extends Resource
## Definición de un arma. Sus multiplicadores se aplican sobre los stats de quien dispara.

@export var id: StringName = &""
@export var display_name: String = ""

@export_group("Multiplicadores sobre los stats")
@export var damage_mult: float = 1.0
@export var fire_rate_mult: float = 1.0
@export var range_mult: float = 1.0
@export var shot_speed_mult: float = 1.0

@export_group("Impacto")
## Empujón que le da cada bala a un enemigo (px/s, antes de su resistencia).
@export var knockback: float = 70.0

@export_group("Feel")
## Trauma de cámara que agrega cada disparo (0 a 1).
@export var shake_trauma: float = 0.2
@export var sfx_id: StringName = &"shoot"
## Sonido cuando la bala choca una pared. Vacío = sin sonido.
@export var impact_sfx_id: StringName = &"bullet_impact"

@export_group("Visual placeholder")
@export var bullet_radius: float = 3.0
@export var bullet_color: Color = Color(1.0, 0.91, 0.63)
