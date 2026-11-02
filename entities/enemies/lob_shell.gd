class_name LobShell
extends Node2D
## Bola de fuego del Fogonero (LOB): vuela en arco desde donde la tiraron hasta donde estaba el
## jugador, con una marca en el piso que avisa dónde va a caer. Al caer explota (EnemyBlast). Un Pulso
## la apaga en el aire. El nodo está en el punto donde cae; la bola se dibuja corrida.
## Con `fuse` > 0 es una bomba de jefe (FRAG_BOMBS): cae, queda `fuse` s en el piso con la mecha
## prendida y el radio marcado, y recién ahí explota (la metralla es `pattern`). El Pulso también la
## apaga en el piso.

const GROUP: StringName = &"lob_shells"
const ARC_HEIGHT: float = 42.0
const BALL_RADIUS: float = 3.0
const CORE_COLOR: Color = Color("fff6d5")
const SMOKE_SCENE: PackedScene = preload("res://fx/dust_puff.tscn")

## Desde dónde la tiraron (global).
var origin: Vector2 = Vector2.ZERO
var duration: float = 0.9
var damage: float = 1.0
var radius: float = 24.0
var pattern: BulletPatternData
var speed_multiplier: float = 1.0
var color: Color = Color("ff8a3d")
## Segundos en el piso antes de explotar (0 = explota al caer).
var fuse: float = 0.0
var _elapsed: float = 0.0
var _landed: bool = false


func _ready() -> void:
	add_to_group(GROUP)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration and not _landed and fuse > 0.0:
		_landed = true
		AudioManager.play_sfx(&"bomb_place", 0.15)
	if _elapsed >= duration + fuse:
		EnemyBlast.explode(get_tree(), global_position, radius, damage, pattern, speed_multiplier, color)
		queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


## Se apaga en el aire (Pulso): un poco de humo y nada más.
func fizzle() -> void:
	Fx.spawn(get_tree(), SMOKE_SCENE, global_position + _ball_offset())
	queue_free()


## Dónde va la bola respecto del punto de caída: en línea recta y con la altura del arco.
func _ball_offset() -> Vector2:
	var t: float = clampf(_elapsed / duration, 0.0, 1.0)
	var ground: Vector2 = origin.lerp(global_position, t) - global_position
	return ground + Vector2(0, -ARC_HEIGHT * 4.0 * t * (1.0 - t))


func _draw() -> void:
	if _landed:
		_draw_bomb()
		return
	var t: float = clampf(_elapsed / duration, 0.0, 1.0)
	# La marca crece y late a medida que se acerca.
	var blink: float = 0.4 + 0.3 * sin(_elapsed * 20.0)
	draw_arc(Vector2.ZERO, radius * (0.4 + 0.6 * t), 0.0, TAU, 24, Color(color, blink), 1.0)
	draw_circle(Vector2.ZERO, radius * t, Color(color, 0.12))
	var ball: Vector2 = _ball_offset().round()
	draw_set_transform(Vector2(ball.x, roundf(lerpf(origin.y - global_position.y, 0.0, t)) + 2.0), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, BALL_RADIUS, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_circle(ball, BALL_RADIUS + 1.0, color.darkened(0.4))
	draw_circle(ball, BALL_RADIUS, color)
	draw_circle(ball + Vector2(-1, -1), 1.0, CORE_COLOR)


## En el piso: el radio marcado, la bomba y la mecha que titila cada vez más rápido.
func _draw_bomb() -> void:
	var left: float = clampf(1.0 - (_elapsed - duration) / fuse, 0.0, 1.0)
	var blink: float = 0.5 + 0.5 * sin(_elapsed * lerpf(40.0, 12.0, left))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(color, 0.35 + 0.4 * blink), 1.0)
	draw_circle(Vector2.ZERO, radius * (1.0 - left), Color(color, 0.1))
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, BALL_RADIUS + 1.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	var body := Vector2(0, -2)
	draw_circle(body, BALL_RADIUS + 2.0, color.darkened(0.7))
	draw_circle(body, BALL_RADIUS + 1.0, color.darkened(0.5))
	draw_circle(body + Vector2(-1, -1), 1.0, color.darkened(0.1))
	draw_line(body + Vector2(1, -BALL_RADIUS - 1.0), body + Vector2(2, -BALL_RADIUS - 3.0), color.darkened(0.3), 1.0)
	draw_circle(body + Vector2(2, -BALL_RADIUS - 3.0), 0.5 + blink, Color(CORE_COLOR, blink))
