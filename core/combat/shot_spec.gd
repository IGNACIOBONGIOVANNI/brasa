class_name ShotSpec
extends RefCounted
## Parámetros finales de un proyectil: stats del tirador × multiplicadores del arma
## (o los valores de un patrón, para las balas enemigas).

const MIN_DAMAGE: float = 0.1
const MIN_FIRE_RATE: float = 0.5
const MAX_FIRE_RATE: float = 30.0
const MIN_RANGE: float = 16.0
const MIN_SPEED: float = 40.0

var damage: float
var speed: float
var max_range: float
var knockback: float
var radius: float
var color: Color
## Rebotes en paredes antes de morir.
var bounces: int = 0
## Enemigos que atraviesa antes de morir.
var pierce: int = 0
## Qué tanto dobla hacia el enemigo más cercano (0 a 1).
var homing: float = 0.0
## Sonido al chocar una pared; vacío = sin sonido.
var impact_sfx_id: StringName = &""
## Explota al chocar o al llegar a su alcance (cohetes, granadas): radio. 0 = bala común.
var blast_radius: float = 0.0
## Chance (0 a 1) de cada estado al pegar.
var burn_chance: float = 0.0
var poison_chance: float = 0.0
var corrupt_chance: float = 0.0
var douse_chance: float = 0.0
## Balas que esperan (las de algunos jefes): se frenan a los `stall_after` s de salir, quedan quietas
## `stall_time` s y después salen hacia el jugador. 0 = no se frenan.
var stall_after: float = 0.0
var stall_time: float = 0.0


static func build(stats: StatBlock, weapon: WeaponData) -> ShotSpec:
	var spec := ShotSpec.new()
	spec.damage = maxf(MIN_DAMAGE, stats.damage * weapon.damage_mult)
	spec.speed = maxf(MIN_SPEED, stats.shot_speed * weapon.shot_speed_mult)
	spec.max_range = maxf(MIN_RANGE, stats.shot_range * weapon.range_mult)
	spec.knockback = weapon.knockback
	spec.radius = weapon.bullet_radius * stats.shot_size
	spec.color = weapon.bullet_color
	spec.bounces = roundi(stats.bounces)
	spec.pierce = roundi(stats.pierce) + weapon.pierce_bonus
	spec.homing = stats.homing
	spec.impact_sfx_id = weapon.impact_sfx_id
	spec.blast_radius = weapon.blast_radius
	spec.burn_chance = clampf(stats.burn_chance + weapon.burn_chance, 0.0, 1.0)
	spec.poison_chance = clampf(stats.poison_chance + weapon.poison_chance, 0.0, 1.0)
	spec.corrupt_chance = clampf(stats.corrupt_chance + weapon.corrupt_chance, 0.0, 1.0)
	spec.douse_chance = clampf(stats.douse_chance + weapon.douse_chance, 0.0, 1.0)
	return spec


func has_status() -> bool:
	return burn_chance > 0.0 or poison_chance > 0.0 or corrupt_chance > 0.0 or douse_chance > 0.0


## Balas enemigas: no dependen de stats, salen tal cual del patrón.
static func from_pattern(pattern: BulletPatternData) -> ShotSpec:
	var spec := ShotSpec.new()
	spec.damage = maxf(MIN_DAMAGE, pattern.damage)
	spec.speed = maxf(MIN_SPEED, pattern.bullet_speed)
	spec.max_range = maxf(MIN_RANGE, pattern.bullet_range)
	spec.knockback = pattern.knockback
	spec.radius = pattern.bullet_radius
	spec.color = pattern.bullet_color
	spec.bounces = pattern.bounces
	spec.homing = pattern.homing
	spec.stall_after = pattern.stall_after
	spec.stall_time = pattern.stall_time
	return spec


## Segundos entre disparos.
static func fire_interval(stats: StatBlock, weapon: WeaponData) -> float:
	var rate: float = clampf(stats.fire_rate * weapon.fire_rate_mult, MIN_FIRE_RATE, MAX_FIRE_RATE)
	return 1.0 / rate
