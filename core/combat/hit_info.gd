class_name HitInfo
extends RefCounted
## Datos de un golpe: cuánto daño hace y hacia dónde empuja.

var damage: float
## Dirección del empujón, normalizada.
var direction: Vector2
var knockback: float


static func create(hit_damage: float, push_direction: Vector2, push_force: float) -> HitInfo:
	var info := HitInfo.new()
	info.damage = hit_damage
	info.direction = push_direction.normalized()
	info.knockback = push_force
	return info
