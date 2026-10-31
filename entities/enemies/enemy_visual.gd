@tool
class_name EnemyVisual
extends Node2D
## Placeholder de enemigo dibujado por código. El estilo sale de EnemyData.visual_style:
## HORNED (cuernos, embiste), EYE (un ojo grande que sigue al jugador), LANTERN (rombo con núcleo),
## SPORE (bola con manchas que late), BLOCK (bloque con ojos que brillan al atacar), SLIME (babosa que
## se estira al saltar), BAT (murciélago que aletea), FUSE (bomba con mecha encendida), NEST (montículo
## con agujeros), MOLE (topo; bajo tierra es un montículo que se mueve), WISP (llama de hollín),
## SHIELD (con escudo frontal) y MORTAR (mortero).
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
	var flying: bool = style == EnemyData.VisualStyle.BAT or style == EnemyData.VisualStyle.WISP
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
	draw_set_transform(Vector2.ZERO)
	if _alert:
		var origin := Vector2(0, BODY_OFFSET.y - radius - 7.0)
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
