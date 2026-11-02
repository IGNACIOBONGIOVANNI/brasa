@tool
class_name EnemyVisual
extends Node2D
## Placeholder de enemigo dibujado por código. El estilo sale de EnemyData.visual_style:
## HORNED (cuernos, embiste), EYE (un ojo grande que sigue al jugador), LANTERN (rombo con núcleo),
## SPORE (bola con manchas que late), BLOCK (bloque con ojos que brillan al atacar), SLIME (babosa que
## se estira al saltar), BAT (murciélago que aletea), FUSE (bomba con mecha encendida), NEST (montículo
## con agujeros), MOLE (topo; bajo tierra es un montículo que se mueve), WISP (llama de hollín),
## SHIELD (con escudo frontal), MORTAR (mortero) y los del monte: YARN (ovillo con la hebra suelta),
## SHEARS (tijera que corta sola), BURR (abrojo con púas), MOTH (polilla), BOULDER (piedra con
## grietas), CROW (cuervo), WOLF (lobo), ICE (témpano), CLOUD (nubarrón), GALE (cara de viento que
## sopla), DETHRONED (el Rey sin corona y con un cuerno roto) y AVALANCHE (montaña de nieve con
## carámbanos).
## Muestra la aparición, el aplastamiento al recibir un golpe y un "!" durante el telegraph.
## Se reemplaza por un sprite animado manteniendo la misma interfaz.

const ALERT_COLOR: Color = Color("ffd166")
const OUTLINE_COLOR: Color = Color("1b1420")
const HORN_COLOR: Color = Color("e8dcc0")
const EYE_WHITE: Color = Color("f2efe6")
const HIT_SQUASH_TIME: float = 0.12
const HOP_TIME: float = 0.3
const DIRT_COLOR: Color = Color("6b4a32")
const SHIELD_COLOR: Color = Color("9aa3b0")
const FUSE_SPARK_COLOR: Color = Color("ffd166")
const BLADE_COLOR: Color = Color("dfe6ef")
const ICE_LIGHT: Color = Color("e6f6ff")
const WOLF_EYE: Color = Color("ffd166")
const SNOW_COLOR: Color = Color("eef4fa")
## Los que flotan: sombra chica y lejos, y se bambolean.
const FLYING_STYLES: Array[EnemyData.VisualStyle] = [EnemyData.VisualStyle.BAT, EnemyData.VisualStyle.WISP,
		EnemyData.VisualStyle.MOTH, EnemyData.VisualStyle.CROW, EnemyData.VisualStyle.CLOUD, EnemyData.VisualStyle.GALE]
## Centro del cuerpo respecto del origen (que está en los pies).
const BODY_OFFSET: Vector2 = Vector2(0, -2)

@export var style: EnemyData.VisualStyle = EnemyData.VisualStyle.HORNED:
	set(value):
		style = value
		queue_redraw()
@export var radius: float = 7.0:
	set(value):
		radius = value
		queue_redraw()
@export var body_color: Color = Color("c4553f"):
	set(value):
		body_color = value
		queue_redraw()

var look_direction: Vector2 = Vector2.DOWN
var _alert: bool = false
var _charging: bool = false
var _squash_left: float = 0.0
var _spawn_duration: float = 0.0
var _spawn_left: float = 0.0
var _time: float = 0.0
var _hop_left: float = 0.0
var _burrowed: bool = false
var _guarding: bool = false
## Altura en el aire (un jefe que salta): el cuerpo sube y la sombra se achica en el piso.
var _lift: float = 0.0


func configure(data: EnemyData) -> void:
	style = data.visual_style
	radius = data.visual_radius
	body_color = data.body_color


func set_look(direction: Vector2) -> void:
	look_direction = direction


func set_alert(alert: bool) -> void:
	_alert = alert


func set_charging(charging: bool) -> void:
	_charging = charging


func play_hit() -> void:
	_squash_left = HIT_SQUASH_TIME


## Se estira al salir y se aplasta al caer (HOP).
func play_hop() -> void:
	_hop_left = HOP_TIME


## Bajo tierra se dibuja un montículo en vez del cuerpo (BURROW).
func set_burrowed(burrowed: bool) -> void:
	_burrowed = burrowed


## El escudo levantado (SHIELD); al atacar lo baja.
func set_guarding(guarding: bool) -> void:
	_guarding = guarding


## Cuántos px está en el aire (0 = en el piso). La sombra queda donde está el nodo y marca dónde cae.
func set_lift(height: float) -> void:
	_lift = maxf(0.0, height)


## Crece desde chiquito durante `duration` segundos.
func play_spawn(duration: float) -> void:
	_spawn_duration = duration
	_spawn_left = duration


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_squash_left = maxf(0.0, _squash_left - delta)
	_spawn_left = maxf(0.0, _spawn_left - delta)
	_hop_left = maxf(0.0, _hop_left - delta)
	queue_redraw()


