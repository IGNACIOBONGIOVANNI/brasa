class_name OrbitRing
extends Node2D
## Orbes del modo ORBITAL. Mientras el arma está equipada giran solos alrededor del jugador: borran
## las balas enemigas y lastiman a los enemigos que tocan (con un pequeño cooldown por enemigo).
## El gatillo lanza el orbe que esté más del lado de la mira (WeaponComponent dispara la bala desde
## la boca del arma, como cualquier otra) y ese orbe vuelve a crecer después de REGEN_TIME segundos.

const SPIN_SPEED: float = 5.0
const ORB_RADIUS: float = 4.0
## Segundos antes de volver a lastimar al mismo enemigo.
const HIT_COOLDOWN: float = 0.3
## El roce de un orbe pega esta parte del daño del arma (el lanzado pega entero).
const CONTACT_DAMAGE: float = 0.5
## Segundos que tarda en volver un orbe lanzado.
const REGEN_TIME: float = 1.5
const KNOCKBACK: float = 80.0
const OUTLINE_COLOR: Color = Color("120c16")
## Alfa del orbe mientras vuelve a crecer.
const REGEN_ALPHA: float = 0.35

var color: Color = Color("7ad1ff")
var _orbs: Array[Area2D] = []
## Segundos que le faltan a cada orbe para volver (0 = está).
var _regen_left: Array[float] = []
var _radius: float = 22.0
var _angle: float = 0.0
var _active: bool = false
var _cooldowns: Dictionary[int, float] = {}


## Arma `count` orbes a `radius` del centro (al equipar un arma orbital).
func setup(count: int, radius: float) -> void:
	for orb: Area2D in _orbs:
		orb.queue_free()
	_orbs.clear()
	_regen_left.clear()
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
		_regen_left.append(0.0)
	_place_orbs()


func is_active() -> bool:
	return _active


## Prende o apaga los orbes (al equipar otra arma o al morir se apagan).
func set_active(active: bool) -> void:
	if active == _active:
		return
	_active = active
	for orb: Area2D in _orbs:
		orb.set_deferred(&"monitoring", active)
	queue_redraw()


## Llamar en cada tick mientras el arma está equipada: gira, hace volver los orbes lanzados,
## lastima y borra balas.
func tick(spec: ShotSpec, delta: float) -> void:
	set_active(true)
	_angle = wrapf(_angle + SPIN_SPEED * delta, 0.0, TAU)
	_place_orbs()
	for i: int in _regen_left.size():
		_regen_left[i] = maxf(0.0, _regen_left[i] - delta)
	for id: int in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	for i: int in _orbs.size():
		# El monitoring se prende diferido: el primer tick todavía no hay solapes.
		if _regen_left[i] > 0.0 or not _orbs[i].monitoring:
			continue
		for area: Area2D in _orbs[i].get_overlapping_areas():
			_touch(area, _orbs[i], spec)


func ready_count() -> int:
	return _regen_left.count(0.0)


## Saca el orbe listo que esté más del lado de `direction`. Llamar solo si ready_count() > 0.
func launch(direction: Vector2) -> void:
	var best: int = -1
	var best_dot: float = -INF
	for i: int in _orbs.size():
		if _regen_left[i] > 0.0:
			continue
		var dot: float = _orbs[i].position.normalized().dot(direction)
		if dot > best_dot:
			best_dot = dot
			best = i
	_regen_left[best] = REGEN_TIME
	queue_redraw()


func _touch(area: Area2D, orb: Area2D, spec: ShotSpec) -> void:
	var bullet := area as Bullet
	if bullet != null:
		if bullet.is_hostile_to_player():
			bullet.destroy()
		return
	var hurtbox := area as HurtboxComponent
	if hurtbox == null or _cooldowns.has(hurtbox.get_instance_id()):
		return
	if hurtbox.guards(hurtbox.global_position - orb.global_position):
		return
	_cooldowns[hurtbox.get_instance_id()] = HIT_COOLDOWN
	hurtbox.receive_hit(HitInfo.create(spec.damage * CONTACT_DAMAGE, hurtbox.global_position - orb.global_position, KNOCKBACK))


func _place_orbs() -> void:
	for i: int in _orbs.size():
		_orbs[i].position = Vector2.from_angle(_angle + TAU * i / _orbs.size()) * _radius
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	for i: int in _orbs.size():
		var at: Vector2 = _orbs[i].position
		if _regen_left[i] > 0.0:
			# Vuelve a crecer de a poco.
			var grown: float = 1.0 - _regen_left[i] / REGEN_TIME
			draw_circle(at, maxf(1.0, ORB_RADIUS * grown), Color(color, REGEN_ALPHA))
			continue
		draw_circle(at, ORB_RADIUS + 1.0, OUTLINE_COLOR)
		draw_circle(at, ORB_RADIUS, color)
		draw_circle(at + Vector2(-1, -1), 1.0, Color.WHITE)
