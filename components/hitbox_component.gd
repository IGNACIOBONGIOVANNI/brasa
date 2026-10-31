class_name HitboxComponent
extends Area2D
## Daño por contacto a los HurtboxComponent que toca. Revisa los solapes en cada tick: si el
## objetivo sigue encima cuando se le terminan los i-frames, lo vuelve a golpear.

const DEBUG_COLOR: Color = Color(1.0, 0.3, 0.3, 0.45)

## Daño por golpe (medios corazones si el objetivo es el jugador).
@export var damage: float = 1.0
@export var knockback: float = 140.0

var active: bool = true


func _ready() -> void:
	monitorable = false
	for child: Node in get_children():
		var shape := child as CollisionShape2D
		if shape != null:
			shape.debug_color = DEBUG_COLOR


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for area: Area2D in get_overlapping_areas():
		var hurtbox := area as HurtboxComponent
		if hurtbox != null:
			hurtbox.receive_hit(HitInfo.create(damage, hurtbox.global_position - global_position, knockback))