func _draw() -> void:
	var appear: float = 1.0
	if _spawn_duration > 0.0:
		appear = 1.0 - _spawn_left / _spawn_duration
	if _burrowed:
		_draw_mound()
		return
	# Sombra (los que vuelan la tienen más chica y más lejos).
	var flying: bool = FLYING_STYLES.has(style)
	if _lift > 0.0:
		# En el aire: la sombra se agranda y se oscurece a medida que baja, con un aro que avisa.
		var near: float = clampf(1.0 - _lift / 140.0, 0.25, 1.0)
		draw_set_transform(Vector2(0, radius * 0.6), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, radius * 1.1 * near, Color(0, 0, 0, 0.25 + 0.3 * near))
		draw_arc(Vector2.ZERO, radius * 1.4, 0.0, TAU, 24, Color(ALERT_COLOR, 0.35 + 0.3 * sin(_time * 20.0)), 1.0)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_set_transform(Vector2(0, radius * (1.1 if flying else 0.6)), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, radius * (0.6 if flying else 0.9) * appear, Color(0, 0, 0, 0.35))
	# Cuerpo: aplastado al recibir un golpe, inclinado hacia adelante al embestir, estirado al saltar.
	var squash: float = _squash_left / HIT_SQUASH_TIME
	var body_scale := Vector2(1.0 + 0.25 * squash, 1.0 - 0.2 * squash) * lerpf(0.3, 1.0, appear)
	var lean: Vector2 = look_direction * 1.5 if _charging else Vector2.ZERO
	var lift := Vector2.ZERO
	if _hop_left > 0.0:
		var hop: float = 1.0 - _hop_left / HOP_TIME
		lift = Vector2(0, -roundf(sin(hop * PI) * radius * 0.8))
		body_scale *= Vector2(1.0 - 0.15 * sin(hop * PI), 1.0 + 0.2 * sin(hop * PI))
	if flying:
		lift = Vector2(0, roundf(-3.0 + sin(_time * 5.0)))
	if _lift > 0.0:
		lift = Vector2(0, -roundf(_lift))
	draw_set_transform(BODY_OFFSET + lean + lift, 0.0, body_scale)
	match style:
		EnemyData.VisualStyle.HORNED:
			_draw_horned()
		EnemyData.VisualStyle.EYE:
			_draw_eye()
		EnemyData.VisualStyle.LANTERN:
			_draw_lantern()
		EnemyData.VisualStyle.SPORE:
			_draw_spore()
		EnemyData.VisualStyle.BLOCK:
			_draw_block()
		EnemyData.VisualStyle.SLIME:
			_draw_slime()
		EnemyData.VisualStyle.BAT:
			_draw_bat()
		EnemyData.VisualStyle.FUSE:
			_draw_fuse()
		EnemyData.VisualStyle.NEST:
			_draw_nest()
		EnemyData.VisualStyle.MOLE:
			_draw_mole()
		EnemyData.VisualStyle.WISP:
			_draw_wisp()
		EnemyData.VisualStyle.SHIELD:
			_draw_shield()
		EnemyData.VisualStyle.MORTAR:
			_draw_mortar()
		EnemyData.VisualStyle.YARN:
			_draw_yarn()
		EnemyData.VisualStyle.SHEARS:
			_draw_shears()
		EnemyData.VisualStyle.BURR:
			_draw_burr()
		EnemyData.VisualStyle.MOTH:
			_draw_moth()
		EnemyData.VisualStyle.BOULDER:
			_draw_boulder()
		EnemyData.VisualStyle.CROW:
			_draw_crow()
		EnemyData.VisualStyle.WOLF:
			_draw_wolf()
		EnemyData.VisualStyle.ICE:
			_draw_ice()
		EnemyData.VisualStyle.CLOUD:
			_draw_cloud()
		EnemyData.VisualStyle.GALE:
			_draw_gale()
		EnemyData.VisualStyle.DETHRONED:
			_draw_dethroned()
		EnemyData.VisualStyle.AVALANCHE:
			_draw_avalanche()
	draw_set_transform(Vector2.ZERO)
	if _alert:
		var origin := Vector2(0, BODY_OFFSET.y - radius - 7.0 - roundf(_lift))
		PixelBitmap.paint_outlined(self, PixelIcons.ALERT, origin, ALERT_COLOR, OUTLINE_COLOR)


