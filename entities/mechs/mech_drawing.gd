class_name MechDrawing
extends RefCounted
## Dibujo placeholder de un armazón, compartido por el que está parado (ParkedMech) y el que maneja
## el jugador (PlayerVisual). Cada chasis (MechData.frame) tiene su silueta:
## - HEAVY: bajo y ancho, patas cortas con pies grandes, hombreras, dos chimeneas que echan vapor, la
##   cabina es una visera en el pecho y el cañón grueso sale del hombro que apunta.
## - WALKER: una cápsula alta sobre dos patas de ave (la rodilla dobla para atrás), el piloto sentado
##   arriba a cielo abierto, un ojo-sensor adelante, una antena y una ametralladora fina abajo. Parado
##   se agacha.
## - STANDARD: de forma humana, con la cabina redonda en el pecho, un brazo colgando, el otro es el
##   arma (con la llamita piloto en la punta) y un fuelle en la espalda que respira.
## Con poco blindaje echa humo negro.

const OUTLINE_COLOR: Color = Color("120c16")
const GLASS_COLOR: Color = Color("1d2a33")
const GLASS_SHINE_COLOR: Color = Color("4d6b7d")
const SMOKE_COLOR: Color = Color(0.25, 0.22, 0.28, 0.7)
const STEAM_COLOR: Color = Color(0.86, 0.85, 0.9, 0.55)
## Con menos de esta fracción de blindaje echa humo.
const SMOKE_BELOW: float = 0.35
## Cuánto baja la cápsula del WALKER parado (agachado).
const CROUCH: float = 3.0


## Lo que hace falta para dibujar un cuadro (así cada parte no recibe diez argumentos).
class Pose:
	var canvas: CanvasItem
	var data: MechData
	var aim: Vector2
	## 0 o 1 alterna las patas al caminar; -1 = quieto.
	var step: int
	var pilot_color: Color
	var gun_color: Color
	var gun_length: float
	var recoil: float
	var time: float

	func piloted() -> bool:
		return pilot_color.a > 0.0

	## Cuánto levanta la pata de ese lado (-1 izquierda, 1 derecha) en este paso.
	func lift(side: int, height: float) -> float:
		return -height if step >= 0 and (side < 0) == (step == 0) else 0.0

	## Hacia qué lado apunta (-1 o 1).
	func aim_side() -> float:
		return -1.0 if aim.x < 0.0 else 1.0


## `pilot_color` transparente = cabina vacía (parado). `step`: 0 o 1 al caminar, -1 quieto.
## `armor_fraction` en [0, 1].
static func draw(canvas: CanvasItem, data: MechData, aim: Vector2, step: int, pilot_color: Color,
		gun_color: Color, gun_length: float, recoil: float, armor_fraction: float, time: float) -> void:
	var pose := Pose.new()
	pose.canvas = canvas
	pose.data = data
	pose.aim = aim if aim != Vector2.ZERO else Vector2.DOWN
	pose.step = step
	pose.pilot_color = pilot_color
	pose.gun_color = gun_color
	pose.gun_length = gun_length
	pose.recoil = recoil
	pose.time = time
	canvas.draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.0, 0.4))
	canvas.draw_circle(Vector2.ZERO, _shadow_radius(data), Color(0, 0, 0, 0.35))
	canvas.draw_set_transform(Vector2.ZERO)
	match data.frame:
		MechData.Frame.HEAVY:
			_draw_heavy(pose)
		MechData.Frame.WALKER:
			_draw_walker(pose)
		_:
			_draw_standard(pose)
	if armor_fraction < SMOKE_BELOW:
		var top: Vector2 = beacon(data, not pose.piloted())
		for i: int in 2:
			var rise: float = fmod(time * 1.5 + i * 0.5, 1.0)
			var at := (top + Vector2(-2 + i * 3, -1 - rise * 6.0)).round()
			canvas.draw_rect(Rect2(at, Vector2(2, 2)), Color(SMOKE_COLOR, SMOKE_COLOR.a * (1.0 - rise)))


## Lo más alto del armazón (la luz que titila parado y de donde sale el humo).
static func beacon(data: MechData, parked: bool) -> Vector2:
	match data.frame:
		MechData.Frame.HEAVY:
			return Vector2(-5, -22)
		MechData.Frame.WALKER:
			return Vector2(7, -21 + (CROUCH if parked else 0.0))
		_:
			return Vector2(0, -21)


