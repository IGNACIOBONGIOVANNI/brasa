class_name LaserBeam
extends Node2D
## Rayo continuo del modo LASER. Cada tick traza un rayo desde la boca del arma: corta en la primera
## pared y en el primer enemigo (o atraviesa tantos como `pierce` + 1). Hace daño cada TICK segundos
## con el mismo daño por segundo que tendría el arma disparando balas. Se dibuja en coordenadas
## globales (top_level).

const TICK: float = 0.1
const KNOCKBACK: float = 25.0
const CORE_COLOR: Color = Color("fff6d5")

var color: Color = Color("ff5ad1")
var _active: bool = false
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _tick_left: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO


func is_active() -> bool:
	return _active


## Actualiza el rayo; llamar en cada tick de física mientras se mantiene el gatillo.
## Devuelve true en los ticks en que hizo daño (y hay que gastar munición).
func update_beam(from: Vector2, direction: Vector2, spec: ShotSpec, fire_interval: float, delta: float) -> bool:
	_active = true
	_from = from
	var targets: Array[HurtboxComponent] = _cast(from, direction, spec.max_range, 1 + spec.pierce)
	queue_redraw()
	_tick_left -= delta
	if _tick_left > 0.0:
		return false
	_tick_left = TICK
	var damage: float = spec.damage * TICK / fire_interval
	for hurtbox: HurtboxComponent in targets:
		hurtbox.receive_hit(HitInfo.create(damage, direction, KNOCKBACK))
	return true


func stop() -> void:
	if _active:
		_active = false
		_tick_left = 0.0
		queue_redraw()


func _process(delta: float) -> void:
	if _active:
		_time += delta
		queue_redraw()


## Traza el rayo y devuelve los hurtboxes que toca; deja en _to dónde termina.
func _cast(from: Vector2, direction: Vector2, length: float, max_targets: int) -> Array[HurtboxComponent]:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var to: Vector2 = from + direction * length
	var exclude: Array[RID] = []
	var targets: Array[HurtboxComponent] = []
	_to = to
	while true:
		var query := PhysicsRayQueryParameters2D.create(from, to, PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX, exclude)
		query.collide_with_areas = true
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			break
		var hurtbox := hit.collider as HurtboxComponent
		if hurtbox == null:
			_to = hit.position
			break
		targets.append(hurtbox)
		exclude.append(hit.rid)
		if targets.size() >= max_targets:
			_to = hit.position
			break
	return targets


func _draw() -> void:
	if not _active:
		return
	var flicker: float = 0.75 + 0.25 * sin(_time * 40.0)
	draw_line(_from, _to, Color(color, 0.45 * flicker), 4.0)
	draw_line(_from, _to, Color(color, flicker), 2.0)
	draw_line(_from, _to, CORE_COLOR, 1.0)
	draw_circle(_to, 2.5 * flicker, Color(color, flicker))