func _draw_horned() -> void:
	for side: float in [-1.0, 1.0]:
		var horn := PackedVector2Array([
			Vector2(side * radius * 0.35, -radius * 0.7),
			Vector2(side * radius * 1.05, -radius * 1.3),
			Vector2(side * radius * 0.8, -radius * 0.3),
		])
		draw_colored_polygon(horn, HORN_COLOR)
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius - 1.0, body_color)
	var look: Vector2 = (look_direction * 2.0).round()
	draw_rect(Rect2(Vector2(-4, -1) + look, Vector2(2, 1)), OUTLINE_COLOR)
	draw_rect(Rect2(Vector2(2, -1) + look, Vector2(2, 1)), OUTLINE_COLOR)


func _draw_eye() -> void:
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius - 1.0, body_color)
	var eye_center: Vector2 = (look_direction * 1.0).round()
	draw_circle(eye_center, radius * 0.55, EYE_WHITE)
	draw_circle(eye_center + (look_direction * radius * 0.25).round(), radius * 0.25, OUTLINE_COLOR)


func _draw_lantern() -> void:
	var outer: float = radius
	draw_colored_polygon(_diamond(outer + 1.0), OUTLINE_COLOR)
	draw_colored_polygon(_diamond(outer), body_color)
	var glow: float = 0.5 + 0.5 * sin(_time * 4.0)
	draw_circle(Vector2.ZERO, radius * 0.45, body_color.lightened(0.3 + 0.3 * glow))
	draw_circle(Vector2.ZERO, radius * 0.2, Color.WHITE)


func _draw_spore() -> void:
	var size: float = radius * (1.0 + 0.06 * sin(_time * 3.0))
	draw_circle(Vector2.ZERO, size, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, size - 1.0, body_color)
	var spot_color: Color = body_color.darkened(0.35)
	for spot: Vector2 in [Vector2(-0.45, -0.4), Vector2(0.4, -0.15), Vector2(-0.1, 0.45)]:
		draw_circle((spot * radius).round(), maxf(1.0, radius * 0.18), spot_color)
	var look: Vector2 = (look_direction * 1.5).round()
	draw_rect(Rect2(Vector2(-2, -1) + look, Vector2(1, 2)), OUTLINE_COLOR)
	draw_rect(Rect2(Vector2(1, -1) + look, Vector2(1, 2)), OUTLINE_COLOR)


func _draw_block() -> void:
	var half: float = roundf(radius * 0.9)
	draw_rect(Rect2(-half - 1.0, -half - 1.0, half * 2.0 + 2.0, half * 2.0 + 2.0), OUTLINE_COLOR)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), body_color)
	draw_rect(Rect2(-half, roundf(half * 0.4), half * 2.0, roundf(half * 0.6)), body_color.darkened(0.3))
	var eye_color: Color = ALERT_COLOR if _alert or _charging else body_color.lightened(0.55)
	var eye_width: float = maxf(2.0, roundf(radius * 0.35))
	var look: Vector2 = (look_direction * 1.5).round()
	draw_rect(Rect2(Vector2(-eye_width - 1.0, -2.0) + look, Vector2(eye_width, 1.0)), eye_color)
	draw_rect(Rect2(Vector2(1.0, -2.0) + look, Vector2(eye_width, 1.0)), eye_color)


## Babosa: media gota que tiembla, con brillo y dos ojos.
func _draw_slime() -> void:
	var wobble: float = 1.0 + 0.06 * sin(_time * 6.0)
	var width: float = radius * wobble
	var height: float = radius * (2.0 - wobble)
	var blob := _ellipse(Vector2(0, radius * 0.25), width + 1.0, height + 1.0, true)
	draw_colored_polygon(blob, OUTLINE_COLOR)
	draw_colored_polygon(_ellipse(Vector2(0, radius * 0.25), width, height, true), body_color)
	draw_rect(Rect2(roundf(-width * 0.5), roundf(-height * 0.45), 2, 1), body_color.lightened(0.5))
	var look: Vector2 = (look_direction * 1.5).round()
	draw_rect(Rect2(Vector2(-3, -1) + look, Vector2(1, 2)), OUTLINE_COLOR)
	draw_rect(Rect2(Vector2(2, -1) + look, Vector2(1, 2)), OUTLINE_COLOR)


## Murciélago: cuerpito con orejas y dos alas que aletean; los ojos se prenden al avisar.
func _draw_bat() -> void:
	var flap: float = sin(_time * 22.0)
	for side: float in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			Vector2(side * radius * 0.4, -radius * 0.2),
			Vector2(side * radius * 1.6, -radius * (0.5 + 0.6 * flap)),
			Vector2(side * radius * 1.3, radius * 0.3),
			Vector2(side * radius * 0.4, radius * 0.4),
		])
		draw_colored_polygon(wing, body_color.darkened(0.35))
		var ear := PackedVector2Array([Vector2(side * radius * 0.2, -radius * 0.5), Vector2(side * radius * 0.55, -radius * 1.05), Vector2(side * radius * 0.6, -radius * 0.35)])
		draw_colored_polygon(ear, body_color)
	draw_circle(Vector2.ZERO, radius * 0.65 + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius * 0.65, body_color)
	var eye_color: Color = ALERT_COLOR if _alert else Color("ff4d6d")
	draw_rect(Rect2(-2, -1, 1, 1), eye_color)
	draw_rect(Rect2(1, -1, 1, 1), eye_color)