static func _shadow_radius(data: MechData) -> float:
	match data.frame:
		MechData.Frame.HEAVY:
			return 12.0
		MechData.Frame.WALKER:
			return 8.0
		_:
			return 9.5


## Pesado: patas cortas, hombreras, chimeneas con vapor y la cabina-visera en el pecho.
static func _draw_heavy(p: Pose) -> void:
	var c: CanvasItem = p.canvas
	var body: Color = p.data.body_color
	var dark: Color = body.darkened(0.35)
	var accent: Color = p.data.accent_color
	# Chimeneas detrás de la espalda (echan vapor mientras anda).
	var stacks: Array[float] = [-6.0, 3.0]
	for k: int in stacks.size():
		var x: float = stacks[k]
		_box(c, Rect2(x, -19 + k, 3, 7 - k), dark.darkened(0.2))
		_box(c, Rect2(x - 1, -20 + k, 5, 2), dark)
		if p.piloted():
			for i: int in 2:
				var rise: float = fmod(p.time * 1.1 + i * 0.5 + k * 0.27, 1.0)
				var at := Vector2(x + 0.5, -23 + k - rise * 7.0).round()
				c.draw_rect(Rect2(at, Vector2(2, 2)), Color(STEAM_COLOR, STEAM_COLOR.a * (1.0 - rise)))
	for side: int in [-1, 1]:
		var lift: float = p.lift(side, 1.0)
		var leg_x: float = -8.0 if side < 0 else 3.0
		_box(c, Rect2(leg_x, -1 + lift, 5, 6), dark)
		c.draw_rect(Rect2(leg_x + 1, 1 + lift, 3, 1), body)
		_box(c, Rect2(leg_x - 2 if side < 0 else leg_x, 5 + lift, 7, 2), dark.darkened(0.25))
	_box(c, Rect2(-6, -3, 12, 3), dark.darkened(0.15))
	var pivot := Vector2(7.0 * p.aim_side(), -11)
	var gun_behind: bool = p.aim.y < -0.3
	if gun_behind:
		_gun(p, pivot, 6.0)
	_box(c, Rect2(-9, -15, 18, 12), body)
	c.draw_rect(Rect2(-9, -15, 18, 1), body.lightened(0.2))
	c.draw_rect(Rect2(-9, -6, 18, 3), dark)
	c.draw_rect(Rect2(-8, -14, 1, 1), body.lightened(0.35))
	c.draw_rect(Rect2(7, -14, 1, 1), body.lightened(0.35))
	# La cabina es una visera en el pecho: se ven los ojos del piloto.
	var visor := Rect2(-4, -12, 8, 3)
	if p.piloted():
		_box(c, visor, p.pilot_color)
		var look: float = clampf(roundf(p.aim.x * 1.5), -1.0, 1.0)
		c.draw_rect(Rect2(-2 + look, -11, 1, 1), OUTLINE_COLOR)
		c.draw_rect(Rect2(1 + look, -11, 1, 1), OUTLINE_COLOR)
	else:
		_box(c, visor, GLASS_COLOR)
		c.draw_rect(Rect2(-3, -12, 2, 1), GLASS_SHINE_COLOR)
	# La boca de la caldera: tres barras que brillan con el fuego de adentro.
	c.draw_rect(Rect2(-3, -8, 6, 2), OUTLINE_COLOR)
	var flicker: float = 0.65 + 0.35 * sin(p.time * 9.0)
	var glow: Color = Color(accent, flicker) if p.piloted() else accent.darkened(0.55)
	for i: int in 3:
		c.draw_rect(Rect2(-3 + i * 2, -8, 1, 2), glow)
	for side: int in [-1, 1]:
		var pad := Rect2(-13 if side < 0 else 8, -16, 5, 7)
		_box(c, pad, body.darkened(0.1))
		c.draw_rect(Rect2(pad.position.x, -13, 5, 1), accent)
		c.draw_rect(Rect2(pad.position.x + 1, -16, 3, 1), body.lightened(0.15))
	if not gun_behind:
		_gun(p, pivot, 6.0)


