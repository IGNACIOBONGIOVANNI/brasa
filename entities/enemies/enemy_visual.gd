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
## carámbanos) y GHOST (sábana de poltergeist que flota, con los ojos huecos). Los minijefes: VETERAN
## (carnero viejo y musculoso, con cuernos enroscados y cicatrices), SPIKED_SLIME (babosa erizada de
## pinchos), TREE (un pehuén que camina, con piñas) y ANVIL (bigornia al rojo), con las armas que
## vuelan solas (SWORD, AXE que gira y KNIFE), y FORGE_HEART (el Yunque sin coraza: un cuerpo de fuego).
## Los jefes con dibujo propio: BELL (la campana rajada con ojos y el badajo que se mece), RAM_KING (el
## Rey Carnero con capa, cuello de lana y corona de clavos), ROOT_HEART (un bulbo de raíces que se
## retuercen, con un ojo y un corazón que late), ANVIL_KNIGHT (el Yunque con coraza: cabeza de yunque,
## hombreras y la llama encerrada en el pecho), GIANT_SHEARS (las tijeras de esquilar enormes, con lana
## enganchada y un ojo en el tornillo) y STORM (el Cierzo: un espectro de tormenta encapuchado).
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
const STEEL_COLOR: Color = Color("cfd8e3")
const GRIP_COLOR: Color = Color("6b4a32")
const GOLD_COLOR: Color = Color("e2b84a")
const FOLIAGE_COLOR: Color = Color("2f6b3a")
const CONE_COLOR: Color = Color("9a6234")
const HOT_COLOR: Color = Color("ff8a3d")
const FIRE_CORE: Color = Color("fff1a8")
const PLATE_COLOR: Color = Color("6e7889")
const CAPE_COLOR: Color = Color("5a1424")
const WOOL_COLOR: Color = Color("e9e1cf")
const IRON_COLOR: Color = Color("3a3640")
const PINE_COLOR: Color = Color("2c5248")
## Los que flotan: sombra chica y lejos, y se bambolean.
const FLYING_STYLES: Array[EnemyData.VisualStyle] = [EnemyData.VisualStyle.BAT, EnemyData.VisualStyle.WISP,
		EnemyData.VisualStyle.MOTH, EnemyData.VisualStyle.CROW, EnemyData.VisualStyle.CLOUD, EnemyData.VisualStyle.GALE,
		EnemyData.VisualStyle.GHOST, EnemyData.VisualStyle.SWORD, EnemyData.VisualStyle.AXE,
		EnemyData.VisualStyle.KNIFE]
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
## La entrada de un jefe (BossIntro) lo agranda o lo achica desde los pies (crece de la tierra, de la
## nieve) y lo corre un poco. Fuera de la entrada quedan en (1, 1) y (0, 0).
var intro_scale: Vector2 = Vector2.ONE
var intro_offset: Vector2 = Vector2.ZERO
## Dónde y de qué tamaño se dibuja el cuerpo en este cuadro (los dibujos que cambian la transformación
## la arman desde acá, así respetan el salto, la altura y la entrada).
var _body_origin: Vector2 = Vector2.ZERO
var _body_scale: Vector2 = Vector2.ONE


func configure(data: EnemyData) -> void:
	style = data.visual_style
	radius = data.visual_radius
	body_color = data.body_color


## Otro dibujo desde ahora (un jefe al que se le rompe la coraza).
func change_look(new_style: EnemyData.VisualStyle, new_color: Color) -> void:
	style = new_style
	body_color = new_color


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
	# La entrada crece desde los pies: el centro baja lo que se achica.
	var rise := Vector2(0, radius * (1.0 - intro_scale.y))
	_body_origin = BODY_OFFSET + lean + lift + intro_offset + rise
	_body_scale = body_scale * intro_scale
	draw_set_transform(_body_origin, 0.0, _body_scale)
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
		EnemyData.VisualStyle.GHOST:
			_draw_ghost()
		EnemyData.VisualStyle.VETERAN:
			_draw_veteran()
		EnemyData.VisualStyle.SPIKED_SLIME:
			_draw_spiked_slime()
		EnemyData.VisualStyle.TREE:
			_draw_tree()
		EnemyData.VisualStyle.ANVIL:
			_draw_anvil()
		EnemyData.VisualStyle.SWORD:
			_draw_sword()
		EnemyData.VisualStyle.AXE:
			_draw_axe()
		EnemyData.VisualStyle.KNIFE:
			_draw_knife()
		EnemyData.VisualStyle.FORGE_HEART:
			_draw_forge_heart()
		EnemyData.VisualStyle.BELL:
			_draw_bell()
		EnemyData.VisualStyle.RAM_KING:
			_draw_ram_king()
		EnemyData.VisualStyle.ROOT_HEART:
			_draw_root_heart()
		EnemyData.VisualStyle.ANVIL_KNIGHT:
			_draw_anvil_knight()
		EnemyData.VisualStyle.GIANT_SHEARS:
			_draw_giant_shears()
		EnemyData.VisualStyle.STORM:
			_draw_storm()
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


