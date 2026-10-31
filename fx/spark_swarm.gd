class_name SparkSwarm
extends Node2D
## Las chispas que suelta un enemigo al morir (ver docs/LORE.md): salen disparadas para todos lados y
## después vuelan hacia el jugador hasta que lo alcanzan. Solo visual (no suman nada: las chispas de
## verdad se cuentan al terminar la run). Usa el stream COSMETIC.

const BURST_SPEED_MIN: float = 40.0
const BURST_SPEED_MAX: float = 90.0
## Aceleración hacia el jugador (px/s²) y velocidad máxima.
const PULL: float = 600.0
const MAX_SPEED: float = 260.0
## Frenado del impulso inicial, para que se note el "vuelo de vuelta".
const DRAG: float = 3.0
const CATCH_DISTANCE: float = 5.0
const MAX_LIFETIME: float = 2.5
const CORE_COLOR: Color = Color("fff6d5")

var count: int = 4
var color: Color = Color("ffb35c")
var _positions: PackedVector2Array = []
var _velocities: PackedVector2Array = []
var _target: Node2D
var _age: float = 0.0


func _ready() -> void:
	top_level = true
	_target = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.COSMETIC)
	for _i: int in count:
		_positions.append(position)
		var angle: float = rng.randf() * TAU
		_velocities.append(Vector2.from_angle(angle) * rng.randf_range(BURST_SPEED_MIN, BURST_SPEED_MAX))
	position = Vector2.ZERO


func _process(delta: float) -> void:
	_age += delta
	if _age >= MAX_LIFETIME or _positions.is_empty() or not is_instance_valid(_target):
		queue_free()
		return
	var goal: Vector2 = _target.global_position + Vector2(0, -2)
	for i: int in range(_positions.size() - 1, -1, -1):
		var to_goal: Vector2 = goal - _positions[i]
		if to_goal.length() <= CATCH_DISTANCE:
			_positions.remove_at(i)
			_velocities.remove_at(i)
			continue
		var velocity: Vector2 = _velocities[i] * maxf(0.0, 1.0 - DRAG * delta)
		velocity += to_goal.normalized() * PULL * delta
		_velocities[i] = velocity.limit_length(MAX_SPEED)
		_positions[i] += _velocities[i] * delta
	queue_redraw()


func _draw() -> void:
	for i: int in _positions.size():
		var at: Vector2 = _positions[i].round()
		var tail: Vector2 = (_positions[i] - _velocities[i].normalized() * 2.0).round()
		draw_rect(Rect2(tail, Vector2.ONE), Color(color, 0.6))
		draw_rect(Rect2(at, Vector2.ONE), CORE_COLOR)
