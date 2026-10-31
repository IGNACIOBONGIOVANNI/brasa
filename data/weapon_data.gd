class_name WeaponData
extends Resource
## Definición de un arma. Sus multiplicadores se aplican sobre los stats de quien dispara, así los
## items afectan a cualquier arma. Modos: SINGLE (una bala), SPREAD (abanico), BURST (ráfaga),
## LASER (rayo continuo) y ORBITAL (orbes que giran alrededor mientras se mantiene el gatillo).

enum FireMode { SINGLE, SPREAD, BURST, LASER, ORBITAL }

@export var id: StringName = &""
@export var display_name: String = ""
@export var fire_mode: FireMode = FireMode.SINGLE

@export_group("Multiplicadores sobre los stats")
@export var damage_mult: float = 1.0
@export var fire_rate_mult: float = 1.0
@export var range_mult: float = 1.0
@export var shot_speed_mult: float = 1.0

@export_group("Modo")
## SPREAD: balas por disparo. ORBITAL: cantidad de orbes.
@export var projectiles: int = 1
## SPREAD: ancho total del abanico.
@export var spread_degrees: float = 0.0
## BURST: balas por ráfaga y segundos entre una y otra.
@export var burst_count: int = 3
@export var burst_interval: float = 0.07
## ORBITAL: distancia de los orbes al jugador.
@export var orbit_radius: float = 22.0

@export_group("Munición")
## Munición de reserva (sin contar el cargador). -1 = infinita.
@export var ammo: int = -1
## Tamaño del cargador. -1 = sin cargador (no recarga).
@export var magazine: int = -1
## Segundos que tarda en recargar.
@export var reload_time: float = 1.0

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
@export var gun_color: Color = Color("8a8a9e")
## Largo del caño dibujado.
@export var gun_length: float = 6.0
## Ícono de píxeles para el HUD ("#" = píxel), 9 x 5.
@export var icon: PackedStringArray = []
@export var icon_color: Color = Color("c9c3d6")
