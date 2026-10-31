class_name BulletEmitter
extends Node2D
## Dispara un BulletPatternData: ráfagas espaciadas en el tiempo, re-apuntando al objetivo en cada una.

signal finished

@export var bullet_scene: PackedScene
## Distancia desde este nodo hasta donde aparecen las balas.
@export var muzzle_distance: float = 6.0
@export_flags_2d_physics var bullet_layer: int = 0
@export_flags_2d_physics var bullet_mask: int = 0

var _pattern: BulletPatternData
var _target: Node2D
var _volley: int = 0
var _next_volley_in: float = 0.0


func is_firing() -> bool:
	return _pattern != null


## Empieza el patrón; la primera ráfaga sale en el acto.
func fire(pattern: BulletPatternData, target: Node2D) -> void:
	_pattern = pattern
	_target = target
	_volley = 0
	_emit_volley()


func stop() -> void:
	_pattern = null


func _physics_process(delta: float) -> void:
	if _pattern == null:
		return
	_next_volley_in -= delta
	if _next_volley_in <= 0.0:
		_emit_volley()


func _emit_volley() -> void:
	var spec := ShotSpec.from_pattern(_pattern)
	for direction: Vector2 in PatternMath.directions(_pattern, _aim(), _volley):
		Bullet.spawn(get_tree(), bullet_scene, spec, global_position + direction * muzzle_distance,
				direction, bullet_layer, bullet_mask)
	AudioManager.play_sfx(_pattern.sfx_id, 0.06)
	_volley += 1
	if _volley >= _pattern.volleys:
		_pattern = null
		finished.emit()
	else:
		_next_volley_in = _pattern.volley_interval


func _aim() -> Vector2:
	if is_instance_valid(_target):
		return _target.global_position - global_position
	return Vector2.RIGHT