## Mecha: bomba redonda con una mecha arriba que chisporrotea; al avisar se pone roja.
func _draw_fuse() -> void:
	var shell: Color = Color("e0464e") if _alert and int(_time * 16.0) % 2 == 0 else body_color
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius - 1.0, shell)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.35), 1.0, shell.lightened(0.5))
	var tip := Vector2(radius * 0.45, -radius * 1.25)
	draw_line(Vector2(radius * 0.2, -radius * 0.85), tip, Color("c9b28a"), 1.0)
	var spark: float = 1.0 + float(int(_time * 20.0) % 2)
	draw_circle(tip, spark, FUSE_SPARK_COLOR)
	var look: Vector2 = (look_direction * 1.5).round()
	draw_rect(Rect2(Vector2(-3, 0) + look, Vector2(2, 1)), OUTLINE_COLOR)
	draw_rect(Rect2(Vector2(1, 0) + look, Vector2(2, 1)), OUTLINE_COLOR)


## Nido: montículo de tres bultos con agujeros oscuros que late.
func _draw_nest() -> void:
	var pulse: float = 1.0 + 0.05 * sin(_time * 3.0)
	var lumps: Array[Vector3] = [Vector3(-0.45, 0.2, 0.65), Vector3(0.45, 0.25, 0.6), Vector3(0.0, -0.25, 0.75)]
	for lump: Vector3 in lumps:
		draw_circle(Vector2(lump.x, lump.y) * radius, lump.z * radius * pulse + 1.0, OUTLINE_COLOR)
	for lump: Vector3 in lumps:
		draw_circle(Vector2(lump.x, lump.y) * radius, lump.z * radius * pulse, body_color)
	for hole: Vector2 in [Vector2(-0.45, 0.25), Vector2(0.4, 0.3), Vector2(0.0, -0.3)]:
		draw_circle((hole * radius).round(), maxf(1.0, radius * 0.16), OUTLINE_COLOR)


## Topo afuera: cabeza con hocico rosado y dos garras.
func _draw_mole() -> void:
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius - 1.0, body_color)
	var look: Vector2 = (look_direction * 2.0).round()
	draw_circle(Vector2(0, 1) + look, 2.0, Color("e8a0a0"))
	draw_rect(Rect2(Vector2(-3, -2) + look, Vector2(1, 1)), OUTLINE_COLOR)
	draw_rect(Rect2(Vector2(2, -2) + look, Vector2(1, 1)), OUTLINE_COLOR)
	for side: float in [-1.0, 1.0]:
		draw_rect(Rect2(side * radius * 0.85 - 1.0, radius * 0.4, 2.0, 2.0), HORN_COLOR)


## Bajo tierra: un montículo de tierra con piedritas (BURROW); tiembla al avisar.
func _draw_mound() -> void:
	var shake: Vector2 = Vector2(roundf(sin(_time * 50.0)), 0) if _alert else Vector2.ZERO
	draw_set_transform(Vector2(0, 1) + shake, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, radius + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius, DIRT_COLOR)
	draw_set_transform(Vector2.ZERO)
	for pebble: Vector2 in [Vector2(-3, 0), Vector2(2, -1), Vector2(0, 2)]:
		draw_rect(Rect2(pebble + shake, Vector2.ONE), DIRT_COLOR.lightened(0.35))
	if _alert:
		var origin := Vector2(0, -radius - 7.0)
		PixelBitmap.paint_outlined(self, PixelIcons.ALERT, origin, ALERT_COLOR, OUTLINE_COLOR)


## Hollín: una llama oscura que ondula, con ojos claros.
func _draw_wisp() -> void:
	var sway: float = sin(_time * 5.0) * radius * 0.25
	var flame := PackedVector2Array([
		Vector2(-radius, radius * 0.3), Vector2(-radius * 0.6, -radius * 0.5),
		Vector2(sway * 0.5, -radius * 1.6), Vector2(radius * 0.6, -radius * 0.5),
		Vector2(radius, radius * 0.3), Vector2(radius * 0.4, radius * 0.9 + sway * 0.3),
		Vector2(-radius * 0.4, radius * 0.9 - sway * 0.3),
	])
	draw_colored_polygon(flame, body_color)
	draw_circle(Vector2(0, radius * 0.1), radius * 0.75, body_color.lightened(0.15))
	var look: Vector2 = (look_direction * 1.5).round()
	draw_rect(Rect2(Vector2(-3, -1) + look, Vector2(2, 2)), EYE_WHITE)
	draw_rect(Rect2(Vector2(1, -1) + look, Vector2(2, 2)), EYE_WHITE)