## Zancudo: patas de ave, cápsula con el piloto a la vista, sensor, antena y ametralladora abajo.
static func _draw_walker(p: Pose) -> void:
	var c: CanvasItem = p.canvas
	var body: Color = p.data.body_color
	var dark: Color = body.darkened(0.35)
	var accent: Color = p.data.accent_color
	var crouch: float = 0.0 if p.piloted() else CROUCH
	var o := Vector2(0, crouch)
	for side: int in [-1, 1]:
		var lift: float = p.lift(side, 2.0)
		var hip := Vector2(side * 3, -6 + crouch)
		# La rodilla dobla para atrás y para afuera; agachado se abre más.
		var knee := Vector2(side * (7 + crouch), -2 + crouch * 0.7 + lift * 0.5)
		var ankle := Vector2(side * 4, 5 + lift)
		_limb(c, hip, knee, 3.0, dark)
		_limb(c, knee, ankle, 2.0, dark.darkened(0.15))
		c.draw_rect(Rect2(knee.round() - Vector2(1, 1), Vector2(2, 2)), body)
		# Pie de tres dedos.
		c.draw_rect(Rect2(ankle.x - 3, ankle.y + 1, 6, 2), OUTLINE_COLOR)
		c.draw_rect(Rect2(ankle.x - 2, ankle.y + 1, 4, 1), dark)
	var pivot := Vector2(0, -8) + o
	var gun_behind: bool = p.aim.y < -0.3
	if gun_behind:
		_gun(p, pivot, 3.0)
	# Respaldo del asiento y el piloto, que asoma por arriba de la cápsula.
	_box(c, Rect2(Vector2(-4, -20) + o, Vector2(8, 5)), dark)
	if p.piloted():
		var head := Vector2(0, -16) + o
		c.draw_circle(head, 4.0, OUTLINE_COLOR)
		c.draw_circle(head, 3.0, p.pilot_color)
		var look: Vector2 = p.aim.round()
		c.draw_rect(Rect2(head + Vector2(-2, -2) + look, Vector2(1, 2)), OUTLINE_COLOR)
		c.draw_rect(Rect2(head + Vector2(1, -2) + look, Vector2(1, 2)), OUTLINE_COLOR)
	_box(c, Rect2(Vector2(-7, -13) + o, Vector2(14, 7)), body)
	c.draw_rect(Rect2(Vector2(-7, -13) + o, Vector2(14, 1)), body.lightened(0.25))
	c.draw_rect(Rect2(Vector2(-7, -8) + o, Vector2(14, 2)), dark)
	c.draw_rect(Rect2(Vector2(-6, -11) + o, Vector2(1, 2)), dark)
	c.draw_rect(Rect2(Vector2(5, -11) + o, Vector2(1, 2)), dark)
	# El ojo-sensor de adelante: prendido mientras lo manejan.
	c.draw_rect(Rect2(Vector2(-1, -11) + o, Vector2(2, 2)), OUTLINE_COLOR)
	c.draw_rect(Rect2(Vector2(-1, -11) + o, Vector2(1, 1)), accent if p.piloted() else accent.darkened(0.6))
	c.draw_line(Vector2(5, -13) + o, Vector2(7, -20) + o, OUTLINE_COLOR, 1.0)
	c.draw_rect(Rect2(Vector2(7, -21) + o, Vector2(1, 1)), accent)
	if not gun_behind:
		_gun(p, pivot, 3.0)


