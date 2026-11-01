class_name MechDrawing
extends RefCounted
## Dibujo placeholder de un armazón, compartido por el que está parado (ParkedMech) y el que maneja
## el jugador (PlayerVisual): sombra, dos patas que se alternan al caminar, casco con franja, cabina
## (con la chispa adentro o vacía) y el arma que sigue la mira. Con poco blindaje echa humo.

const OUTLINE_COLOR: Color = Color("120c16")
const GLASS_COLOR: Color = Color("1d2a33")
const GLASS_SHINE_COLOR: Color = Color("4d6b7d")
const SMOKE_COLOR: Color = Color(0.25, 0.22, 0.28, 0.7)
## Con menos de esta fracción de blindaje echa humo.
const SMOKE_BELOW: float = 0.35


## `pilot_color` transparente = cabina vacía. `step` alterna las patas (0 o 1). `armor_fraction` en [0, 1].
static func draw(canvas: CanvasItem, data: MechData, aim: Vector2, step: int, pilot_color: Color,
		gun_color: Color, gun_length: float, recoil: float, armor_fraction: float, time: float) -> void:
	canvas.draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.0, 0.4))
	canvas.draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.35))
	canvas.draw_set_transform(Vector2.ZERO)
	var dark: Color = data.body_color.darkened(0.35)
	for side: int in [-1, 1]:
		var lift: float = -1.0 if (side < 0) == (step == 0) else 0.0
		var leg := Rect2(side * 4 - 2, 1 + lift, 4, 6)
		canvas.draw_rect(leg.grow(1.0), OUTLINE_COLOR)
		canvas.draw_rect(leg, dark)
		canvas.draw_rect(Rect2(leg.position.x - 1, leg.end.y - 1, 6, 2), dark.darkened(0.2))
	var gun_behind: bool = aim.y < -0.3
	if gun_behind:
		_draw_gun(canvas, aim, gun_color, gun_length, recoil)
	var hull := Rect2(-7, -12, 14, 13)
	canvas.draw_rect(hull.grow(1.0), OUTLINE_COLOR)
	canvas.draw_rect(hull, data.body_color)
	canvas.draw_rect(Rect2(hull.position.x, hull.end.y - 3, hull.size.x, 3), dark)
	canvas.draw_rect(Rect2(hull.position.x, -3, hull.size.x, 1), data.accent_color)
	var cockpit := Vector2(0, -7)
	canvas.draw_circle(cockpit, 4.0, OUTLINE_COLOR)
	if pilot_color.a > 0.0:
		canvas.draw_circle(cockpit, 3.0, pilot_color)
		var look: Vector2 = (aim * 1.0).round()
		canvas.draw_rect(Rect2(cockpit + Vector2(-2, -1) + look, Vector2(1, 2)), OUTLINE_COLOR)
		canvas.draw_rect(Rect2(cockpit + Vector2(1, -1) + look, Vector2(1, 2)), OUTLINE_COLOR)
	else:
		canvas.draw_circle(cockpit, 3.0, GLASS_COLOR)
		canvas.draw_rect(Rect2(cockpit + Vector2(-2, -2), Vector2(1, 1)), GLASS_SHINE_COLOR)
	canvas.draw_rect(Rect2(hull.end.x - 3, hull.position.y + 1, 2, 1), data.accent_color)
	if not gun_behind:
		_draw_gun(canvas, aim, gun_color, gun_length, recoil)
	if armor_fraction < SMOKE_BELOW:
		for i: int in 2:
			var rise: float = fmod(time * 1.5 + i * 0.5, 1.0)
			var at := Vector2(-3 + i * 6, -13 - rise * 6.0).round()
			canvas.draw_rect(Rect2(at, Vector2(2, 2)), Color(SMOKE_COLOR, SMOKE_COLOR.a * (1.0 - rise)))


static func _draw_gun(canvas: CanvasItem, aim: Vector2, color: Color, length: float, recoil: float) -> void:
	canvas.draw_set_transform(Vector2(0, -4), aim.angle())
	var start: float = 5.0 - recoil
	canvas.draw_rect(Rect2(start - 1.0, -2.5, length + 2.0, 5.0), OUTLINE_COLOR)
	canvas.draw_rect(Rect2(start, -1.5, length, 3.0), color)
	canvas.draw_rect(Rect2(start, -1.5, 2.0, 3.0), color.darkened(0.3))
	canvas.draw_set_transform(Vector2.ZERO)