## El Rey Destronado: el Rey Carnero que volvió de la cantera: la capa hecha jirones, el cuello de lana
## sucio, un cuerno partido, cicatrices, los clavos de la corona que perdió todavía clavados en la frente
## y dos ojos que arden.
func _draw_dethroned() -> void:
	var r: float = radius
	var cape := PackedVector2Array([Vector2(-r * 0.7, -r * 0.1), Vector2(r * 0.7, -r * 0.1), Vector2(r * 1.1, r * 0.75),
			Vector2(r * 0.8, r * 1.0), Vector2(r * 0.55, r * 0.7), Vector2(r * 0.25, r * 1.05), Vector2(-r * 0.1, r * 0.75),
			Vector2(-r * 0.45, r * 1.0), Vector2(-r * 0.7, r * 0.7), Vector2(-r * 1.1, r * 0.9)])
	_outlined_polygon(cape, CAPE_COLOR.darkened(0.35))
	for x: float in [-0.75, -0.35, 0.05, 0.45, 0.8]:
		draw_circle(Vector2(x * r, r * 0.45), r * 0.26, WOOL_COLOR.darkened(0.35))
	var whole := Vector2(-r * 0.8, -r * 0.45)
	draw_arc(whole, r * 0.45, PI * 1.5, PI * 0.1, 14, OUTLINE_COLOR, 6.0)
	draw_arc(whole, r * 0.45, PI * 1.5, PI * 0.1, 14, HORN_COLOR.darkened(0.15), 4.0)
	var stump := PackedVector2Array([Vector2(r * 0.4, -r * 0.65), Vector2(r * 0.85, -r * 0.95), Vector2(r * 0.95, -r * 0.7),
			Vector2(r * 0.7, -r * 0.35)])
	_outlined_polygon(stump, HORN_COLOR.darkened(0.3))
	draw_line(Vector2(r * 0.85, -r * 0.95), Vector2(r * 0.95, -r * 0.7), OUTLINE_COLOR, 1.0)
	draw_circle(Vector2(0, -r * 0.05), r * 0.75 + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2(0, -r * 0.05), r * 0.75, body_color)
	# Los clavos de la corona, todavía clavados.
	for k: int in 4:
		var x: float = -r * 0.35 + k * r * 0.22
		var tilt: float = (k % 2) * 2.0 - 1.0
		draw_line(Vector2(x, -r * 0.62), Vector2(x + tilt, -r * 0.95), Color("8a8f99"), 1.0)
	draw_line(Vector2(r * 0.15, -r * 0.5), Vector2(r * 0.55, r * 0.15), body_color.darkened(0.45), 1.0)
	draw_line(Vector2(-r * 0.55, -r * 0.1), Vector2(-r * 0.25, r * 0.3), body_color.darkened(0.45), 1.0)
	var eye_color: Color = ALERT_COLOR if _alert or _charging else Color("ff4d6d")
	var look: Vector2 = (look_direction * 2.0).round()
	draw_rect(Rect2(Vector2(-r * 0.42, -r * 0.22) + look, Vector2(3, 2)), eye_color)
	draw_rect(Rect2(Vector2(r * 0.42 - 3.0, -r * 0.22) + look, Vector2(3, 2)), eye_color)
	draw_rect(Rect2(Vector2(-r * 0.42 - 1.0, -r * 0.22 - 1.0) + look, Vector2(5, 4)), Color(eye_color, 0.25))
	draw_rect(Rect2(Vector2(r * 0.42 - 4.0, -r * 0.22 - 1.0) + look, Vector2(5, 4)), Color(eye_color, 0.25))
	var muzzle: Vector2 = Vector2(0, r * 0.3) + look * 0.5
	draw_circle(muzzle, r * 0.28, body_color.lightened(0.15))
	draw_rect(Rect2(muzzle + Vector2(-2, -1), Vector2(1, 1)), OUTLINE_COLOR)
	draw_rect(Rect2(muzzle + Vector2(1, -1), Vector2(1, 1)), OUTLINE_COLOR)


## Alud: una montaña viva: picos nevados con roca que asoma, un pino torcido en el lomo, dos brazos de
## nieve, una boca de carámbanos y ojos hundidos que se prenden de azul (amarillo al avisar).
func _draw_avalanche() -> void:
	var r: float = radius
	var rock := Color("5a5f6e")
	for side: float in [-1.0, 1.0]:
		var arm := Vector2(side * r * 1.05, r * 0.45)
		draw_circle(arm, r * 0.38 + 1.0, OUTLINE_COLOR)
		draw_circle(arm, r * 0.38, SNOW_COLOR.darkened(0.08))
	var peaks := PackedVector2Array([Vector2(-r * 1.05, r * 0.8), Vector2(-r * 0.95, -r * 0.1), Vector2(-r * 0.55, -r * 0.75),
			Vector2(-r * 0.2, -r * 0.4), Vector2(r * 0.15, -r * 1.05), Vector2(r * 0.55, -r * 0.45), Vector2(r * 0.95, -r * 0.2),
			Vector2(r * 1.05, r * 0.8)])
	_outlined_polygon(peaks, rock)
	var snow := PackedVector2Array([Vector2(-r * 0.95, r * 0.2), Vector2(-r * 0.95, -r * 0.1), Vector2(-r * 0.55, -r * 0.75),
			Vector2(-r * 0.2, -r * 0.4), Vector2(r * 0.15, -r * 1.05), Vector2(r * 0.55, -r * 0.45), Vector2(r * 0.95, -r * 0.2),
			Vector2(r * 0.95, r * 0.25), Vector2(r * 0.5, r * 0.05), Vector2(r * 0.1, r * 0.2), Vector2(-r * 0.4, 0.0)])
	draw_colored_polygon(snow, SNOW_COLOR)
	draw_line(Vector2(r * 0.15, -r * 1.0), Vector2(r * 0.4, -r * 0.5), ICE_LIGHT.darkened(0.15), 1.0)
	# Un pino torcido en el lomo.
	var pine := Vector2(-r * 0.55, -r * 0.75)
	draw_line(pine, pine + Vector2(-1, -5), Color("4a3428"), 1.0)
	draw_colored_polygon(PackedVector2Array([pine + Vector2(-4, -3), pine + Vector2(2, -3), pine + Vector2(-1, -9)]), PINE_COLOR)
	draw_rect(Rect2(pine + Vector2(-3, -6), Vector2(3, 1)), SNOW_COLOR)
	var mouth_y: float = r * 0.42
	draw_rect(Rect2(-r * 0.6, mouth_y - 2.0, r * 1.2, 4), Color("1b2433"))
	for i: int in 6:
		var x: float = -r * 0.5 + i * r * 0.2
		draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, mouth_y - 2.0), Vector2(x + 1.5, mouth_y - 2.0),
				Vector2(x, mouth_y + 2.0 + (i % 2) * 2.0)]), ICE_LIGHT)
	var look: Vector2 = (look_direction * 2.0).round()
	var eye_color: Color = ALERT_COLOR if _alert else Color("7fd4ff")
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(side * r * 0.35, -r * 0.05) + look
		draw_rect(Rect2(eye - Vector2(2, 2), Vector2(4, 3)), Color("1b2433"))
		draw_rect(Rect2(eye - Vector2(1, 1), Vector2(2, 1)), eye_color)


