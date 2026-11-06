class_name CrownBoomerang
extends Node2D
## Una corona de clavos tirada como bumerán (CrownBoomerangMove): sale girando hacia `direction`,
## frena a los `out_time` s, suelta `pattern` y vuelve a la mano de `owner_id` (el jefe; si murió, se
## deshace). Lastima al tocarla, en `radius`.

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const GOLD: Color = Color("e2b84a")
const NAIL: Color = Color("8a8f99")
const OUTLINE: Color = Color("1b1420")
const REACH: float = 3.0
## Se deshace al llegar tan cerca del jefe (lo atrapó).
const CATCH_DISTANCE: float = 8.0
const SPIN_SPEED: float = 14.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 160.0
var out_time: float = 0.8
var radius: float = 7.0
var damage: float = 1.0
var pattern: BulletPatternData
var speed_multiplier: float = 1.0
var owner_id: int = 0
var _time: float = 0.0
var _returning: bool = false


func _ready() -> void:
	add_to_group(BossMove.HAZARD_GROUP)
	material = UNSHADED


func is_returning() -> bool:
	return _returning


func _physics_process(delta: float) -> void:
	_time += delta
	var holder := instance_from_id(owner_id) as Node2D
	if not _returning:
		# Sale rápido y frena hasta quedar quieta al final de la ida.
		var slow: float = clampf(1.0 - _time / out_time, 0.0, 1.0)
		global_position += direction * speed * slow * delta
		if _time >= out_time:
			_returning = true
			_burst()
	else:
		if holder == null:
			queue_free()
			return
		var back: Vector2 = holder.global_position - global_position
		if back.length() <= CATCH_DISTANCE:
			queue_free()
			return
		var pace: float = minf(speed * 1.1, speed * 0.3 + (_time - out_time) * speed * 1.5)
		global_position += back.normalized() * minf(pace * delta, back.length())
	BossMove.hurt_players(get_tree(), damage, global_position,
			func(at: Vector2) -> bool: return at.distance_to(global_position) <= radius + REACH)


func _burst() -> void:
	AudioManager.play_sfx(&"snip", 0.1)
	if pattern == null:
		return
	var spec := ShotSpec.from_pattern(pattern)
	spec.speed *= speed_multiplier
	for shot: Vector2 in PatternMath.ring(pattern.count, _time):
		Bullet.spawn(get_tree(), Bullet.default_scene(), spec, global_position + shot * radius, shot,
				PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var spin: float = _time * SPIN_SPEED
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius * 0.8, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	for i: int in 6:
		var spike := Vector2.from_angle(spin + TAU * i / 6.0)
		draw_line(spike * radius * 0.6, spike * radius * 1.35, OUTLINE, 3.0)
		draw_line(spike * radius * 0.6, spike * radius * 1.3, NAIL, 1.0)
	draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 16, OUTLINE, 4.0)
	draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 16, GOLD, 2.0)
	draw_arc(Vector2.ZERO, radius * 0.7, spin, spin + 1.2, 6, GOLD.lightened(0.5), 1.0)
