class_name LaserBeam
extends Node2D
## Rayo continuo del modo LASER. Cada tick traza un rayo desde la boca del arma: atraviesa a todos
## los enemigos y corta en la primera pared o roca. Hace daño cada TICK segundos con el mismo daño
## por segundo que tendría el arma disparando balas, y gasta una unidad de munición cada
## AMMO_INTERVAL segundos. Se dibuja en coordenadas globales (top_level).

const TICK: float = 0.1
const AMMO_INTERVAL: float = 0.25
const KNOCKBACK: float = 40.0
## Enemigos que puede atravesar un rayo (en la práctica, todos).
const MAX_TARGETS: int = 32
const CORE_COLOR: Color = Color("fff6d5")
const SPARK_SCENE: PackedScene = preload("res://fx/bullet_impact.tscn")

var color: Color = Color("ff5ad1")
var _active: bool = false
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _hits: Array[Vector2] = []
var _tick_left: float = 0.0
var _ammo_left: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO


func is_active() -> bool:
	return _active


## Actualiza el rayo; llamar en cada tick de física mientras se mantiene el gatillo.
## Devuelve true en los ticks en que hay que gastar munición.
func update_beam(from: Vector2, direction: Vector2, spec: ShotSpec, fire_interval: float, delta: float) -> bool:
	_active = true
	_from = from
	var targets: Array[HurtboxComponent] = _cast(from, direction, spec.max_range)
	queue_redraw()
	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left = TICK
		var damage: float = spec.damage * TICK / fire_interval
		for hurtbox: HurtboxComponent in targets:
			hurtbox.receive_hit(HitInfo.create(damage, direction, KNOCKBACK))
		for point: Vector2 in _hits:
			var spark := Fx.spawn(get_tree(), SPARK_SCENE, point) as CPUParticles2D
			spark.color = color
	_ammo_left -= delta
	if _ammo_left > 0.0:
		return false
	_ammo_left = AMMO_INTERVAL
	return true


func stop() -> void:
	if _active:
		_active = false
		_tick_left = 0.0
		_ammo_left = 0.0
		queue_redraw()


func _process(delta: float) -> void:
	if _active:
		_time += delta
		queue_redraw()


## Traza el rayo y devuelve los hurtboxes que toca; deja en _to dónde termina y en _hits dónde
## pegó en cada enemigo.
func _cast(from: Vector2, direction: Vector2, length: float) -> Array[HurtboxComponent]:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var to: Vector2 = from + direction * length
	var exclude: Array[RID] = []
	var targets: Array[HurtboxComponent] = []
	_to = to
	_hits.clear()
	while targets.size() < MAX_TARGETS:
		var query := PhysicsRayQueryParameters2D.create(from, to, PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX, exclude)
		query.collide_with_areas = true
		# Si la boca del arma ya está adentro de un enemigo pegado (o de una pared), igual cuenta.
		query.hit_from_inside = true
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			break
		var hurtbox := hit.collider as HurtboxComponent
		if hurtbox == null or hurtbox.guards(direction):
			_to = hit.position
			break
		targets.append(hurtbox)
		_hits.append(hit.position)
		exclude.append(hit.rid)
	return targets


func _draw() -> void:
	if not _active:
		return
	var flicker: float = 0.75 + 0.25 * sin(_time * 40.0)
	draw_line(_from, _to, Color(color, 0.3 * flicker), 6.0)
	draw_line(_from, _to, Color(color, flicker), 3.0)
	draw_line(_from, _to, CORE_COLOR, 1.0)
	draw_circle(_from, 2.5 * flicker, Color(color, flicker))
	draw_circle(_to, 3.0 * flicker, Color(color, flicker))
	for point: Vector2 in _hits:
		draw_circle(point, 2.0 + flicker, CORE_COLOR)