## Poltergeist: una sábana que flota, con el ruedo ondulado y dos ojos huecos que brillan al avisar.
func _draw_ghost() -> void:
	var sheet := PackedVector2Array()
	sheet.append(Vector2(-radius, radius * 0.1))
	for k: int in 13:
		var angle: float = PI + PI * k / 12.0
		sheet.append(Vector2(cos(angle), sin(angle)) * radius + Vector2(0, radius * 0.1))
	var waves: int = 4
	for k: int in waves * 2 + 1:
		var x: float = radius - radius * 2.0 * k / (waves * 2)
		var wave: float = sin(_time * 6.0 + k) * 1.0 + (2.0 if k % 2 == 0 else 0.0)
		sheet.append(Vector2(x, radius * 0.9 + wave))
	var outline := PackedVector2Array()
	for point: Vector2 in sheet:
		outline.append(point * (1.0 + 1.0 / radius))
	draw_colored_polygon(outline, OUTLINE_COLOR)
	draw_colored_polygon(sheet, body_color)
	draw_line(Vector2(-radius * 0.6, -radius * 0.5), Vector2(-radius * 0.2, -radius * 0.8), body_color.lightened(0.3), 1.0)
	var eye_color: Color = ALERT_COLOR if _alert else OUTLINE_COLOR
	var look: Vector2 = (look_direction * 1.5).round()
	for side: float in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.35, -radius * 0.15) + look, maxf(1.2, radius * 0.18), eye_color)
	draw_circle(Vector2(0, radius * 0.3) + look, maxf(1.0, radius * 0.12), OUTLINE_COLOR)


## Carnero veterano: hombros de músculo, cuernos gruesos enroscados, mechón de lana, ceño fruncido,
## una cicatriz y la argolla en la nariz.
func _draw_veteran() -> void:
	var r: float = radius
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector2(side * r * 0.95, r * 0.3)
		draw_circle(shoulder, r * 0.55 + 1.0, OUTLINE_COLOR)
		draw_circle(shoulder, r * 0.55, body_color.darkened(0.15))
		draw_arc(shoulder, r * 0.35, PI * 1.1, PI * 1.6, 6, body_color.lightened(0.15), 1.0)
	for side: float in [-1.0, 1.0]:
		var curl := Vector2(side * r * 0.85, -r * 0.45)
		var from: float = PI * 1.5
		var to: float = from + side * PI * 1.4
		draw_arc(curl, r * 0.42, from, to, 12, OUTLINE_COLOR, 5.0)
		draw_arc(curl, r * 0.42, from, to, 12, HORN_COLOR, 3.0)
		draw_arc(curl, r * 0.42, from, from + side * PI * 0.5, 6, HORN_COLOR.lightened(0.3), 1.0)
	draw_circle(Vector2.ZERO, r, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, r - 1.0, body_color)
	for x: float in [-0.3, 0.0, 0.3]:
		draw_circle(Vector2(x * r, -r * 0.8), r * 0.22, body_color.lightened(0.3))
	var look: Vector2 = (look_direction * 2.0).round()
	var eye_color: Color = ALERT_COLOR if _alert or _charging else Color("ff4d6d")
	draw_rect(Rect2(Vector2(-5, -2) + look, Vector2(3, 2)), eye_color)
	draw_rect(Rect2(Vector2(2, -2) + look, Vector2(3, 2)), eye_color)
	draw_line(Vector2(-6, -5) + look, Vector2(-2, -3) + look, OUTLINE_COLOR, 1.0)
	draw_line(Vector2(6, -5) + look, Vector2(2, -3) + look, OUTLINE_COLOR, 1.0)
	draw_line(Vector2(3, -6), Vector2(6, 1), body_color.darkened(0.45), 1.0)
	var muzzle: Vector2 = Vector2(0, r * 0.45) + look * 0.5
	draw_circle(muzzle, r * 0.35, body_color.lightened(0.2))
	draw_rect(Rect2(muzzle + Vector2(-2, -1), Vector2(1, 1)), OUTLINE_COLOR)
	draw_rect(Rect2(muzzle + Vector2(1, -1), Vector2(1, 1)), OUTLINE_COLOR)
	draw_arc(muzzle + Vector2(0, 1), 1.5, 0.0, PI, 6, GOLD_COLOR, 1.0)


## Babosa erizada: una gota grande con pinchos por arriba (se paran al avisar) y ojos enojados.
func _draw_spiked_slime() -> void:
	var wobble: float = 1.0 + 0.05 * sin(_time * 5.0)
	var width: float = radius * wobble
	var height: float = radius * (2.0 - wobble)
	var center := Vector2(0, radius * 0.25)
	var reach: float = 0.7 if _alert else 0.45
	var spikes: int = 9
	for i: int in spikes:
		var angle: float = PI + PI * (i + 0.5) / spikes
		var rim: Vector2 = center + Vector2(cos(angle) * width, sin(angle) * height)
		var direction: Vector2 = (rim - center).normalized()
		var base: Vector2 = center + (rim - center) * 0.85
		var tip: Vector2 = rim + direction * radius * reach
		var side: Vector2 = direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([base + side * 2.5, tip + direction, base - side * 2.5]), OUTLINE_COLOR)
		draw_colored_polygon(PackedVector2Array([base + side * 1.5, tip, base - side * 1.5]), HORN_COLOR)
	draw_colored_polygon(_ellipse(center, width + 1.0, height + 1.0, true), OUTLINE_COLOR)
	draw_colored_polygon(_ellipse(center, width, height, true), body_color)
	draw_colored_polygon(_ellipse(center, width * 0.7, height * 0.6, true), body_color.lightened(0.12))
	draw_rect(Rect2(roundf(-width * 0.55), roundf(-height * 0.4), 2, 1), body_color.lightened(0.5))
	var look: Vector2 = (look_direction * 2.0).round()
	var eye_color: Color = ALERT_COLOR if _alert else OUTLINE_COLOR
	draw_rect(Rect2(Vector2(-4, -1) + look, Vector2(2, 2)), eye_color)
	draw_rect(Rect2(Vector2(2, -1) + look, Vector2(2, 2)), eye_color)
	draw_line(Vector2(-5, -3) + look, Vector2(-2, -2) + look, OUTLINE_COLOR, 1.0)
	draw_line(Vector2(5, -3) + look, Vector2(2, -2) + look, OUTLINE_COLOR, 1.0)