## Humanoide: fuelle en la espalda, cabina redonda, un brazo colgando y el otro es el arma.
static func _draw_standard(p: Pose) -> void:
	var c: CanvasItem = p.canvas
	var body: Color = p.data.body_color
	var dark: Color = body.darkened(0.35)
	var accent: Color = p.data.accent_color
	# El fuelle respira mientras lo manejan (y se infla al disparar).
	var breath: float = 0.0
	if p.piloted():
		breath = roundf(0.5 + 0.5 * sin(p.time * 3.0) + p.recoil * 0.4)
	var top: float = -18.0 - breath
	_box(c, Rect2(-6, top, 12, -13.0 - top), dark)
	for row: int in int(-13.0 - top):
		if row % 2 == 1:
			c.draw_rect(Rect2(-6, top + row, 12, 1), dark.lightened(0.2))
	for side: int in [-1, 1]:
		var lift: float = p.lift(side, 1.0)
		var leg_x: float = -6.0 if side < 0 else 2.0
		_box(c, Rect2(leg_x, -1 + lift, 4, 6), dark)
		c.draw_rect(Rect2(leg_x, 1 + lift, 4, 1), body.lightened(0.15))
		_box(c, Rect2(leg_x - 1, 5 + lift, 6, 2), dark.darkened(0.25))
	_box(c, Rect2(-5, -3, 10, 3), dark.darkened(0.15))
	var side_x: float = p.aim_side()
	var pivot := Vector2(7.0 * side_x, -9)
	var gun_behind: bool = p.aim.y < -0.3
	if gun_behind:
		_gun(p, pivot, 4.0)
		_pilot_flame(p, pivot)
	# El brazo libre cuelga del otro lado.
	_box(c, Rect2(-side_x * 9.0 - 1.5, -11, 3, 7), dark)
	_box(c, Rect2(-side_x * 9.0 - 2.0, -4, 4, 2), dark.darkened(0.2))
	_box(c, Rect2(-7, -14, 14, 11), body)
	c.draw_rect(Rect2(-7, -14, 14, 1), body.lightened(0.2))
	c.draw_rect(Rect2(-7, -6, 14, 3), dark)
	c.draw_rect(Rect2(-7, -5, 14, 1), accent)
	for side: int in [-1, 1]:
		c.draw_circle(Vector2(side * 8, -12), 4.0, OUTLINE_COLOR)
		c.draw_circle(Vector2(side * 8, -12), 3.0, body.darkened(0.1))
	var cockpit := Vector2(0, -9)
	c.draw_circle(cockpit, 4.0, OUTLINE_COLOR)
	if p.piloted():
		c.draw_circle(cockpit, 3.0, p.pilot_color)
		var look: Vector2 = p.aim.round()
		c.draw_rect(Rect2(cockpit + Vector2(-2, -1) + look, Vector2(1, 2)), OUTLINE_COLOR)
		c.draw_rect(Rect2(cockpit + Vector2(1, -1) + look, Vector2(1, 2)), OUTLINE_COLOR)
	else:
		c.draw_circle(cockpit, 3.0, GLASS_COLOR)
		c.draw_rect(Rect2(cockpit + Vector2(-2, -2), Vector2(1, 1)), GLASS_SHINE_COLOR)
	if not gun_behind:
		_gun(p, pivot, 4.0)
		_pilot_flame(p, pivot)


## La llamita piloto en la punta del arma (solo si lo manejan).
static func _pilot_flame(p: Pose, pivot: Vector2) -> void:
	if not p.piloted():
		return
	var tip: Vector2 = pivot + p.aim * (3.0 - p.recoil + p.gun_length + 1.0)
	p.canvas.draw_circle(tip.round(), 1.0 + float(int(p.time * 12.0) % 2), p.data.accent_color)


## El arma: un caño de `thickness` px de grueso que sale de `pivot` hacia la mira.
static func _gun(p: Pose, pivot: Vector2, thickness: float) -> void:
	var c: CanvasItem = p.canvas
	c.draw_set_transform(pivot, p.aim.angle())
	var start: float = 3.0 - p.recoil
	var half: float = thickness * 0.5
	c.draw_rect(Rect2(start - 1.0, -half - 1.0, p.gun_length + 2.0, thickness + 2.0), OUTLINE_COLOR)
	c.draw_rect(Rect2(start, -half, p.gun_length, thickness), p.gun_color)
	c.draw_rect(Rect2(start, -half, p.gun_length, 1.0), p.gun_color.lightened(0.25))
	c.draw_rect(Rect2(start, -half, 2.0, thickness), p.gun_color.darkened(0.3))
	c.draw_rect(Rect2(start + p.gun_length - 1.0, -half, 1.0, thickness), p.gun_color.darkened(0.45))
	c.draw_set_transform(Vector2.ZERO)


## Un rectángulo con borde oscuro de 1 px.
static func _box(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(rect.grow(1.0), OUTLINE_COLOR)
	canvas.draw_rect(rect, color)


## Un tramo de pata (línea gruesa con borde).
static func _limb(canvas: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	canvas.draw_line(from, to, OUTLINE_COLOR, width + 2.0)
	canvas.draw_line(from, to, color, width)
