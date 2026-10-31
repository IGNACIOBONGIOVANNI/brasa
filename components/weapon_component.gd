class_name WeaponComponent
extends Node2D
## Dispara el arma actual (un WeaponSlot, con su munición) con los stats que le pasa su dueño.
## El dueño llama trigger() en cada tick mientras se mantiene el gatillo e idle() en los demás;
## release() corta el disparo (al rodar) y holster() además guarda los orbes (al morir).
## SINGLE, SPREAD y BURST disparan balas respetando la cadencia; LASER es continuo (LaserBeam); en
## ORBITAL los orbes giran solos mientras el arma está equipada y el gatillo los lanza (OrbitRing);
## GRENADE tira granadas hasta donde se apunta (Grenade) y RAIL se carga manteniendo el gatillo y
## dispara al soltarlo, si llegó a cargarse (RailGun; rodar lo cancela). Las armas con `sight` muestran
## una mira láser (AimSight). El dueño avisa hacia dónde y a qué distancia apunta con set_aim().

signal fired(direction: Vector2)

## Margen para que un intervalo exacto (p. ej. 20 ticks) no se pierda por error de punto flotante.
const COOLDOWN_EPSILON: float = 0.001
## Segundos entre los "clic" de arma vacía.
const EMPTY_CLICK_INTERVAL: float = 0.35
const GRENADE_SCENE: PackedScene = preload("res://entities/bullets/grenade.tscn")
## Las granadas caen a esta distancia de la pared o roca que crucen.
const GRENADE_WALL_MARGIN: float = 6.0
## Con el stick, la granada busca un enemigo hasta estos grados a cada lado de la mira.
const GRENADE_ASSIST_DEGREES: float = 25.0

@export var bullet_scene: PackedScene
## Distancia desde este nodo hasta la boca del arma.
@export var muzzle_distance: float = 10.0
@export_flags_2d_physics var bullet_layer: int = 0
@export_flags_2d_physics var bullet_mask: int = 0

## Arma equipada. Al cambiarla se cortan el láser, los orbes y la ráfaga en curso.
var slot: WeaponSlot:
	set(value):
		if slot != null:
			slot.cancel_reload()
		slot = value
		_on_slot_changed()

var _cooldown: float = 0.0
var _burst_left: int = 0
var _burst_timer: float = 0.0
var _burst_spec: ShotSpec
var _aim: Vector2 = Vector2.RIGHT
## Últimos stats que pasó el dueño (los orbes los usan aunque no se apriete el gatillo).
var _stats: StatBlock
var _holstered: bool = false
## Distancia a la que apunta el dueño (el mouse); INF con el stick.
var _aim_distance: float = INF
## Segundos que se viene cargando el riel (negativo = no se está cargando).
var _rail_charge: float = -1.0

@onready var _laser: LaserBeam = $LaserBeam
@onready var _orbit: OrbitRing = $OrbitRing
@onready var _rail: RailGun = $RailGun
@onready var _sight: AimSight = $AimSight


func _ready() -> void:
	_on_slot_changed()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if slot != null and slot.update(delta):
		AudioManager.play_sfx(&"reload", 0.1)
	_update_burst(delta)
	if not _holstered and _stats != null and _is_orbital():
		_orbit.tick(ShotSpec.build(_stats, slot.weapon), delta)
	if slot != null and slot.weapon.sight and not _holstered:
		_sight.show_line(_muzzle(_aim), _aim)
	else:
		_sight.hide_line()


## Hacia dónde apunta el dueño y a qué distancia (INF si no hay un punto, como con el stick).
func set_aim(direction: Vector2, distance: float) -> void:
	_aim = direction
	_aim_distance = distance


func weapon() -> WeaponData:
	return slot.weapon if slot != null else null


## Llamar en cada tick mientras se mantiene el gatillo. Devuelve true si el arma disparó (o, en
## los modos continuos, si está funcionando).
func trigger(stats: StatBlock, direction: Vector2, delta: float) -> bool:
	_stats = stats
	if slot == null:
		return false
	_aim = direction
	match slot.weapon.fire_mode:
		WeaponData.FireMode.LASER:
			_laser_tick(stats, direction, delta)
			return _laser.is_active()
		WeaponData.FireMode.ORBITAL:
			return _launch_orb(stats, direction)
		WeaponData.FireMode.RAIL:
			return _rail_tick(direction, delta)
	return try_fire(stats, direction)


