class_name Grenade
extends Node2D
## Granada del lanzagranadas: vuela en arco por arriba de todo (enemigos, fosos) hasta donde se
## apuntó y explota al caer (PlayerBlast).

const ARC_HEIGHT: float = 22.0
const MIN_FLIGHT: float = 0.25
const OUTLINE_COLOR: Color = Color("120c16")

var spec: ShotSpec
var origin: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var _duration: float = 0.5
var _elapsed: float = 0.0


## Tira una granada (`scene`, la de grenade.tscn) de `from` a `to` (globales) con los datos de `shot`.
static func throw(tree: SceneTree, scene: PackedScene, shot: ShotSpec, from: Vector2, to: Vector2) -> Grenade:
	var grenade := Fx.spawn(tree, scene, from, Bullet.PROJECTILES_GROUP) as Grenade
	grenade.spec = shot
	grenade.origin = from
	grenade.target = to
	grenade._duration = maxf(MIN_FLIGHT, from.distance_to(to) / shot.speed)
	return grenade


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / _duration, 0.0, 1.0)
	global_position = origin.lerp(target, t)
	if t >= 1.0:
		PlayerBlast.explode(get_tree(), global_position, spec)
		queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t: float = clampf(_elapsed / _duration, 0.0, 1.0)
	var height: float = roundf(ARC_HEIGHT * 4.0 * t * (1.0 - t))
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, spec.radius, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -height))
	draw_circle(Vector2.ZERO, spec.radius + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, spec.radius, spec.color.darkened(0.3))
	# La mecha que titila.
	if int(_elapsed * 12.0) % 2 == 0:
		draw_rect(Rect2(Vector2(1, -spec.radius - 1.0), Vector2.ONE), spec.color.lightened(0.4))
