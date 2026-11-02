class_name DiveMove
extends LeapMove
## DIVE: salta como LEAP (una vez: la sombra persigue al jugador y se traba), cae clavándose en el
## piso (pega en `radius` y suelta `pattern`) y desde ahí salen `count` rayos al ras del piso, en
## estrella y uno apuntando al jugador: se ven `interval` s y queman `linger` s. Hay que salirse de la
## línea (o rodar a través del rayo).

enum RayStep { NONE, PREVIEW, FIRE }

var _ray_step: RayStep = RayStep.NONE
var _ray_time: float = 0.0
var _rays: Array[EnemyBeam] = []
var _first_angle: float = 0.0


func _begin() -> void:
	super._begin()
	_left = 1


func _tick(delta: float) -> bool:
	if _ray_step == RayStep.NONE:
		if super._tick(delta):
			_start_rays()
		return false
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	_ray_time += delta
	var origin: Vector2 = enemy.global_position + Vector2(0, 2)
	for i: int in _rays.size():
		var direction: Vector2 = ray_direction(i)
		var from: Vector2 = origin + direction * enemy.data.body_radius
		if _ray_step == RayStep.PREVIEW:
			_rays[i].preview(from, direction)
		else:
			_rays[i].fire(from, direction, attack.damage)
	if _ray_step == RayStep.PREVIEW and _ray_time >= attack.interval:
		_ray_step = RayStep.FIRE
		_ray_time = 0.0
		AudioManager.play_sfx(&"beam", 0.05)
		EventBus.shake_requested.emit(LAND_TRAUMA * 0.5)
	elif _ray_step == RayStep.FIRE and _ray_time >= attack.linger:
		return true
	return false


func _end() -> void:
	super._end()
	for ray: EnemyBeam in _rays:
		if is_instance_valid(ray):
			ray.queue_free()
	_rays.clear()


## Hacia dónde sale el rayo `index` (el primero, al jugador).
func ray_direction(index: int) -> Vector2:
	return Vector2.from_angle(_first_angle + TAU * index / maxi(1, attack.count))


func is_firing() -> bool:
	return _ray_step == RayStep.FIRE


func _start_rays() -> void:
	_ray_step = RayStep.PREVIEW
	_ray_time = 0.0
	_first_angle = (target_position() - enemy.global_position).angle()
	for i: int in attack.count:
		var ray := EnemyBeam.new()
		ray.material = enemy.beam.material
		ray.color = enemy.beam.color
		enemy.add_child(ray)
		_rays.append(ray)
	AudioManager.play_sfx(&"root", 0.05)
