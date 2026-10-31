class_name HurtboxComponent
extends Area2D
## Zona donde una entidad recibe golpes (más chica que su dibujo). La detectan las balas y los
## HitboxComponent; si el golpe entra, descuenta vida y avisa con `hurt`.

signal hurt(info: HitInfo)

const DEBUG_COLOR: Color = Color(0.3, 1.0, 0.5, 0.45)

@export var health: HealthComponent


func _ready() -> void:
	monitoring = false
	for child: Node in get_children():
		var shape := child as CollisionShape2D
		if shape != null:
			shape.debug_color = DEBUG_COLOR


## Devuelve true si el golpe hizo daño (false si estaba invulnerable o muerto).
func receive_hit(info: HitInfo) -> bool:
	if health == null or not health.take_damage(info.damage):
		return false
	hurt.emit(info)
	return true