## Pehuén: tronco con cara, raíces, dos ramas-brazo y una copa en pisos de ramas con púas, con piñas
## colgando (titilan al avisar).
func _draw_tree() -> void:
	var r: float = radius
	var sway: float = sin(_time * 1.5)
	for side: float in [-1.0, 1.0]:
		draw_line(Vector2(side * r * 0.25, r * 0.85), Vector2(side * r * 0.7, r * 1.05), OUTLINE_COLOR, 3.0)
		draw_line(Vector2(side * r * 0.25, r * 0.85), Vector2(side * r * 0.7, r * 1.05), body_color.darkened(0.2), 1.0)
		var hand := Vector2(side * r * 1.25, -r * 0.15 + sway * side)
		draw_line(Vector2(side * r * 0.3, r * 0.1), hand, OUTLINE_COLOR, 4.0)
		draw_line(Vector2(side * r * 0.3, r * 0.1), hand, body_color, 2.0)
		for k: int in 3:
			var needle: Vector2 = hand + Vector2(side * (k - 1) * 1.5, -2.0 - k)
			draw_line(hand, needle, FOLIAGE_COLOR.lightened(0.15), 1.0)
	var trunk := Rect2(-r * 0.4, -r * 0.4, r * 0.8, r * 1.3)
	draw_rect(trunk.grow(1.0), OUTLINE_COLOR)
	draw_rect(trunk, body_color)
	for x: float in [-0.2, 0.15]:
		draw_line(Vector2(x * r, -r * 0.3), Vector2(x * r, r * 0.8), body_color.darkened(0.3), 1.0)
	var eye_color: Color = ALERT_COLOR if _alert else Color("ffb35c")
	var look: Vector2 = (look_direction * 1.0).round()
	draw_rect(Rect2(Vector2(-3, 0) + look, Vector2(2, 1)), eye_color)
	draw_rect(Rect2(Vector2(1, 0) + look, Vector2(2, 1)), eye_color)
	draw_line(Vector2(-2, 4) + look, Vector2(2, 3) + look, OUTLINE_COLOR, 1.0)
	var tiers: Array[Vector3] = [Vector3(-0.55, 1.15, 0.32), Vector3(-0.95, 0.9, 0.28), Vector3(-1.3, 0.6, 0.24)]
	for tier: Vector3 in tiers:
		var y: float = tier.x * r
		var half: float = tier.y * r
		var thick: float = tier.z * r
		var outline := PackedVector2Array([Vector2(-half - 1.0, y + thick * 0.5 + 1.0), Vector2(-half * 0.6, y - thick * 0.6 - 1.0),
				Vector2(half * 0.6, y - thick * 0.6 - 1.0), Vector2(half + 1.0, y + thick * 0.5 + 1.0)])
		var shape := PackedVector2Array([Vector2(-half, y + thick * 0.5), Vector2(-half * 0.6, y - thick * 0.6),
				Vector2(half * 0.6, y - thick * 0.6), Vector2(half, y + thick * 0.5)])
		draw_colored_polygon(outline, OUTLINE_COLOR)
		draw_colored_polygon(shape, FOLIAGE_COLOR)
		for k: int in 5:
			var x: float = -half + half * 2.0 * (k + 0.5) / 5.0
			draw_line(Vector2(x, y + thick * 0.5), Vector2(x + 1.0, y + thick * 0.5 + 2.0), FOLIAGE_COLOR.darkened(0.3), 1.0)
		draw_line(Vector2(-half * 0.55, y - thick * 0.45), Vector2(half * 0.3, y - thick * 0.45), FOLIAGE_COLOR.lightened(0.2), 1.0)
	var glow: float = 0.35 if _alert and int(_time * 10.0) % 2 == 0 else 0.0
	for cone: Vector2 in [Vector2(-0.6, -0.4), Vector2(0.55, -0.45), Vector2(0.0, -0.8)]:
		var at: Vector2 = (cone * r).round()
		draw_rect(Rect2(at + Vector2(-2, -2), Vector2(4, 5)), OUTLINE_COLOR)
		draw_rect(Rect2(at + Vector2(-1, -1), Vector2(2, 3)), CONE_COLOR.lightened(glow))