## Escudero: cuerpo cuadrado y, adelante, el escudo (más chico y de costado cuando ataca).
func _draw_shield() -> void:
	var half: float = roundf(radius * 0.8)
	draw_rect(Rect2(-half - 1.0, -half - 1.0, half * 2.0 + 2.0, half * 2.0 + 2.0), OUTLINE_COLOR)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), body_color)
	var look: Vector2 = (look_direction * 1.5).round()
	draw_rect(Rect2(Vector2(-3, -2) + look, Vector2(2, 1)), OUTLINE_COLOR)
	draw_rect(Rect2(Vector2(1, -2) + look, Vector2(2, 1)), OUTLINE_COLOR)
	var reach: float = radius * (1.15 if _guarding else 0.6)
	draw_set_transform(BODY_OFFSET + look_direction * reach, look_direction.angle(), Vector2.ONE)
	var plate := Rect2(-1.5, -radius * (0.95 if _guarding else 0.5), 3.0, radius * (1.9 if _guarding else 1.0))
	draw_rect(plate.grow(1.0), OUTLINE_COLOR)
	draw_rect(plate, SHIELD_COLOR)
	draw_rect(Rect2(plate.position.x, plate.position.y, 1.0, plate.size.y), SHIELD_COLOR.lightened(0.4))


## Fogonero: mortero achatado con la boca encendida apuntando arriba.
func _draw_mortar() -> void:
	draw_rect(Rect2(-radius - 1.0, -radius * 0.2 - 1.0, radius * 2.0 + 2.0, radius * 1.1 + 2.0), OUTLINE_COLOR)
	draw_rect(Rect2(-radius, -radius * 0.2, radius * 2.0, radius * 1.1), body_color)
	var tilt: float = clampf(look_direction.x, -0.6, 0.6)
	var mouth := Vector2(tilt * radius * 0.6, -radius * 1.1)
	draw_line(Vector2(0, -radius * 0.1), mouth, OUTLINE_COLOR, 5.0)
	draw_line(Vector2(0, -radius * 0.1), mouth, body_color.darkened(0.25), 3.0)
	var glow: float = 0.6 + 0.4 * sin(_time * 6.0)
	draw_circle(mouth, 1.5, Color(FUSE_SPARK_COLOR, glow) if not _alert else ALERT_COLOR)
	var look: Vector2 = (look_direction * 1.0).round()
	draw_rect(Rect2(Vector2(-3, 1) + look, Vector2(2, 1)), FUSE_SPARK_COLOR)
	draw_rect(Rect2(Vector2(1, 1) + look, Vector2(2, 1)), FUSE_SPARK_COLOR)


## Elipse (o su mitad de arriba con el piso plano).
func _ellipse(center: Vector2, half_width: float, half_height: float, flat_bottom: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps: int = 16
	for i: int in steps + 1:
		var angle: float = PI + PI * i / steps if flat_bottom else TAU * i / steps
		points.append(center + Vector2(cos(angle) * half_width, sin(angle) * half_height))
	return points


func _diamond(size: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -size), Vector2(size, 0), Vector2(0, size), Vector2(-size, 0)])


## Dos ojos chicos que miran hacia `look_direction` (en `center`, separados `gap`).
func _eyes(center: Vector2, gap: float, color: Color) -> void:
	var look: Vector2 = (look_direction * 1.5).round()
	draw_rect(Rect2((center + Vector2(-gap - 1.0, -1.0) + look).round(), Vector2(1, 2)), color)
	draw_rect(Rect2((center + Vector2(gap, -1.0) + look).round(), Vector2(1, 2)), color)


## Ovillo: bola con vueltas de hebra que giran al rodar y una punta suelta atrás.
func _draw_yarn() -> void:
	var spin: float = _time * 6.0
	var tail: Vector2 = -look_direction * radius
	draw_line(tail, tail * 1.6 + look_direction.orthogonal() * sin(_time * 9.0) * 2.0, body_color.darkened(0.2), 1.0)
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius - 1.0, body_color)
	for i: int in 3:
		var angle: float = spin + PI * i / 3.0
		var axis: Vector2 = Vector2.from_angle(angle) * (radius - 2.0)
		draw_line(-axis, axis, body_color.darkened(0.3), 1.0)
	draw_arc(Vector2.ZERO, radius * 0.55, spin, spin + PI, 8, body_color.lightened(0.3), 1.0)
	_eyes(Vector2(0, -1), 2.0, OUTLINE_COLOR)


