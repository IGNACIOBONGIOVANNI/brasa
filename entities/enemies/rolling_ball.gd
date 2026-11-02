class_name RollingBall
extends Node2D
## Bola de nieve gigante de un jefe (SNOWBALL): rueda a `velocity`, rebota en los bordes de `area` (la
## sala), rompe las rocas que toca, crece hasta GROWTH veces su radio y se deshace a los `lifetime` s.
## Lastima al jugador al pasarle por encima (los i-frames marcan cada cuánto). Se ve siempre.

const GROUP: StringName = &"rolling_balls"
const UNSHADED: Material = preload("res://fx/unshaded.tres")
const DUST_SCENE: PackedScene = preload("res://fx/dust_puff.tscn")
const GROWTH: float = 1.6
const KNOCKBACK: float = 160.0
const SNOW_COLOR: Color = Color("e8f1fa")
const SHADE_COLOR: Color = Color("9fb4cc")
const OUTLINE_COLOR: Color = Color("2a3346")
## Lo que tarda en deshacerse al final.
const MELT_TIME: float = 0.3

var velocity: Vector2 = Vector2.ZERO
var radius: float = 10.0
var damage: float = 1.0
var lifetime: float = 4.0
var area: Rect2 = Rect2(-120, -72, 240, 144)
var _start_radius: float = 0.0
var _elapsed: float = 0.0
var _spin: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	material = UNSHADED
	_start_radius = radius


## Se deshace sin más (murió el jefe).
func vanish() -> void:
	queue_free()


func current_radius() -> float:
	return lerpf(_start_radius, _start_radius * GROWTH, clampf(_elapsed / maxf(0.01, lifetime), 0.0, 1.0))


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= lifetime + MELT_TIME:
		var dust := Fx.spawn(get_tree(), DUST_SCENE, global_position) as CPUParticles2D
		dust.color = SNOW_COLOR
		queue_free()
		return
	if _elapsed >= lifetime:
		return
	var size: float = current_radius()
	global_position += velocity * delta
	var inner: Rect2 = area.grow(-size)
	if global_position.x < inner.position.x or global_position.x > inner.end.x:
		velocity.x = -velocity.x
		global_position.x = clampf(global_position.x, inner.position.x, inner.end.x)
		AudioManager.play_sfx(&"snowball", 0.15)
	if global_position.y < inner.position.y or global_position.y > inner.end.y:
		velocity.y = -velocity.y
		global_position.y = clampf(global_position.y, inner.position.y, inner.end.y)
		AudioManager.play_sfx(&"snowball", 0.15)
	_spin += velocity.length() / maxf(1.0, size) * delta
	for node: Node in get_tree().get_nodes_in_group(Rock.GROUP):
		var rock := node as Rock
		if rock.global_position.distance_to(global_position) <= size + Rock.HALF_SIZE * 0.6:
			rock.destroy()
	for node: Node in get_tree().get_nodes_in_group(Player.GROUP):
		var player := node as Player
		var offset: Vector2 = player.global_position - global_position
		if offset.length() <= size + 3.0:
			player.hurtbox.receive_hit(HitInfo.create(damage, offset.normalized() if offset != Vector2.ZERO else velocity.normalized(), KNOCKBACK))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var size: float = current_radius()
	var melt: float = 1.0 - clampf((_elapsed - lifetime) / MELT_TIME, 0.0, 1.0)
	draw_set_transform(Vector2(0, size * 0.7), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, size, Color(0, 0, 0, 0.3 * melt))
	draw_set_transform(Vector2.ZERO)
	var body: float = size * melt
	draw_circle(Vector2.ZERO, body + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, body, SHADE_COLOR)
	draw_circle(Vector2(-body * 0.15, -body * 0.15), body * 0.82, SNOW_COLOR)
	# Rayas que giran: se ve rodar.
	for i: int in 3:
		var angle: float = _spin + TAU * i / 3.0
		var at: Vector2 = Vector2.from_angle(angle) * body * 0.55
		draw_circle(at, maxf(1.0, body * 0.12), SHADE_COLOR)
