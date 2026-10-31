class_name RailGun
extends Node2D
## Disparo del caño de riel (RAIL). Mientras se carga se ve una esfera que crece en la boca y una
## línea fina por donde va a salir; al dispararse, un rayo grueso que se apaga en RAIL_FADE segundos
## atraviesa a todos los enemigos en línea (los escudos lo frenan) y corta en paredes y rocas. Se
## dibuja en coordenadas globales.

const RANGE: float = 400.0
const RAIL_FADE: float = 0.25
const MAX_TARGETS: int = 32
const CORE_COLOR: Color = Color("fff6d5")
const SPARK_SCENE: PackedScene = preload("res://fx/bullet_impact.tscn")

var color: Color = Color("7ad1ff")
var _charging: bool = false
var _progress: float = 0.0
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _fade_left: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO


func is_charging() -> bool:
	return _charging


## Muestra la carga (0 a 1) en la boca del arma.
func charge(from: Vector2, direction: Vector2, progress: float) -> void:
	_charging = true
	_progress = progress
	_from = from
	_to = _wall_end(from, direction)
	queue_redraw()


func cancel() -> void:
	if _charging:
		_charging = false
		queue_redraw()


## Dispara: le pega a todos los enemigos en línea hasta la primera pared, roca o escudo.
func fire(from: Vector2, direction: Vector2, spec: ShotSpec) -> void:
	_charging = false
	_from = from
	_to = from + direction * RANGE
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var exclude: Array[RID] = []
	for _i: int in MAX_TARGETS:
		var query := PhysicsRayQueryParameters2D.create(from, _to, PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX, exclude)
		query.collide_with_areas = true
		query.hit_from_inside = true
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			break
		var hurtbox := hit.collider as HurtboxComponent
		if hurtbox == null or hurtbox.guards(direction):
			_to = hit.position
			break
		if hurtbox.receive_hit(HitInfo.create(spec.damage, direction, spec.knockback)):
			StatusComponent.apply_hit(hurtbox, spec)
		var spark := Fx.spawn(get_tree(), SPARK_SCENE, hit.position) as CPUParticles2D
		spark.color = color
		exclude.append(hit.rid)
	_fade_left = RAIL_FADE
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _fade_left > 0.0:
		_fade_left = maxf(0.0, _fade_left - delta)
	if _charging or _fade_left > 0.0:
		queue_redraw()


func _wall_end(from: Vector2, direction: Vector2) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(from, from + direction * RANGE, PhysicsLayers.WALL)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else from + direction * RANGE


func _draw() -> void:
	if _charging:
		var ready_blink: bool = _progress >= 1.0 and int(_time * 14.0) % 2 == 0
		draw_line(_from, _to, Color(color, 0.15 + 0.25 * _progress), 1.0)
		draw_circle(_from, 1.0 + 2.5 * _progress, Color(color, 0.8))
		draw_circle(_from, 1.0 + 1.2 * _progress, CORE_COLOR if ready_blink or _progress < 1.0 else color)
	if _fade_left > 0.0:
		var t: float = _fade_left / RAIL_FADE
		draw_line(_from, _to, Color(color, 0.4 * t), 7.0 * t)
		draw_line(_from, _to, Color(color, t), 3.0 * t + 1.0)
		draw_line(_from, _to, Color(CORE_COLOR, t), 1.0)