## Tijera: dos hojas que se abren y se cierran (más abiertas al avisar) y los ojos en el eje.
func _draw_shears() -> void:
	var open: float = 0.7 if _alert else 0.25 + 0.2 * absf(sin(_time * 5.0))
	var forward: Vector2 = look_direction
	for side: float in [-1.0, 1.0]:
		var blade: Vector2 = forward.rotated(side * open) * radius * 1.4
		var handle: Vector2 = -forward.rotated(-side * 0.6) * radius * 0.8
		draw_line(handle, blade, OUTLINE_COLOR, 3.0)
		draw_line(Vector2.ZERO, blade, BLADE_COLOR, 1.0)
		draw_arc(handle, radius * 0.35, 0.0, TAU, 10, OUTLINE_COLOR, 2.0)
		draw_arc(handle, radius * 0.35, 0.0, TAU, 10, body_color, 1.0)
	draw_circle(Vector2.ZERO, radius * 0.45 + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius * 0.45, body_color)
	_eyes(Vector2.ZERO, 1.0, ALERT_COLOR if _alert else EYE_WHITE)


## Abrojo: semilla redonda con púas alrededor y ojitos enojados.
func _draw_burr() -> void:
	var spikes: int = 10
	for i: int in spikes:
		var direction := Vector2.from_angle(TAU * i / spikes + _time * 0.5)
		var spike := PackedVector2Array([
			direction.rotated(0.25) * radius * 0.8, direction * radius * 1.35, direction.rotated(-0.25) * radius * 0.8])
		draw_colored_polygon(spike, body_color.darkened(0.35))
	draw_circle(Vector2.ZERO, radius * 0.9, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius * 0.9 - 1.0, body_color)
	_eyes(Vector2(0, -1), 2.0, ALERT_COLOR if _alert else OUTLINE_COLOR)


## Polilla: cuerpo alargado con dos alas grandes y redondas que aletean, con manchas.
func _draw_moth() -> void:
	var flap: float = 0.6 + 0.4 * sin(_time * 16.0)
	for side: float in [-1.0, 1.0]:
		var center := Vector2(side * radius * 0.9 * flap, -radius * 0.1)
		draw_colored_polygon(_ellipse(center, radius * 0.75 * flap + 1.0, radius * 0.75 + 1.0, false), OUTLINE_COLOR)
		draw_colored_polygon(_ellipse(center, radius * 0.75 * flap, radius * 0.75, false), body_color)
		draw_circle(center + Vector2(0, -1), radius * 0.25 * flap, body_color.darkened(0.35))
	draw_colored_polygon(_ellipse(Vector2.ZERO, radius * 0.3 + 1.0, radius * 0.8 + 1.0, false), OUTLINE_COLOR)
	draw_colored_polygon(_ellipse(Vector2.ZERO, radius * 0.3, radius * 0.8, false), body_color.darkened(0.2))
	draw_rect(Rect2(-1, -2, 1, 1), ALERT_COLOR if _alert else EYE_WHITE)
	draw_rect(Rect2(1, -2, 1, 1), ALERT_COLOR if _alert else EYE_WHITE)


## Pedrusco: piedra de bordes irregulares, con grietas y cejas enojadas.
func _draw_boulder() -> void:
	var points := PackedVector2Array()
	var bumps: Array[float] = [1.0, 0.86, 0.97, 0.9, 1.0, 0.84, 0.95, 0.88]
	for i: int in bumps.size():
		points.append(Vector2.from_angle(TAU * i / bumps.size() + 0.2) * radius * bumps[i])
	var outline := PackedVector2Array()
	for point: Vector2 in points:
		outline.append(point * (1.0 + 1.0 / radius))
	draw_colored_polygon(outline, OUTLINE_COLOR)
	draw_colored_polygon(points, body_color)
	draw_line(Vector2(-radius * 0.5, radius * 0.2), Vector2(-radius * 0.1, radius * 0.5), body_color.darkened(0.4), 1.0)
	draw_line(Vector2(radius * 0.3, -radius * 0.6), Vector2(radius * 0.55, -radius * 0.2), body_color.darkened(0.4), 1.0)
	var eye_color: Color = ALERT_COLOR if _alert or _charging else OUTLINE_COLOR
	_eyes(Vector2(0, -1), 2.0, eye_color)
	draw_line(Vector2(-4, -4), Vector2(-1, -3), OUTLINE_COLOR, 1.0)
	draw_line(Vector2(4, -4), Vector2(1, -3), OUTLINE_COLOR, 1.0)


