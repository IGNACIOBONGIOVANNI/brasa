class_name Trap
extends Node2D
## Una trampa del piso armada desde su TrapData (la pone la sala en cada "^" de la plantilla).
## Pasa por REST → WARN (avisa: se ve venir) → ACTIVE (lastima lo que toque, una vez a cada uno) →
## REST. Las TIMED arrancan desfasadas según `offset` (fracción del ciclo) para formar patrones; las
## PROXIMITY esperan a que alguien se acerque. La sala la frena (process_mode) cuando no es la actual.

enum Stage { REST, WARN, ACTIVE }

## Al aparecer la sala, ninguna trampa se activa antes de esto.
const START_GRACE: float = 0.8
const WARN_SFX: StringName = &"trap_warn"

## Último tick de física en que sonó cada sonido de trampa (varias juntas suenan como una).
static var _sound_ticks: Dictionary[StringName, int] = {}

var data: TrapData
## Hacia dónde sale el chorro (NOZZLE).
var direction: Vector2 = Vector2.RIGHT
var stage: Stage = Stage.REST
var _offset: float = 0.0
var _left: float = 0.0
## Hurtboxes que ya lastimó en esta activación (por id).
var _hit: Dictionary[int, bool] = {}

@onready var _zone: Area2D = $Zone
@onready var _shape: CollisionShape2D = $Zone/CollisionShape2D
@onready var _visual: TrapVisual = $Visual


## Llamar antes de agregarla al árbol.
func setup(trap_data: TrapData, cycle_offset: float, jet_direction: Vector2) -> void:
	data = trap_data
	_offset = cycle_offset
	direction = jet_direction


func _ready() -> void:
	assert(data != null, "Trap: falta llamar setup()")
	_zone.collision_layer = 0
	_zone.collision_mask = PhysicsLayers.PLAYER_HURTBOX | PhysicsLayers.ENEMY_HURTBOX
	if data.look == TrapData.Look.NOZZLE:
		var box := RectangleShape2D.new()
		box.size = Vector2(data.length, data.radius * 2.0)
		_shape.shape = box
		_shape.position = direction * data.length * 0.5
		_shape.rotation = direction.angle()
	else:
		var circle := CircleShape2D.new()
		circle.radius = data.radius
		_shape.shape = circle
	_visual.configure(data, direction)
	reset()


## Vuelve a quieta con el desfase del principio (al aparecer o al volver a la sala).
func reset() -> void:
	stage = Stage.REST
	_hit.clear()
	_left = START_GRACE
	if data.trigger == TrapData.Trigger.TIMED:
		_left += data.cycle_time() * _offset
	_visual.show_stage(stage, 0.0, false)


func _physics_process(delta: float) -> void:
	_left -= delta
	match stage:
		Stage.REST:
			if _left <= 0.0 and (data.trigger == TrapData.Trigger.TIMED or _someone_near()):
				_enter(Stage.WARN)
		Stage.WARN:
			if _left <= 0.0:
				_enter(Stage.ACTIVE)
		Stage.ACTIVE:
			_hurt_overlapping()
			if _left <= 0.0:
				_enter(Stage.REST)
	_visual.show_stage(stage, _progress(), stage == Stage.REST and _left > 0.0)


func _enter(new_stage: Stage) -> void:
	stage = new_stage
	match stage:
		Stage.REST:
			_left = data.rest_time
		Stage.WARN:
			_left = data.warn_time
			_play(WARN_SFX)
		Stage.ACTIVE:
			_left = data.active_time
			_hit.clear()
			_play(data.sfx_id)


## Qué tanto pasó de la etapa actual (0 a 1).
func _progress() -> float:
	var total: float = data.warn_time if stage == Stage.WARN else data.active_time if stage == Stage.ACTIVE else data.rest_time
	return 1.0 - clampf(_left / total, 0.0, 1.0) if total > 0.0 else 1.0


func _someone_near() -> bool:
	for node: Node in get_tree().get_nodes_in_group(Player.GROUP):
		var player := node as Player
		if not player.is_dead() and player.global_position.distance_to(global_position) <= data.trigger_radius:
			return true
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if not enemy.is_hidden() and not enemy.health.is_dead() \
				and enemy.global_position.distance_to(global_position) <= data.trigger_radius:
			return true
	return false


## A cada hurtbox una vez por activación. Si el jugador estaba invulnerable (rodando), lo vuelve a
## intentar mientras siga activa.
func _hurt_overlapping() -> void:
	if not _zone.monitoring:
		return
	for area: Area2D in _zone.get_overlapping_areas():
		var hurtbox := area as HurtboxComponent
		if hurtbox == null or _hit.has(hurtbox.get_instance_id()):
			continue
		var enemy := hurtbox.owner as Enemy
		if enemy != null and (enemy.is_hidden() or enemy.health.is_dead()):
			continue
		var damage: float = data.enemy_damage if enemy != null else data.player_damage
		var info := HitInfo.create(damage, hurtbox.global_position - global_position, data.knockback)
		if hurtbox.receive_hit(info):
			_hit[hurtbox.get_instance_id()] = true
			if enemy != null and data.applies_status:
				enemy.status.apply(data.status, data.enemy_damage)


## Varias trampas que se activan juntas suenan una sola vez.
static func _play(sfx_id: StringName) -> void:
	if sfx_id == &"":
		return
	var tick: int = Engine.get_physics_frames()
	if _sound_ticks.get(sfx_id, -1) == tick:
		return
	_sound_ticks[sfx_id] = tick
	AudioManager.play_sfx(sfx_id, 0.08)