## Llamar en cada tick en que no se aprieta el gatillo. Si el riel estaba cargado, dispara.
func idle(stats: StatBlock) -> void:
	_stats = stats
	if _is_rail() and _rail_charge >= slot.weapon.charge_time:
		_fire_rail(stats)
	release()


## Corta el disparo (al soltar el gatillo o al rodar): apaga el láser y descarga el riel sin disparar.
## Los orbes siguen girando.
func release() -> void:
	_rail_charge = -1.0
	if is_node_ready():
		_laser.stop()
		_rail.cancel()


## Corta todo y guarda los orbes (al morir).
func holster() -> void:
	_holstered = true
	release()
	if is_node_ready():
		_orbit.set_active(false)
		_sight.hide_line()


func rail_charge() -> float:
	return _rail_charge


func reload() -> void:
	if slot != null and slot.start_reload():
		release()
		AudioManager.play_sfx(&"reload", 0.05)


## Dispara balas (SINGLE, SPREAD o BURST) si el cooldown y la munición lo permiten.
## Devuelve true si salió el disparo.
func try_fire(stats: StatBlock, direction: Vector2) -> bool:
	if slot == null or _cooldown > COOLDOWN_EPSILON or _burst_left > 0:
		return false
	if not slot.can_fire():
		_on_empty()
		return false
	var data: WeaponData = slot.weapon
	_cooldown = ShotSpec.fire_interval(stats, data)
	var spec := ShotSpec.build(stats, data)
	match data.fire_mode:
		WeaponData.FireMode.SPREAD:
			_spawn(spec, PatternMath.spread(data.projectiles, direction, data.spread_degrees))
		WeaponData.FireMode.BURST:
			_burst_left = data.burst_count - 1
			_burst_timer = data.burst_interval
			_burst_spec = spec
			_spawn_bullet(spec, direction)
		WeaponData.FireMode.GRENADE:
			_throw_grenade(spec, direction)
		_:
			_spawn_bullet(spec, direction)
	slot.consume()
	_reload_if_empty()
	_feedback(direction)
	return true


func _update_burst(delta: float) -> void:
	if _burst_left <= 0:
		return
	_burst_timer -= delta
	if _burst_timer > 0.0:
		return
	if slot == null or not slot.can_fire():
		_burst_left = 0
		return
	_spawn_bullet(_burst_spec, _aim)
	slot.consume()
	_reload_if_empty()
	_feedback(_aim)
	_burst_left -= 1
	_burst_timer = slot.weapon.burst_interval


func _laser_tick(stats: StatBlock, direction: Vector2, delta: float) -> void:
	if not slot.can_fire():
		_laser.stop()
		_on_empty()
		return
	var data: WeaponData = slot.weapon
	var spec := ShotSpec.build(stats, data)
	if _laser.update_beam(global_position + direction * muzzle_distance, direction, spec,
			ShotSpec.fire_interval(stats, data), delta):
		slot.consume()
		_reload_if_empty()
		_feedback(direction)


## Lanza un orbe hacia la mira si la cadencia, la munición y los orbes listos lo permiten. La bala
## atraviesa un enemigo más.
func _launch_orb(stats: StatBlock, direction: Vector2) -> bool:
	if _cooldown > COOLDOWN_EPSILON or _orbit.ready_count() == 0:
		return false
	if not slot.can_fire():
		_on_empty()
		return false
	_cooldown = ShotSpec.fire_interval(stats, slot.weapon)
	var spec := ShotSpec.build(stats, slot.weapon)
	spec.pierce += 1
	_orbit.launch(direction)
	_spawn_bullet(spec, direction)
	slot.consume()
	_feedback(direction)
	return true


## Riel: mientras se mantiene el gatillo se carga; dispara recién al soltarlo (idle).
func _rail_tick(direction: Vector2, delta: float) -> bool:
	if not slot.can_fire():
		release()
		_on_empty()
		return false
	if _cooldown > COOLDOWN_EPSILON:
		return false
	if _rail_charge < 0.0:
		_rail_charge = 0.0
		AudioManager.play_sfx(&"rail_charge")
	_rail_charge += delta
	_rail.charge(_muzzle(direction), direction, minf(1.0, _rail_charge / slot.weapon.charge_time))
	return true


