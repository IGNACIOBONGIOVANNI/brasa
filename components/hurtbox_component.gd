class_name HurtboxComponent
extends Area2D
## Zona donde una entidad recibe golpes (más chica que su dibujo). La detectan las balas y los
## HitboxComponent; si el golpe entra, descuenta vida y avisa con `hurt`.
## Escudo: si `guard_direction` no es cero, lo que llega de ese lado (dentro del ángulo de `guard_cos`)
## lo frena el escudo; las balas, el láser y los orbes lo consultan con `guards()` antes de pegar.

signal hurt(info: HitInfo)

const DEBUG_COLOR: Color = Color(0.3, 1.0, 0.5, 0.45)

@export var health: HealthComponent

## Hacia dónde mira el escudo (cero = sin escudo) y el coseno de su medio ángulo.
var guard_direction: Vector2 = Vector2.ZERO
var guard_cos: float = 1.0


func _ready() -> void:
	monitoring = false
	for child: Node in get_children():
		var shape := child as CollisionShape2D
		if shape != null:
			shape.debug_color = DEBUG_COLOR


## true si un golpe que viaja en `hit_direction` le pega al escudo.
func guards(hit_direction: Vector2) -> bool:
	if guard_direction == Vector2.ZERO or hit_direction == Vector2.ZERO:
		return false
	return -hit_direction.normalized().dot(guard_direction) >= guard_cos


## Devuelve true si el golpe hizo daño (false si estaba invulnerable o muerto).
func receive_hit(info: HitInfo) -> bool:
	if health == null or not health.take_damage(info.damage):
		return false
	hurt.emit(info)
	return true
