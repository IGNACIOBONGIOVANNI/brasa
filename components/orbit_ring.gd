class_name OrbitRing
extends Node2D
## Orbes del modo ORBITAL: giran alrededor del jugador mientras se mantiene el gatillo. Lastiman a
## los enemigos que tocan (con un pequeño cooldown por enemigo) y borran las balas enemigas.

const SPIN_SPEED: float = 5.0
const ORB_RADIUS: float = 4.0
## Segundos antes de volver a lastimar al mismo enemigo.
const HIT_COOLDOWN: float = 0.3
## Segundos de uso por cada unidad de munición.
const AMMO_INTERVAL: float = 0.25
const KNOCKBACK: float = 80.0
const OUTLINE_COLOR: Color = Color("120c16")

var color: Color = Color("7ad1ff")
var _orbs: Array[Area2D] = []
var _radius: float = 22.0
var _angle: float = 0.0
var _active: bool = false
var _ammo_left: float = 0.0
var _cooldowns: Dictionary[int, float] = {}


## Arma `count` orbes a `radius` del centro (al equipar un arma orbital).
func setup(count: int, radius: float) -> void:
	for orb: Area2D in _orbs:
		orb.queue_free()
	_orbs.clear()
	_radius = radius
	for _i: int in maxi(1, count):
		var orb := Area2D.new()
		orb.collision_layer = PhysicsLayers.PLAYER_BULLET
		orb.collision_mask = PhysicsLayers.ENEMY_HURTBOX | PhysicsLayers.ENEMY_BULLET
		orb.monitoring = false
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = ORB_RADIUS
		shape.shape = circle
		orb.add_child(shape)
		add_child(orb)
		_orbs.append(orb)
	_place_orbs()


func is_active() -> bool:
	return _active


## Llamar en cada tick mientras se mantiene el gatillo. Devuelve true cuando hay que gastar munición.
func tick(spec: ShotSpec, delta: float) -> bool:
	_set_active(true)
	_angle = wrapf(_angle + SPIN_SPEED * delta, 0.0, TAU)
	_place_orbs()
	for id: int in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	for orb: Area2D in _orbs:
		# El monitoring se prende diferido: el primer tick todavía no hay solapes.
		if not orb.monitoring:
			continue
		for area: Area2D in orb.get_overlapping_areas():
			_touch(area, orb, spec)
	_ammo_left -= delta
	if _ammo_left > 0.0:
		return false
	_ammo_left = AMMO_INTERVAL
	return true


func stop() -> void:
	_set_active(false)


func _touch(area: Area2D, orb: Area2D, spec: ShotSpec) -> void:
	var bullet := area as Bullet
	if bullet != null:
		if bullet.is_hostile_to_player():
			bullet.destroy()
		return
	var hurtbox := area as HurtboxComponent
	if hurtbox == null or _cooldowns.has(hurtbox.get_instance_id()):
		return
	_cooldowns[hurtbox.get_instance_id()] = HIT_COOLDOWN
	hurtbox.receive_hit(HitInfo.create(spec.damage, hurtbox.global_position - orb.global_position, KNOCKBACK))


func _set_active(active: bool) -> void:
	if active == _active:
		return
	_active = active
	_ammo_left = 0.0 if active else _ammo_left
	for orb: Area2D in _orbs:
		orb.set_deferred(&"monitoring", active)
	queue_redraw()


func _place_orbs() -> void:
	for i: int in _orbs.size():
		_orbs[i].position = Vector2.from_angle(_angle + TAU * i / _orbs.size()) * _radius
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	for orb: Area2D in _orbs:
		draw_circle(orb.position, ORB_RADIUS + 1.0, OUTLINE_COLOR)
		draw_circle(orb.position, ORB_RADIUS, color)
		draw_circle(orb.position + Vector2(-1, -1), 1.0, Color.WHITE)
