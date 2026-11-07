class_name AshPuff
extends Node2D
## Una nube de hollín que deja el Deshollinador al barrer (SootSweepMove): no lastima al tocarla, pero
## se hincha y se pone al rojo durante `life` s y revienta en las balas de `pattern` (en anillo, girado
## `spin`). Va en el grupo de lo que borra la muerte del jefe.

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const SOOT_COLOR: Color = Color(0.16, 0.14, 0.17, 0.85)
const EDGE_COLOR: Color = Color(0.42, 0.38, 0.44, 0.9)
const HOT_COLOR: Color = Color("ff8a3d")
const CORE_COLOR: Color = Color("ffd166")

var radius: float = 7.0
var life: float = 0.9
var pattern: BulletPatternData
var speed_multiplier: float = 1.0
var spin: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	add_to_group(BossMove.HAZARD_GROUP)
	material = UNSHADED


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= life:
		_pop()


func _pop() -> void:
	if pattern != null:
		var spec := ShotSpec.from_pattern(pattern)
		spec.speed *= speed_multiplier
		for direction: Vector2 in PatternMath.ring(pattern.count, spin):
			Bullet.spawn(get_tree(), Bullet.default_scene(), spec, global_position + direction * 2.0, direction,
					PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)
	AudioManager.play_sfx(&"trap_pop", 0.1)
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var k: float = clampf(_time / life, 0.0, 1.0)
	var grow: float = minf(1.0, _time / 0.2)
	var size: float = radius * (0.5 + 0.5 * grow + 0.3 * k)
	# Tres bollos de hollín que se mueven un poco.
	for i: int in 3:
		var offset: Vector2 = Vector2.from_angle(spin + TAU * i / 3.0 + _time * 1.5) * size * 0.35
		draw_circle(offset, size * 0.7 + 1.0, EDGE_COLOR)
		draw_circle(offset, size * 0.7, SOOT_COLOR)
	# Se pone al rojo de adentro hacia afuera: avisa que va a reventar.
	var heat: float = k * k
	draw_circle(Vector2.ZERO, size * 0.6 * heat, Color(HOT_COLOR, 0.35 + 0.5 * heat))
	if k > 0.7 and fmod(_time, 0.12) < 0.06:
		draw_circle(Vector2.ZERO, size * 0.25, CORE_COLOR)
	for i: int in 3:
		var spark: Vector2 = Vector2.from_angle(spin * 2.0 + i * 2.1 + _time * 4.0) * size * 0.5
		draw_rect(Rect2(spark.round(), Vector2.ONE), Color(CORE_COLOR, heat))
