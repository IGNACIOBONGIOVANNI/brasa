class_name KnockbackComponent
extends Node
## Empujón que recibe una entidad al ser golpeada. El dueño suma `velocity` a su movimiento y el
## empujón se frena solo.

## 0 = recibe todo el empujón, 1 = no se mueve.
@export_range(0.0, 1.0) var resistance: float = 0.0
## Frenado en px/s².
@export var decay: float = 900.0

var velocity: Vector2 = Vector2.ZERO


func apply(direction: Vector2, force: float) -> void:
	velocity = direction.normalized() * force * (1.0 - clampf(resistance, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, decay * delta)