## Cuervo: cuerpo negro con pico hacia donde mira y dos alas que aletean.
func _draw_crow() -> void:
	var flap: float = sin(_time * 18.0)
	for side: float in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			Vector2(side * radius * 0.3, -radius * 0.1),
			Vector2(side * radius * 1.5, -radius * (0.2 + 0.7 * flap)),
			Vector2(side * radius * 0.9, radius * 0.4),
		])
		draw_colored_polygon(wing, body_color.darkened(0.25))
	draw_circle(Vector2.ZERO, radius * 0.7 + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius * 0.7, body_color)
	var beak_base: Vector2 = look_direction * radius * 0.55
	var beak := PackedVector2Array([beak_base + look_direction.orthogonal() * 1.5, beak_base + look_direction * 4.0,
			beak_base - look_direction.orthogonal() * 1.5])
	draw_colored_polygon(beak, Color("e0a83a"))
	_eyes(Vector2(0, -1), 1.0, ALERT_COLOR if _alert else Color("ff4d6d"))


## Lobo: lomo gris, orejas de punta, hocico hacia donde mira y ojos amarillos.
func _draw_wolf() -> void:
	var side: Vector2 = look_direction.orthogonal()
	var tail: Vector2 = -look_direction * radius * 1.1
	draw_line(tail * 0.6, tail + side * sin(_time * 8.0) * 2.0, body_color.darkened(0.2), 2.0)
	for sign_x: float in [-1.0, 1.0]:
		var ear := PackedVector2Array([Vector2(sign_x * radius * 0.25, -radius * 0.6), Vector2(sign_x * radius * 0.7, -radius * 1.3),
				Vector2(sign_x * radius * 0.75, -radius * 0.45)])
		draw_colored_polygon(ear, OUTLINE_COLOR)
	draw_colored_polygon(_ellipse(Vector2.ZERO, radius + 1.0, radius * 0.8 + 1.0, false), OUTLINE_COLOR)
	draw_colored_polygon(_ellipse(Vector2.ZERO, radius, radius * 0.8, false), body_color)
	var snout: Vector2 = (look_direction * radius * 0.7).round()
	draw_circle(snout, radius * 0.35, body_color.lightened(0.25))
	draw_rect(Rect2(snout + Vector2(-0.5, -0.5), Vector2(1, 1)), OUTLINE_COLOR)
	_eyes(Vector2(0, -2), 2.0, ALERT_COLOR if _alert or _charging else WOLF_EYE)


## Témpano: bloque de hielo de seis caras con brillos y un ojo adentro.
func _draw_ice() -> void:
	var points := PackedVector2Array()
	for i: int in 6:
		points.append(Vector2.from_angle(TAU * i / 6.0 + PI / 6.0) * radius)
	var outline := PackedVector2Array()
	for point: Vector2 in points:
		outline.append(point * (1.0 + 1.0 / radius))
	draw_colored_polygon(outline, OUTLINE_COLOR)
	draw_colored_polygon(points, body_color)
	draw_colored_polygon(PackedVector2Array([points[3], points[4], Vector2.ZERO]), body_color.lightened(0.3))
	draw_line(points[4] * 0.7, Vector2(-1, -1), ICE_LIGHT, 1.0)
	var pupil: Vector2 = (look_direction * 1.5).round()
	draw_circle(Vector2.ZERO, radius * 0.3, EYE_WHITE)
	draw_rect(Rect2(pupil + Vector2(-0.5, -0.5), Vector2(1, 1)), ALERT_COLOR if _alert else OUTLINE_COLOR)


## Nubarrón: bollos grises con ojos; al avisar titila un rayito abajo.
func _draw_cloud() -> void:
	var puffs: Array[Vector2] = [Vector2(-0.6, 0.1), Vector2(0.6, 0.1), Vector2(-0.2, -0.35), Vector2(0.3, -0.3), Vector2(0, 0.2)]
	for puff: Vector2 in puffs:
		draw_circle(puff * radius, radius * 0.55 + 1.0, OUTLINE_COLOR)
	for puff: Vector2 in puffs:
		draw_circle(puff * radius, radius * 0.55, body_color)
	draw_circle(Vector2(-0.2, -0.45) * radius, radius * 0.25, body_color.lightened(0.25))
	if _alert and int(_time * 14.0) % 2 == 0:
		draw_polyline(PackedVector2Array([Vector2(0, radius * 0.6), Vector2(-2, radius * 1.0), Vector2(1, radius * 1.1),
				Vector2(-1, radius * 1.5)]), ALERT_COLOR, 1.0)
	_eyes(Vector2(0, 0), 2.0, OUTLINE_COLOR)


