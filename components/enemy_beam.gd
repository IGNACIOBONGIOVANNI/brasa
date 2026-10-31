class_name EnemyBeam
extends Node2D
## Rayo de un enemigo (BEAM). Primero se ve una línea fina que avisa por dónde va a salir (preview) y
## después el rayo de verdad (fire): corta en paredes y rocas y lastima al jugador si lo cruza.
## Rodando se atraviesa (el jugador está invulnerable). Se dibuja en coordenadas globales.

const RANGE: float = 280.0
const KNOCKBACK: float = 120.0
const CORE_COLOR: Color = Color("fff6d5")

enum Mode { OFF, PREVIEW, FIRE }

var color: Color = Color("ff4d6d")
var _mode: Mode = Mode.OFF
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _time: float = 0.0


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO


func is_firing() -> bool:
	return _mode == Mode.FIRE


## La línea fina del aviso.
func preview(from: Vector2, direction: Vector2) -> void:
	_mode = Mode.PREVIEW
	_from = from
	_to = _wall_end(from, direction)
	queue_redraw()


## El rayo de verdad; llamar en cada tick mientras dura. Lastima al jugador si lo cruza.
func fire(from: Vector2, direction: Vector2, damage: float) -> void:
	_mode = Mode.FIRE
	_from = from
	_to = _wall_end(from, direction)
	var query := PhysicsRayQueryParameters2D.create(_from, _to, PhysicsLayers.PLAYER_HURTBOX)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.hit_from_inside = true
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	var hurtbox := hit.get("collider") as HurtboxComponent
	if hurtbox != null:
		hurtbox.receive_hit(HitInfo.create(damage, direction, KNOCKBACK))
	queue_redraw()


func stop() -> void:
	if _mode != Mode.OFF:
		_mode = Mode.OFF
		queue_redraw()


func _process(delta: float) -> void:
	if _mode != Mode.OFF:
		_time += delta
		queue_redraw()


## Hasta dónde llega el rayo: la primera pared o roca.
func _wall_end(from: Vector2, direction: Vector2) -> Vector2:
	var to: Vector2 = from + direction * RANGE
	var query := PhysicsRayQueryParameters2D.create(from, to, PhysicsLayers.WALL)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else to


func _draw() -> void:
	match _mode:
		Mode.PREVIEW:
			var blink: float = 0.35 + 0.35 * sin(_time * 30.0)
			draw_line(_from, _to, Color(color, blink), 1.0)
		Mode.FIRE:
			var flicker: float = 0.8 + 0.2 * sin(_time * 50.0)
			draw_line(_from, _to, Color(color, 0.35 * flicker), 5.0)
			draw_line(_from, _to, Color(color, flicker), 3.0)
			draw_line(_from, _to, CORE_COLOR, 1.0)
			draw_circle(_to, 2.0 * flicker, CORE_COLOR)
