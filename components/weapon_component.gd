class_name WeaponComponent
extends Node2D
## Dispara el arma actual (un WeaponSlot, con su munición) con los stats que le pasa su dueño.
## El dueño llama trigger() en cada tick mientras se mantiene el gatillo e idle() en los demás;
## release() corta el disparo (al rodar) y holster() además guarda los orbes (al morir).
## SINGLE, SPREAD y BURST disparan balas respetando la cadencia; LASER es continuo (LaserBeam) y en
## ORBITAL los orbes giran solos mientras el arma está equipada y el gatillo los lanza (OrbitRing).

signal fired(direction: Vector2)

## Margen para que un intervalo exacto (p. ej. 20 ticks) no se pierda por error de punto flotante.
const COOLDOWN_EPSILON: float = 0.001
## Segundos entre los "clic" de arma vacía.
const EMPTY_CLICK_INTERVAL: float = 0.35

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

@onready var _laser: LaserBeam = $LaserBeam
@onready var _orbit: OrbitRing = $OrbitRing


func _ready() -> void:
	_on_slot_changed()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if slot != null and slot.update(delta):
		AudioManager.play_sfx(&"reload", 0.1)
	_update_burst(delta)
	if not _holstered and _stats != null and _is_orbital():
		_orbit.tick(ShotSpec.build(_stats, slot.weapon), delta)


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
	return try_fire(stats, direction)


## Llamar en cada tick en que no se aprieta el gatillo.
func idle(stats: StatBlock) -> void:
	_stats = stats
	release()


## Corta el disparo (al soltar el gatillo o al rodar). Los orbes siguen girando.
func release() -> void:
	if is_node_ready():
		_laser.stop()


## Corta todo y guarda los orbes (al morir).
func holster() -> void:
	_holstered = true
	release()
	if is_node_ready():
		_orbit.set_active(false)


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