## Bigornia: un yunque chico con el pico a un costado, la cara de arriba al rojo y ojos en la cintura;
## al avisar la parte caliente se aviva y saltan chispas.
func _draw_anvil() -> void:
	var r: float = radius
	var base := Rect2(-r * 0.75, r * 0.35, r * 1.5, r * 0.55)
	var waist := Rect2(-r * 0.4, -r * 0.15, r * 0.8, r * 0.55)
	var top := Rect2(-r * 0.85, -r * 0.6, r * 1.45, r * 0.5)
	var horn := PackedVector2Array([Vector2(r * 0.6, -r * 0.6), Vector2(r * 1.25, -r * 0.45), Vector2(r * 0.6, -r * 0.15)])
	var horn_outline := PackedVector2Array([Vector2(r * 0.6, -r * 0.6 - 1.0), Vector2(r * 1.25 + 1.5, -r * 0.45),
			Vector2(r * 0.6, -r * 0.15 + 1.0)])
	draw_colored_polygon(horn_outline, OUTLINE_COLOR)
	for part: Rect2 in [base, waist, top]:
		draw_rect(part.grow(1.0), OUTLINE_COLOR)
	draw_colored_polygon(horn, body_color)
	draw_rect(base, body_color.darkened(0.2))
	draw_rect(waist, body_color.darkened(0.1))
	draw_rect(top, body_color)
	var heat: float = 1.0 if _alert else 0.6 + 0.4 * sin(_time * 4.0)
	draw_rect(Rect2(-r * 0.55, -r * 0.6, r * 0.9, 2.0), Color(HOT_COLOR, heat))
	draw_rect(Rect2(-r * 0.4, -r * 0.6, r * 0.5, 1.0), Color(FIRE_CORE, heat))
	draw_line(Vector2(-r * 0.8, -r * 0.2), Vector2(r * 0.5, -r * 0.2), body_color.lightened(0.25), 1.0)
	var look: Vector2 = (look_direction * 1.0).round()
	var eye_color: Color = ALERT_COLOR if _alert else HOT_COLOR
	draw_rect(Rect2(Vector2(-3, 0) + look, Vector2(2, 1)), eye_color)
	draw_rect(Rect2(Vector2(1, 0) + look, Vector2(2, 1)), eye_color)
	if _alert:
		for i: int in 3:
			var rise: float = fmod(_time * 2.5 + i * 0.33, 1.0)
			var at := Vector2((i - 1) * r * 0.35, -r * 0.65 - rise * r * 0.7).round()
			draw_rect(Rect2(at, Vector2.ONE), Color(FIRE_CORE, 1.0 - rise))


## Espada que vuela sola: apunta hacia donde va, con guarda dorada y pomo.
func _draw_sword() -> void:
	_draw_blade_weapon(look_direction, radius * 1.5, radius * 0.75, 1.5, GOLD_COLOR)


## Cuchillo que vuela solo: corto y fino, de mango oscuro.
func _draw_knife() -> void:
	_draw_blade_weapon(look_direction, radius * 1.1, radius * 0.5, 1.0, GRIP_COLOR.darkened(0.3))


## Una hoja con mango hacia `forward`: la punta a `blade_length` del centro, el mango de `grip_length`
## para atrás y la guarda de `guard_color`.
func _draw_blade_weapon(forward: Vector2, blade_length: float, grip_length: float, half_width: float,
		guard_color: Color) -> void:
	var side: Vector2 = forward.orthogonal()
	var heel: Vector2 = -forward * grip_length * 0.2
	var tip: Vector2 = forward * blade_length
	var pommel: Vector2 = -forward * grip_length
	draw_line(heel, pommel, OUTLINE_COLOR, 4.0)
	draw_line(heel, pommel, GRIP_COLOR, 2.0)
	draw_circle(pommel, 1.5, guard_color)
	var outline := PackedVector2Array([heel + side * (half_width + 1.0) - forward, tip + forward * 1.5,
			heel - side * (half_width + 1.0) - forward])
	draw_colored_polygon(outline, OUTLINE_COLOR)
	draw_colored_polygon(PackedVector2Array([heel + side * half_width, tip, heel - side * half_width]),
			ALERT_COLOR.lightened(0.4) if _alert else STEEL_COLOR)
	draw_line(heel, tip * 0.85, Color.WHITE, 1.0)
	var guard: float = half_width + 2.5
	draw_line(heel + side * guard, heel - side * guard, OUTLINE_COLOR, 3.0)
	draw_line(heel + side * (guard - 0.5), heel - side * (guard - 0.5), guard_color, 1.0)


## Hacha que gira en el aire (más rápido al avisar y al lanzarse): mango y una hoja ancha en la punta.
func _draw_axe() -> void:
	var spin: float = _time * (18.0 if _alert or _charging else 9.0)
	var along := Vector2.from_angle(spin)
	var side: Vector2 = along.orthogonal()
	var r: float = radius
	draw_line(-along * r, along * r * 0.8, OUTLINE_COLOR, 4.0)
	draw_line(-along * r, along * r * 0.8, GRIP_COLOR, 2.0)
	var head := PackedVector2Array([along * r * 0.35 + side * r * 0.15, along * r * 0.2 + side * r * 1.0,
			along * r * 1.0 + side * r * 0.85, along * r * 0.9 + side * r * 0.05])
	var outline := PackedVector2Array()
	for point: Vector2 in head:
		outline.append(point * 1.15)
	draw_colored_polygon(outline, OUTLINE_COLOR)
	draw_colored_polygon(head, STEEL_COLOR)
	draw_line(along * r * 0.2 + side * r * 1.0, along * r * 1.0 + side * r * 0.85, Color.WHITE, 1.0)


## El Yunque sin coraza: un cuerpo de fuego en capas (el borde de su color, el medio más claro y el
## centro casi blanco) que titila, dos pedazos de coraza que le quedaron en los hombros y ojos blancos.
func _draw_forge_heart() -> void:
	var r: float = radius
	var sizes: Array[float] = [1.0, 0.72, 0.42]
	var colors: Array[Color] = [body_color.darkened(0.2), body_color.lightened(0.15), FIRE_CORE]
	for k: int in sizes.size():
		var size: float = r * sizes[k]
		var flame := PackedVector2Array()
		var tongues: int = 7
		for i: int in tongues * 2:
			var angle: float = PI + PI * float(i) / float(tongues * 2 - 1)
			var tall: float = 1.35 if i % 2 == 0 else 0.95
			var flick: float = 0.15 * sin(_time * 11.0 + i * 1.7 + k * 2.0)
			flame.append(Vector2(cos(angle) * size, sin(angle) * size * (tall + flick)))
		flame.append(Vector2(size * 0.85, size * 0.75))
		flame.append(Vector2(-size * 0.85, size * 0.75))
		if k == 0:
			var outline := PackedVector2Array()
			for point: Vector2 in flame:
				outline.append(point * (1.0 + 1.0 / r))
			draw_colored_polygon(outline, OUTLINE_COLOR)
		draw_colored_polygon(flame, colors[k])
	for side: float in [-1.0, 1.0]:
		var plate := Rect2(side * r * 0.95 - (r * 0.45 if side < 0.0 else 0.0), -r * 0.1, r * 0.45, r * 0.35)
		draw_rect(plate.grow(1.0), OUTLINE_COLOR)
		draw_rect(plate, PLATE_COLOR)
		draw_line(plate.position + Vector2(1, 1), plate.end - Vector2(1, 1), PLATE_COLOR.darkened(0.3), 1.0)
	var look: Vector2 = (look_direction * 1.5).round()
	var eye_color: Color = ALERT_COLOR if _alert else Color.WHITE
	draw_rect(Rect2(Vector2(-5, -4) + look, Vector2(3, 2)), eye_color)
	draw_rect(Rect2(Vector2(2, -4) + look, Vector2(3, 2)), eye_color)
	draw_line(Vector2(-3, 3) + look, Vector2(3, 3) + look, body_color.darkened(0.5), 1.0)


