class_name ChargedOrb
extends Node2D
## La bola de fuego que un jefe junta arriba de la cabeza antes de tirarla (ChargedOrbMove): crece,
## late y chupa chispitas de alrededor. Solo se ve; lo que pega es la bala que sale al tirarla.

const GROUP: StringName = &"charged_orbs"
const CORE_COLOR: Color = Color("fff1a8")
const SPARKS: int = 8

var radius: float = 2.0
var color: Color = Color("ff8a3d")
var _time: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse: float = 1.0 + 0.08 * sin(_time * 14.0)
	var size: float = radius * pulse
	draw_circle(Vector2.ZERO, size * 1.5, Color(color, 0.18))
	draw_circle(Vector2.ZERO, size + 1.0, color.darkened(0.45))
	draw_circle(Vector2.ZERO, size, color)
	draw_circle(Vector2.ZERO, size * 0.65, color.lightened(0.35))
	draw_circle(Vector2(-size * 0.2, -size * 0.2), size * 0.35, CORE_COLOR)
	for i: int in SPARKS:
		var fall: float = fmod(_time * 1.6 + float(i) / SPARKS, 1.0)
		var angle: float = TAU * i / SPARKS + _time * 1.5
		var at: Vector2 = (Vector2.from_angle(angle) * (size + 4.0 + (1.0 - fall) * 14.0)).round()
		draw_rect(Rect2(at, Vector2.ONE), Color(CORE_COLOR, fall))
