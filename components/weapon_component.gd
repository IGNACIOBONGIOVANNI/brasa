class_name WeaponComponent
extends Node2D
## Dispara un WeaponData con los stats que le pasa su dueño.
## Las balas se agregan al nodo del grupo "projectiles" para que no se muevan con el tirador.

signal fired(direction: Vector2)

const PROJECTILES_GROUP: StringName = &"projectiles"
## Margen para que un intervalo exacto (p. ej. 20 ticks) no se pierda por error de punto flotante.
const COOLDOWN_EPSILON: float = 0.001

@export var weapon: WeaponData
@export var bullet_scene: PackedScene
## Distancia desde este nodo hasta la boca del arma.
@export var muzzle_distance: float = 10.0
@export_flags_2d_physics var bullet_layer: int = 0
@export_flags_2d_physics var bullet_mask: int = 0

var _cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


func can_fire() -> bool:
	return weapon != null and _cooldown <= COOLDOWN_EPSILON


## Dispara hacia `direction` si el cooldown lo permite. Devuelve true si salió una bala.
func try_fire(stats: StatBlock, direction: Vector2) -> bool:
	if not can_fire():
		return false
	_cooldown = ShotSpec.fire_interval(stats, weapon)
	var bullet := bullet_scene.instantiate() as Bullet
	bullet.setup(ShotSpec.build(stats, weapon), direction, bullet_layer, bullet_mask)
	_projectile_container().add_child(bullet)
	bullet.global_position = global_position + direction * muzzle_distance
	EventBus.shake_requested.emit(weapon.shake_trauma)
	AudioManager.play_sfx(weapon.sfx_id, 0.08)
	fired.emit(direction)
	return true


func _projectile_container() -> Node:
	var container: Node = get_tree().get_first_node_in_group(PROJECTILES_GROUP)
	return container if container != null else get_tree().current_scene