## Contorno de 1 px alrededor de un polígono (lo agranda desde el centro).
func _outlined_polygon(points: PackedVector2Array, color: Color) -> void:
	var outline := PackedVector2Array()
	for point: Vector2 in points:
		outline.append(point + point.normalized() * 1.2)
	draw_colored_polygon(outline, OUTLINE_COLOR)
	draw_colored_polygon(points, color)


## El Campanario: la campana caída, rajada, con dos ojos huecos y el badajo que se mece (más al avisar,
## y toda la campana vibra).
func _draw_bell() -> void:
	var r: float = radius
	var shake: float = roundf(sin(_time * 60.0)) if _alert else 0.0
	draw_set_transform(_body_origin + Vector2(shake, 0), 0.0, _body_scale)
	var swing: float = sin(_time * (9.0 if _alert else 2.5)) * (0.45 if _alert else 0.2)
	var clapper := Vector2(sin(swing) * r * 0.5, r * 0.95)
	draw_line(Vector2(0, r * 0.3), clapper, IRON_COLOR, 2.0)
	draw_circle(clapper, r * 0.2 + 1.0, OUTLINE_COLOR)
	draw_circle(clapper, r * 0.2, IRON_COLOR.lightened(0.15))
	var bell := PackedVector2Array([Vector2(-r * 0.35, -r * 1.05), Vector2(r * 0.35, -r * 1.05), Vector2(r * 0.55, -r * 0.6),
			Vector2(r * 0.62, r * 0.1), Vector2(r * 0.92, r * 0.55), Vector2(r, r * 0.72), Vector2(-r, r * 0.72),
			Vector2(-r * 0.92, r * 0.55), Vector2(-r * 0.62, r * 0.1), Vector2(-r * 0.55, -r * 0.6)])
	_outlined_polygon(bell, body_color)
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.3, -r * 0.95), Vector2(-r * 0.12, -r * 0.95),
			Vector2(-r * 0.4, r * 0.5), Vector2(-r * 0.62, r * 0.5)]), body_color.lightened(0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(r * 0.3, -r * 0.9), Vector2(r * 0.5, -r * 0.55),
			Vector2(r * 0.85, r * 0.5), Vector2(r * 0.55, r * 0.5)]), body_color.darkened(0.25))
	draw_rect(Rect2(-r, r * 0.5, r * 2.0, r * 0.22), body_color.darkened(0.35))
	draw_line(Vector2(-r, r * 0.5), Vector2(r, r * 0.5), body_color.lightened(0.2), 1.0)
	draw_arc(Vector2(0, -r * 1.15), r * 0.22, PI, TAU, 8, IRON_COLOR, 3.0)
	draw_polyline(PackedVector2Array([Vector2(r * 0.25, -r * 1.0), Vector2(r * 0.1, -r * 0.6), Vector2(r * 0.3, -r * 0.3),
			Vector2(r * 0.12, r * 0.05)]), OUTLINE_COLOR, 1.0)
	var eye_color: Color = ALERT_COLOR if _alert else Color("fff1c4")
	var look: Vector2 = (look_direction * 1.5).round()
	for side: float in [-1.0, 1.0]:
		var eye := PackedVector2Array([Vector2(side * r * 0.12, -r * 0.2), Vector2(side * r * 0.42, -r * 0.3),
				Vector2(side * r * 0.4, -r * 0.08)])
		var shifted := PackedVector2Array()
		for point: Vector2 in eye:
			shifted.append(point + look)
		draw_colored_polygon(shifted, OUTLINE_COLOR)
		draw_circle(Vector2(side * r * 0.32, -r * 0.18) + look, 1.0, eye_color)
	draw_set_transform(_body_origin, 0.0, _body_scale)