func _fire_rail(stats: StatBlock) -> void:
	var data: WeaponData = slot.weapon
	_rail.color = data.bullet_color
	_rail.fire(_muzzle(_aim), _aim, ShotSpec.build(stats, data))
	_cooldown = ShotSpec.fire_interval(stats, data)
	slot.consume()
	_reload_if_empty()
	_feedback(_aim)


## La granada cae donde se apunta (sin pasar su alcance) y nunca del otro lado de una pared o roca.
## Con el stick no hay un punto: cae en el enemigo más cercano hacia donde se apunta, o a su alcance.
func _throw_grenade(spec: ShotSpec, direction: Vector2) -> void:
	var from: Vector2 = _muzzle(direction)
	var distance: float = _aim_distance
	if is_inf(distance):
		distance = _nearest_enemy_ahead(from, direction, spec.max_range)
	var to: Vector2 = from + direction * minf(distance, spec.max_range)
	var query := PhysicsRayQueryParameters2D.create(from, to, PhysicsLayers.WALL)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		to = hit.position - direction * GRENADE_WALL_MARGIN
	Grenade.throw(get_tree(), GRENADE_SCENE, spec, from, to)


## Distancia al enemigo vivo más cercano dentro de GRENADE_ASSIST_DEGREES de la mira (o `max_range`).
func _nearest_enemy_ahead(from: Vector2, direction: Vector2, max_range: float) -> float:
	var best: float = max_range
	var min_dot: float = cos(deg_to_rad(GRENADE_ASSIST_DEGREES))
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy.health.is_dead() or enemy.is_hidden():
			continue
		var offset: Vector2 = enemy.global_position - from
		if offset.length() < best and offset.normalized().dot(direction) >= min_dot:
			best = offset.length()
	return best


func _muzzle(direction: Vector2) -> Vector2:
	return global_position + direction * muzzle_distance


## Sin balas: si se puede, recarga; si no, "clic".
func _on_empty() -> void:
	if slot.is_reloading():
		return
	if slot.start_reload():
		release()
		AudioManager.play_sfx(&"reload", 0.05)
	elif _cooldown <= COOLDOWN_EPSILON:
		_cooldown = EMPTY_CLICK_INTERVAL
		AudioManager.play_sfx(&"empty")


func _spawn(spec: ShotSpec, directions: Array[Vector2]) -> void:
	for direction: Vector2 in directions:
		_spawn_bullet(spec, direction)


func _spawn_bullet(spec: ShotSpec, direction: Vector2) -> void:
	Bullet.spawn(get_tree(), bullet_scene, spec, global_position + direction * muzzle_distance,
			direction, bullet_layer, bullet_mask)


func _feedback(direction: Vector2) -> void:
	EventBus.shake_requested.emit(slot.weapon.shake_trauma)
	AudioManager.play_sfx(slot.weapon.sfx_id, 0.08)
	fired.emit(direction)


func _is_orbital() -> bool:
	return slot != null and slot.weapon.fire_mode == WeaponData.FireMode.ORBITAL


func _is_rail() -> bool:
	return slot != null and slot.weapon.fire_mode == WeaponData.FireMode.RAIL


func _on_slot_changed() -> void:
	_burst_left = 0
	if not is_node_ready():
		return
	release()
	_orbit.set_active(false)
	var data: WeaponData = weapon()
	if data != null and data.fire_mode == WeaponData.FireMode.ORBITAL:
		_orbit.setup(data.projectiles, data.orbit_radius)
		_orbit.color = data.bullet_color
	if data != null and data.fire_mode == WeaponData.FireMode.LASER:
		_laser.color = data.bullet_color


## Con el cargador vacío empieza a recargar enseguida, sin esperar otro gatillazo.
func _reload_if_empty() -> void:
	if slot.has_magazine() and slot.in_magazine <= 0 and slot.start_reload():
		AudioManager.play_sfx(&"reload", 0.05)