## Viento con cara: un remolino con los cachetes inflados, la boca en "o" hacia donde sopla y rayitas que
## salen al avisar.
func _draw_gale() -> void:
	var spin: float = _time * 4.0
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius - 1.0, body_color)
	for i: int in 3:
		var start: float = spin + TAU * i / 3.0
		draw_arc(Vector2.ZERO, radius * (0.55 + 0.15 * i), start, start + PI * 0.7, 10, body_color.lightened(0.3), 1.0)
	var side: Vector2 = look_direction.orthogonal()
	var mouth: Vector2 = (look_direction * radius * 0.45 + Vector2(0, radius * 0.15)).round()
	for sign_x: float in [-1.0, 1.0]:
		draw_circle((mouth + side * sign_x * radius * 0.4 - look_direction * radius * 0.1).round(), radius * 0.24,
				body_color.lightened(0.35))
	draw_circle(mouth, maxf(1.5, radius * 0.18), OUTLINE_COLOR)
	draw_circle(mouth, maxf(0.5, radius * 0.08), body_color.darkened(0.5))
	var eye_size: float = maxf(1.0, roundf(radius * 0.14))
	for sign_x: float in [-1.0, 1.0]:
		var eye: Vector2 = (Vector2(sign_x * radius * 0.35, -radius * 0.3) + look_direction).round()
		draw_circle(eye, eye_size + 0.5, EYE_WHITE)
		draw_circle(eye + look_direction.round(), maxf(0.5, eye_size * 0.6), ALERT_COLOR if _alert else OUTLINE_COLOR)
	if _alert or _charging:
		for k: int in 3:
			var lane: Vector2 = side * (k - 1) * 2.0
			var reach: float = radius * (1.2 + 0.4 * fmod(_time * 3.0 + k * 0.3, 1.0))
			draw_line(mouth + lane, mouth + lane + look_direction * reach * 0.5, Color(EYE_WHITE, 0.8), 1.0)


## El Rey Destronado: el carnero grande sin corona, con un cuerno partido y una cicatriz.
func _draw_dethroned() -> void:
	var whole := PackedVector2Array([Vector2(-radius * 0.35, -radius * 0.7), Vector2(-radius * 1.05, -radius * 1.3),
			Vector2(-radius * 0.8, -radius * 0.3)])
	draw_colored_polygon(whole, HORN_COLOR)
	var broken := PackedVector2Array([Vector2(radius * 0.35, -radius * 0.7), Vector2(radius * 0.7, -radius * 0.95),
			Vector2(radius * 0.8, -radius * 0.3)])
	draw_colored_polygon(broken, HORN_COLOR.darkened(0.2))
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, radius - 1.0, body_color)
	# Clavos sueltos donde estaba la corona.
	for x: float in [-0.3, 0.05, 0.35]:
		draw_rect(Rect2(Vector2(x * radius, -radius + 1.0).round(), Vector2(1, 3)), Color("8a8f99"))
	draw_line(Vector2(radius * 0.15, -radius * 0.45), Vector2(radius * 0.55, radius * 0.1), body_color.darkened(0.45), 1.0)
	var eye_color: Color = ALERT_COLOR if _alert or _charging else Color("ff4d6d")
	var look: Vector2 = (look_direction * 2.0).round()
	draw_rect(Rect2(Vector2(-5, -2) + look, Vector2(3, 2)), eye_color)
	draw_rect(Rect2(Vector2(2, -2) + look, Vector2(3, 2)), eye_color)


## Alud: una montaña de nieve con dientes de carámbano y dos ojos hundidos.
func _draw_avalanche() -> void:
	var mound := _ellipse(Vector2(0, radius * 0.2), radius * 1.1, radius, true)
	var outline := _ellipse(Vector2(0, radius * 0.2), radius * 1.1 + 1.0, radius + 1.0, true)
	draw_colored_polygon(outline, OUTLINE_COLOR)
	draw_colored_polygon(mound, SNOW_COLOR)
	draw_colored_polygon(_ellipse(Vector2(radius * 0.25, radius * 0.45), radius * 0.7, radius * 0.45, true), body_color)
	for i: int in 5:
		var x: float = (i - 2) * radius * 0.3
		var tooth := PackedVector2Array([Vector2(x - 2, radius * 0.25), Vector2(x + 2, radius * 0.25), Vector2(x, radius * 0.6)])
		draw_colored_polygon(tooth, ICE_LIGHT)
	var look: Vector2 = (look_direction * 2.0).round()
	var eye_color: Color = ALERT_COLOR if _alert else Color("2a4a7a")
	draw_rect(Rect2(Vector2(-6, -4) + look, Vector2(3, 3)), eye_color)
	draw_rect(Rect2(Vector2(3, -4) + look, Vector2(3, 3)), eye_color)