## El Rey Carnero: capa roja, cuello de lana, cuernos gruesos con punta dorada, corona de clavos y
## argolla.
func _draw_ram_king() -> void:
	var r: float = radius
	var cape := PackedVector2Array([Vector2(-r * 0.7, -r * 0.1), Vector2(r * 0.7, -r * 0.1), Vector2(r * 1.15, r * 1.0),
			Vector2(r * 0.4, r * 0.85), Vector2(0, r * 1.05), Vector2(-r * 0.4, r * 0.85), Vector2(-r * 1.15, r * 1.0)])
	_outlined_polygon(cape, CAPE_COLOR)
	for x: float in [-0.75, -0.4, 0.0, 0.4, 0.75]:
		draw_circle(Vector2(x * r, r * 0.45), r * 0.28, WOOL_COLOR.darkened(0.08))
	for side: float in [-1.0, 1.0]:
		var curl := Vector2(side * r * 0.8, -r * 0.45)
		var from: float = PI * 1.5
		draw_arc(curl, r * 0.45, from, from + side * PI * 1.5, 14, OUTLINE_COLOR, 6.0)
		draw_arc(curl, r * 0.45, from, from + side * PI * 1.5, 14, HORN_COLOR, 4.0)
		draw_arc(curl, r * 0.45, from + side * PI * 1.1, from + side * PI * 1.5, 6, GOLD_COLOR, 4.0)
	draw_circle(Vector2(0, -r * 0.05), r * 0.75 + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2(0, -r * 0.05), r * 0.75, body_color)
	# Corona de clavos.
	draw_rect(Rect2(-r * 0.5, -r * 0.85, r, 3), OUTLINE_COLOR)
	draw_rect(Rect2(-r * 0.5 + 1.0, -r * 0.85 + 1.0, r - 2.0, 1), GOLD_COLOR)
	for k: int in 5:
		var x: float = -r * 0.42 + k * r * 0.21
		draw_line(Vector2(x, -r * 0.85), Vector2(x, -r * 1.2 - (k % 2) * 2.0), Color("8a8f99"), 1.0)
	var eye_color: Color = ALERT_COLOR if _alert or _charging else Color("ff4d6d")
	var look: Vector2 = (look_direction * 2.0).round()
	draw_rect(Rect2(Vector2(-r * 0.4, -r * 0.2) + look, Vector2(3, 2)), eye_color)
	draw_rect(Rect2(Vector2(r * 0.4 - 3.0, -r * 0.2) + look, Vector2(3, 2)), eye_color)
	draw_line(Vector2(-r * 0.5, -r * 0.42) + look, Vector2(-r * 0.15, -r * 0.3) + look, OUTLINE_COLOR, 1.0)
	draw_line(Vector2(r * 0.5, -r * 0.42) + look, Vector2(r * 0.15, -r * 0.3) + look, OUTLINE_COLOR, 1.0)
	var muzzle: Vector2 = Vector2(0, r * 0.3) + look * 0.5
	draw_circle(muzzle, r * 0.28, body_color.lightened(0.2))
	draw_arc(muzzle + Vector2(0, 2), 2.0, 0.0, PI, 6, GOLD_COLOR, 1.0)


## El Raigón: raíces gruesas que se retuercen alrededor de un bulbo con un ojo de pupila fina y, abajo,
## un corazón que late (más rápido al avisar).
func _draw_root_heart() -> void:
	var r: float = radius
	var tendrils: int = 7
	for i: int in tendrils:
		var base_angle: float = TAU * i / tendrils + 0.3
		var points := PackedVector2Array()
		for k: int in 5:
			var t: float = float(k) / 4.0
			var wave: float = sin(_time * 2.5 + i * 1.3 + t * 3.0) * 0.35 * t
			points.append(Vector2.from_angle(base_angle + wave) * r * (0.5 + 0.85 * t))
		draw_polyline(points, OUTLINE_COLOR, 5.0)
		draw_polyline(points, body_color.darkened(0.3), 3.0)
		draw_polyline(points, body_color.darkened(0.05), 1.0)
	draw_circle(Vector2.ZERO, r * 0.62 + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, r * 0.62, body_color.darkened(0.15))
	draw_arc(Vector2.ZERO, r * 0.5, PI * 1.1, PI * 1.6, 8, body_color.lightened(0.2), 1.0)
	var beat: float = absf(sin(_time * (9.0 if _alert else 3.5)))
	draw_circle(Vector2(0, r * 0.28), r * (0.15 + 0.07 * beat), Color("e0464e").lightened(0.2 * beat))
	var eye := Vector2(0, -r * 0.12) + (look_direction * 1.5).round()
	draw_circle(eye, r * 0.3, EYE_WHITE)
	draw_rect(Rect2(eye + Vector2(-0.5, -r * 0.22), Vector2(1, r * 0.44)), ALERT_COLOR if _alert else OUTLINE_COLOR)


## El Yunque con su coraza: un guardián de hierro con hombreras, la cabeza con forma de yunque (el pico
## a un costado), la visera con ojos de brasa y la última llama encerrada en el pecho.
func _draw_anvil_knight() -> void:
	var r: float = radius
	var dark: Color = body_color.darkened(0.3)
	var torso := Rect2(-r * 0.65, -r * 0.35, r * 1.3, r * 1.1)
	draw_rect(torso.grow(1.0), OUTLINE_COLOR)
	draw_rect(torso, body_color)
	draw_rect(Rect2(torso.position.x, torso.end.y - r * 0.3, torso.size.x, r * 0.3), dark)
	for side: float in [-1.0, 1.0]:
		var pad := Rect2(side * r * 0.95 - r * 0.38, -r * 0.45, r * 0.76, r * 0.55)
		draw_rect(pad.grow(1.0), OUTLINE_COLOR)
		draw_rect(pad, body_color.lightened(0.1))
		draw_rect(Rect2(pad.position.x, pad.position.y, pad.size.x, 1), body_color.lightened(0.35))
		draw_rect(Rect2(pad.get_center() - Vector2(0.5, 0.5), Vector2.ONE), dark)
	# La rejilla del pecho con la llama adentro.
	var flicker: float = 0.7 + 0.3 * sin(_time * 8.0)
	var grate := Rect2(-r * 0.3, -r * 0.05, r * 0.6, r * 0.4)
	draw_rect(grate.grow(1.0), OUTLINE_COLOR)
	draw_rect(grate, Color(HOT_COLOR, flicker))
	draw_rect(Rect2(grate.position + Vector2(grate.size.x * 0.35, grate.size.y * 0.3), grate.size * Vector2(0.3, 0.6)), FIRE_CORE)
	for k: int in 3:
		draw_rect(Rect2(grate.position.x + grate.size.x * (k + 1) / 4.0, grate.position.y, 1, grate.size.y), OUTLINE_COLOR)
	# Cabeza de yunque.
	var head := Rect2(-r * 0.55, -r * 0.95, r * 1.0, r * 0.45)
	var horn := PackedVector2Array([Vector2(r * 0.45, -r * 0.95), Vector2(r * 0.95, -r * 0.82), Vector2(r * 0.45, -r * 0.6)])
	draw_colored_polygon(PackedVector2Array([horn[0] + Vector2(0, -1), horn[1] + Vector2(1.5, 0), horn[2] + Vector2(0, 1)]), OUTLINE_COLOR)
	draw_rect(head.grow(1.0), OUTLINE_COLOR)
	draw_colored_polygon(horn, body_color.lightened(0.15))
	draw_rect(head, body_color.lightened(0.15))
	draw_rect(Rect2(head.position, Vector2(head.size.x, 1)), body_color.lightened(0.4))
	var look: Vector2 = (look_direction * 1.0).round()
	draw_rect(Rect2(Vector2(-r * 0.4, -r * 0.75) + look, Vector2(r * 0.7, 2)), OUTLINE_COLOR)
	var eye_color: Color = ALERT_COLOR if _alert else HOT_COLOR
	draw_rect(Rect2(Vector2(-r * 0.3, -r * 0.75) + look, Vector2(2, 2)), eye_color)
	draw_rect(Rect2(Vector2(r * 0.1, -r * 0.75) + look, Vector2(2, 2)), eye_color)


## El Tijerón: unas tijeras de esquilar enormes, sin nadie que las sostenga: dos hojas con filo dentado
## que se abren y se cierran, lana enganchada, mangos atados con hilo rojo y un ojo en el tornillo.
func _draw_giant_shears() -> void:
	var r: float = radius
	var open: float = 0.75 if _alert else 0.3 + 0.2 * absf(sin(_time * 3.0))
	var forward: Vector2 = look_direction
	for side: float in [-1.0, 1.0]:
		var along: Vector2 = forward.rotated(side * open)
		var across: Vector2 = along.orthogonal() * side
		var tip: Vector2 = along * r * 1.5
		var blade := PackedVector2Array([across * 2.5, tip, -across * 1.0 + along * r * 0.3])
		var outline := PackedVector2Array([across * 3.5 - along, tip + along * 1.5, -across * 2.0 + along * r * 0.3])
		draw_colored_polygon(outline, OUTLINE_COLOR)
		draw_colored_polygon(blade, BLADE_COLOR)
		for k: int in 3:
			var notch: Vector2 = along * r * (0.5 + 0.3 * k) + across * 1.5
			draw_rect(Rect2(notch.round(), Vector2.ONE), body_color.darkened(0.3))
		var handle: Vector2 = -forward.rotated(-side * 0.55) * r * 0.85
		draw_line(Vector2.ZERO, handle, OUTLINE_COLOR, 4.0)
		draw_line(Vector2.ZERO, handle, body_color.darkened(0.2), 2.0)
		draw_arc(handle, r * 0.32, 0.0, TAU, 12, OUTLINE_COLOR, 3.0)
		draw_arc(handle, r * 0.32, 0.0, TAU, 12, body_color, 1.0)
		draw_line(handle * 0.55 + across * 1.0, handle * 0.55 - across * 1.0, Color("d9506a"), 2.0)
	for tuft: Vector2 in [Vector2(0.55, -0.15), Vector2(0.9, 0.2)]:
		draw_circle((forward * tuft.x * r + forward.orthogonal() * tuft.y * r).round(), 2.0, WOOL_COLOR)
	draw_circle(Vector2.ZERO, r * 0.3 + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, r * 0.3, body_color.darkened(0.1))
	draw_circle((forward * 0.8).round(), r * 0.16, ALERT_COLOR if _alert else EYE_WHITE)
	draw_rect(Rect2((forward * 1.5).round() - Vector2(0.5, 0.5), Vector2.ONE), OUTLINE_COLOR)


## El Cierzo: un espectro de tormenta encapuchado: un manto de nubes que se arremolina, la capucha vacía
## con dos ojos de hielo, una corona de escarcha y jirones de viento que se le escapan (más al avisar).
func _draw_storm() -> void:
	var r: float = radius
	var spin: float = _time * 2.0
	var wisps: int = 5 if not _alert else 8
	for i: int in wisps:
		var angle: float = spin + TAU * i / wisps
		var from: Vector2 = Vector2.from_angle(angle) * r * 0.8
		var to: Vector2 = Vector2.from_angle(angle + 0.6) * r * (1.25 + 0.15 * sin(_time * 4.0 + i))
		draw_line(from, to, Color(EYE_WHITE, 0.45), 1.0)
	var cloak := PackedVector2Array([Vector2(-r * 0.5, -r * 0.9), Vector2(r * 0.5, -r * 0.9), Vector2(r * 0.85, -r * 0.2),
			Vector2(r * 1.0, r * 0.75), Vector2(r * 0.5, r * 0.55 + sin(_time * 5.0) * 1.5), Vector2(0, r * 0.85),
			Vector2(-r * 0.5, r * 0.55 - sin(_time * 5.0) * 1.5), Vector2(-r * 1.0, r * 0.75), Vector2(-r * 0.85, -r * 0.2)])
	_outlined_polygon(cloak, body_color)
	for puff: Vector2 in [Vector2(-0.6, 0.35), Vector2(0.55, 0.3), Vector2(0.0, 0.55), Vector2(-0.35, -0.55), Vector2(0.4, -0.5)]:
		draw_circle((puff * r).round(), r * 0.24, body_color.lightened(0.18))
	var hood := Vector2(0, -r * 0.25)
	draw_circle(hood, r * 0.42, body_color.darkened(0.45))
	draw_circle(hood + Vector2(0, 1), r * 0.32, Color("0d1220"))
	var look: Vector2 = (look_direction * 1.5).round()
	var eye_color: Color = ALERT_COLOR if _alert else Color("bfe9ff")
	draw_rect(Rect2(hood + Vector2(-4, -1) + look, Vector2(2, 2)), eye_color)
	draw_rect(Rect2(hood + Vector2(2, -1) + look, Vector2(2, 2)), eye_color)
	for k: int in 5:
		var x: float = (k - 2) * r * 0.18
		var height: float = 3.0 + (k % 2) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, -r * 0.92), Vector2(x + 1.5, -r * 0.92),
				Vector2(x, -r * 0.92 - height)]), ICE_LIGHT)
