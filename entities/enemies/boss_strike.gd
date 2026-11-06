class_name BossStrike
extends Node2D
## Golpe de jefe que avisa dónde va a pegar: durante `warn_time` se ve la marca (la sombra del
## cascote que cae, la grieta de la raíz que va a salir, los tres tajos del zarpazo, el círculo del
## metal fundido, el brillo de una tijera, la sombra de un carámbano, el círculo que titila antes del
## rayo, la franja por donde pasa la manada, la piña que cae, la grieta por donde brota la lava) y
## después pega una vez a quien esté adentro. Con `linger` > 0 queda en el piso
## lastimando a quien lo pise (los i-frames del jugador marcan el ritmo). Rodando no lastima (el
## jugador está invulnerable). Un círculo de `radius`, o con `slash` un tajo de -slash a slash del
## ancho de `radius`. Se ve siempre, también en la oscuridad (sin sombra).

const GROUP: StringName = &"boss_strikes"
const DUST_SCENE: PackedScene = preload("res://fx/dust_puff.tscn")
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const UNSHADED: Material = preload("res://fx/unshaded.tres")
const KNOCKBACK: float = 120.0
## Margen sobre el radio (el cuerpo del jugador).
const REACH: float = 3.0
## Cuánto se sigue viendo el golpe después de pegar.
const HIT_SHOW: float = 0.3
## Desde qué altura cae un cascote, y en qué parte final del aviso se lo ve caer.
const DROP_HEIGHT: float = 110.0
const DROP_PART: float = 0.35
## Lo que tarda un charco en apagarse al final.
const FADE_TIME: float = 0.4
const TRAUMA: float = 0.12
## Varios golpes en el mismo tick (o casi) suenan una vez.
const SOUND_GAP_TICKS: int = 4
const STONE_COLOR: Color = Color("8a7f86")
const ROOT_COLOR: Color = Color("9e6bc7")
const CLAW_COLOR: Color = Color("ff5a5a")
const EMBER_COLOR: Color = Color("ff8a3d")
const BLADE_COLOR: Color = Color("e6ecf5")
const ICE_COLOR: Color = Color("a8dcff")
const BOLT_COLOR: Color = Color("fff27a")
const HOOF_COLOR: Color = Color("c9a46a")
const WOOL_COLOR: Color = Color("e9e1cf")
const CONE_COLOR: Color = Color("9a6234")
const LAVA_COLOR: Color = Color("ff5a2a")
const OUTLINE_COLOR_DARK: Color = Color("2a2230")
const CORE_COLOR: Color = Color("fff6d5")
const SHADOW_COLOR: Color = Color(0, 0, 0, 0.45)

static var _last_sound_tick: int = -100

var look: BossAttack.Look = BossAttack.Look.STONE
var warn_time: float = 0.8
var damage: float = 1.0
var radius: float = 12.0
var linger: float = 0.0
## Balas que suelta al pegar (null = ninguna).
var pattern: BulletPatternData
var speed_multiplier: float = 1.0
## Tajo (CLAW): de -slash a slash; cero = un círculo.
var slash: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _struck: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	material = UNSHADED


func has_struck() -> bool:
	return _struck


## true si `point` (global) queda adentro del golpe.
func covers(point: Vector2) -> bool:
	var local: Vector2 = point - global_position
	if slash != Vector2.ZERO:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(local, -slash, slash)
		return closest.distance_to(local) <= radius + REACH
	return local.length() <= radius + REACH


## Se borra sin pegar (murió el jefe).
func vanish() -> void:
	queue_free()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not _struck:
		if _elapsed >= warn_time:
			_strike()
		return
	var after: float = _elapsed - warn_time
	if after < linger:
		_hurt_player()
	if after >= maxf(HIT_SHOW, linger + (FADE_TIME if linger > 0.0 else 0.0)):
		queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _strike() -> void:
	_struck = true
	_hurt_player()
	var tick: int = Engine.get_physics_frames()
	if tick - _last_sound_tick >= SOUND_GAP_TICKS:
		_last_sound_tick = tick
		match look:
			BossAttack.Look.STONE:
				AudioManager.play_sfx(&"debris", 0.15)
			BossAttack.Look.ROOT:
				AudioManager.play_sfx(&"root", 0.15)
			BossAttack.Look.CLAW:
				AudioManager.play_sfx(&"claw", 0.1)
			BossAttack.Look.EMBER:
				AudioManager.play_sfx(&"molten", 0.15)
			BossAttack.Look.BLADE:
				AudioManager.play_sfx(&"snip", 0.1)
			BossAttack.Look.ICE:
				AudioManager.play_sfx(&"icicle", 0.15)
			BossAttack.Look.BOLT:
				AudioManager.play_sfx(&"bolt", 0.1)
			BossAttack.Look.HOOVES:
				AudioManager.play_sfx(&"stampede", 0.1)
			BossAttack.Look.PINECONE:
				AudioManager.play_sfx(&"debris", 0.15)
			BossAttack.Look.LAVA:
				AudioManager.play_sfx(&"molten", 0.15)
	if look == BossAttack.Look.BOLT or look == BossAttack.Look.HOOVES or look == BossAttack.Look.LAVA:
		EventBus.shake_requested.emit(TRAUMA)
	if look == BossAttack.Look.STONE or look == BossAttack.Look.ICE:
		EventBus.shake_requested.emit(TRAUMA)
		var dust := Fx.spawn(get_tree(), DUST_SCENE, global_position) as CPUParticles2D
		dust.color = STONE_COLOR if look == BossAttack.Look.STONE else ICE_COLOR
	elif look == BossAttack.Look.PINECONE:
		var chips := Fx.spawn(get_tree(), DUST_SCENE, global_position) as CPUParticles2D
		chips.color = CONE_COLOR
	elif look == BossAttack.Look.CLAW:
		var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position) as CPUParticles2D
		burst.color = CLAW_COLOR
		burst.amount = 8
	if pattern != null:
		var spec := ShotSpec.from_pattern(pattern)
		spec.speed *= speed_multiplier
		for direction: Vector2 in PatternMath.ring(pattern.count, deg_to_rad(pattern.angle_offset_degrees)):
			Bullet.spawn(get_tree(), Bullet.default_scene(), spec, global_position + direction * REACH, direction,
					PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)


func _hurt_player() -> void:
	for node: Node in get_tree().get_nodes_in_group(Player.GROUP):
		var player := node as Player
		if covers(player.global_position):
			player.hurtbox.receive_hit(HitInfo.create(damage, player.global_position - global_position, KNOCKBACK))


func _draw() -> void:
	var warn: float = clampf(_elapsed / warn_time, 0.0, 1.0) if warn_time > 0.0 else 1.0
	var after: float = _elapsed - warn_time
	var blink: float = 0.55 + 0.35 * sin(_elapsed * 24.0)
	match look:
		BossAttack.Look.STONE:
			_draw_stone(warn, after, blink)
		BossAttack.Look.ROOT:
			_draw_root(warn, after, blink)
		BossAttack.Look.CLAW:
			_draw_claw(warn, after, blink)
		BossAttack.Look.EMBER:
			_draw_ember(warn, after, blink)
		BossAttack.Look.BLADE:
			_draw_blade(warn, after, blink)
		BossAttack.Look.ICE:
			_draw_ice(warn, after, blink)
		BossAttack.Look.BOLT:
			_draw_bolt(warn, after)
		BossAttack.Look.HOOVES:
			_draw_hooves(warn, after, blink)
		BossAttack.Look.PINECONE:
			_draw_pinecone(warn, after, blink)
		BossAttack.Look.LAVA:
			_draw_lava(warn, after, blink)


## La sombra crece y se oscurece; al final se ve caer la piedra.
func _draw_stone(warn: float, after: float, blink: float) -> void:
	if not _struck:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, radius * (0.35 + 0.65 * warn), Color(SHADOW_COLOR, 0.2 + 0.35 * warn))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(STONE_COLOR, blink * 0.6), 1.0)
		draw_set_transform(Vector2.ZERO)
		var fall: float = clampf((warn - (1.0 - DROP_PART)) / DROP_PART, 0.0, 1.0)
		if fall > 0.0:
			var rock := Vector2(0, -roundf(DROP_HEIGHT * (1.0 - fall * fall)))
			draw_circle(rock, radius * 0.55 + 1.0, STONE_COLOR.darkened(0.45))
			draw_circle(rock, radius * 0.55, STONE_COLOR)
			draw_circle(rock + Vector2(-2, -2), 1.5, STONE_COLOR.lightened(0.4))
		return
	var fade: float = 1.0 - clampf(after / HIT_SHOW, 0.0, 1.0)
	for i: int in 6:
		var direction := Vector2.from_angle(TAU * i / 6.0 + 0.4)
		draw_line(direction * radius * 0.3, direction * radius, Color(STONE_COLOR, fade), 1.0)
	draw_circle(Vector2.ZERO, radius * 0.4, Color(STONE_COLOR.darkened(0.3), fade))


## Una grieta que late; al pegar sale la punta de la raíz.
func _draw_root(warn: float, after: float, blink: float) -> void:
	if not _struck:
		draw_circle(Vector2.ZERO, radius * (0.3 + 0.5 * warn), Color(ROOT_COLOR.darkened(0.6), 0.5))
		draw_line(Vector2(-radius * 0.7, 1), Vector2(radius * 0.7, -1), Color(ROOT_COLOR, blink), 1.0)
		draw_line(Vector2(-1, -radius * 0.5), Vector2(1, radius * 0.5), Color(ROOT_COLOR, blink * 0.7), 1.0)
		return
	var grow: float = clampf(after / 0.08, 0.0, 1.0)
	var fade: float = 1.0 - clampf((after - 0.15) / (HIT_SHOW - 0.15), 0.0, 1.0)
	var height: float = radius * 1.6 * grow
	var spike := PackedVector2Array([Vector2(-radius * 0.55, 2), Vector2(0, -height), Vector2(radius * 0.55, 2)])
	draw_colored_polygon(spike, Color(ROOT_COLOR.darkened(0.25), fade))
	draw_line(Vector2(0, -height), Vector2(-1, 1), Color(ROOT_COLOR.lightened(0.4), fade), 1.0)


## Tres tajos finos que titilan; al pegar se marcan gruesos y brillantes.
func _draw_claw(warn: float, after: float, blink: float) -> void:
	var side: Vector2 = slash.orthogonal().normalized() * (radius * 0.6)
	if not _struck:
		for i: int in 3:
			var offset: Vector2 = side * (i - 1)
			var reach: float = 0.5 + 0.5 * warn
			draw_line(offset - slash * reach, offset + slash * reach, Color(CLAW_COLOR, blink * 0.7), 1.0)
		return
	var sweep: float = clampf(after / 0.07, 0.0, 1.0)
	var fade: float = 1.0 - clampf((after - 0.1) / (HIT_SHOW - 0.1), 0.0, 1.0)
	for i: int in 3:
		var offset: Vector2 = side * (i - 1)
		var tip: Vector2 = -slash + slash * 2.0 * sweep
		draw_line(offset - slash, offset + tip, Color(CLAW_COLOR, fade), 3.0)
		draw_line(offset - slash, offset + tip, Color(CORE_COLOR, fade), 1.0)


## Un círculo que crece y late; al pegar salpica y, con `linger`, queda un charco que burbujea.
func _draw_ember(warn: float, after: float, blink: float) -> void:
	if not _struck:
		draw_circle(Vector2.ZERO, radius * warn, Color(EMBER_COLOR, 0.15))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(EMBER_COLOR, blink), 1.0)
		return
	if linger <= 0.0:
		var fade: float = 1.0 - clampf(after / HIT_SHOW, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius * (0.6 + 0.4 * fade), Color(EMBER_COLOR, 0.6 * fade))
		draw_circle(Vector2.ZERO, radius * 0.4, Color(CORE_COLOR, fade))
		return
	var alpha: float = 1.0 - clampf((after - linger) / FADE_TIME, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.7))
	draw_circle(Vector2.ZERO, radius + 1.0, Color(EMBER_COLOR.darkened(0.55), 0.85 * alpha))
	draw_circle(Vector2.ZERO, radius, Color(EMBER_COLOR, 0.8 * alpha))
	draw_circle(Vector2.ZERO, radius * 0.55, Color(CORE_COLOR, 0.5 * alpha * (0.8 + 0.2 * sin(_elapsed * 9.0))))
	for i: int in 3:
		var bubble := Vector2.from_angle(_elapsed * 1.7 + TAU * i / 3.0) * radius * 0.6
		draw_circle(bubble, 1.0 + 0.5 * sin(_elapsed * 6.0 + i), Color(CORE_COLOR, 0.7 * alpha))
	draw_set_transform(Vector2.ZERO)


## Un brillo fino que se estira; al pegar, el corte de una tijera (dos hojas cruzadas). Con `linger`, el
## corte queda abierto en el aire (titila) hasta cerrarse.
func _draw_blade(warn: float, after: float, blink: float) -> void:
	if not _struck:
		draw_line(-slash * warn, slash * warn, Color(BLADE_COLOR, blink * 0.7), 1.0)
		return
	if linger > 0.0:
		var alpha: float = 1.0 - clampf((after - linger) / FADE_TIME, 0.0, 1.0)
		var shimmer: float = 0.7 + 0.3 * sin(_elapsed * 18.0)
		var across: Vector2 = slash.orthogonal().normalized()
		draw_line(-slash - across, slash - across, Color(CLAW_COLOR, 0.5 * alpha), 1.0)
		draw_line(-slash + across, slash + across, Color(CLAW_COLOR, 0.5 * alpha), 1.0)
		draw_line(-slash, slash, Color(BLADE_COLOR, shimmer * alpha), 2.0)
		draw_line(-slash * 0.9, slash * 0.9, Color(CORE_COLOR, alpha), 1.0)
		return
	var fade: float = 1.0 - clampf(after / HIT_SHOW, 0.0, 1.0)
	var side: Vector2 = slash.orthogonal().normalized() * 2.0
	draw_line(-slash - side, slash + side, Color(BLADE_COLOR, fade), 2.0)
	draw_line(-slash + side, slash - side, Color(BLADE_COLOR, fade), 2.0)
	draw_line(-slash, slash, Color(CORE_COLOR, fade), 1.0)


## La sombra crece y al final cae un carámbano; al pegar, astillas. Con `linger` queda clavado.
func _draw_ice(warn: float, after: float, blink: float) -> void:
	if not _struck:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, radius * (0.35 + 0.65 * warn), Color(SHADOW_COLOR, 0.2 + 0.35 * warn))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(ICE_COLOR, blink * 0.7), 1.0)
		draw_set_transform(Vector2.ZERO)
		var fall: float = clampf((warn - (1.0 - DROP_PART)) / DROP_PART, 0.0, 1.0)
		if fall > 0.0:
			_draw_icicle(Vector2(0, -roundf(DROP_HEIGHT * (1.0 - fall * fall))), 1.0)
		return
	var fade: float = 1.0 - clampf(after / HIT_SHOW, 0.0, 1.0)
	for i: int in 6:
		var direction := Vector2.from_angle(TAU * i / 6.0 + 0.2)
		draw_line(direction * radius * 0.3, direction * radius, Color(ICE_COLOR, fade), 1.0)
	if linger > 0.0:
		_draw_icicle(Vector2.ZERO, 1.0 - clampf((after - linger) / FADE_TIME, 0.0, 1.0))


## Un carámbano clavado (la punta abajo, en `at`).
func _draw_icicle(at: Vector2, alpha: float) -> void:
	var width: float = minf(radius * 0.5, 6.0)
	var height: float = minf(radius * 1.6, 22.0)
	var shape := PackedVector2Array([at + Vector2(-width, -height), at + Vector2(width, -height), at])
	draw_colored_polygon(shape, Color(ICE_COLOR, 0.9 * alpha))
	draw_line(at + Vector2(-width * 0.3, -height), at + Vector2(0, -1), Color(CORE_COLOR, 0.8 * alpha), 1.0)


## Un círculo que titila cada vez más rápido; al pegar, un rayo en zigzag que baja del cielo.
func _draw_bolt(warn: float, after: float) -> void:
	if not _struck:
		var flicker: float = 0.35 + 0.65 * float(int(_elapsed * (6.0 + 26.0 * warn)) % 2)
		draw_circle(Vector2.ZERO, radius * warn, Color(BOLT_COLOR, 0.12))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(BOLT_COLOR, flicker * 0.8), 1.0)
		return
	var fade: float = 1.0 - clampf(after / HIT_SHOW, 0.0, 1.0)
	var points := PackedVector2Array()
	var y: float = -DROP_HEIGHT
	var i: int = 0
	while y < 0.0:
		points.append(Vector2(0.0 if i == 0 else (4.0 if i % 2 == 0 else -4.0), y))
		y += 12.0
		i += 1
	points.append(Vector2.ZERO)
	draw_polyline(points, Color(BOLT_COLOR, fade), 3.0)
	draw_polyline(points, Color(CORE_COLOR, fade), 1.0)
	draw_circle(Vector2.ZERO, radius * (0.5 + 0.5 * fade), Color(BOLT_COLOR, 0.35 * fade))


## Una franja de polvo con flechas hacia donde corre la manada; al pegar, carneros que la cruzan.
func _draw_hooves(warn: float, after: float, blink: float) -> void:
	var along: Vector2 = slash.normalized()
	var half: float = slash.length()
	var side: Vector2 = along.orthogonal() * radius
	var band := PackedVector2Array([-slash - side, slash - side, slash + side, -slash + side])
	if not _struck:
		draw_colored_polygon(band, Color(HOOF_COLOR, 0.08 + 0.17 * warn))
		draw_line(-slash - side, slash - side, Color(HOOF_COLOR, blink * 0.5), 1.0)
		draw_line(-slash + side, slash + side, Color(HOOF_COLOR, blink * 0.5), 1.0)
		for k: int in 5:
			var at: Vector2 = along * (-half + half * 2.0 * (k + 0.5) / 5.0)
			draw_line(at - along * 3.0 - side * 0.4, at, Color(HOOF_COLOR, blink), 1.0)
			draw_line(at - along * 3.0 + side * 0.4, at, Color(HOOF_COLOR, blink), 1.0)
		return
	var alpha: float = 1.0 - clampf((after - linger) / FADE_TIME, 0.0, 1.0) if linger > 0.0 \
			else 1.0 - clampf(after / HIT_SHOW, 0.0, 1.0)
	draw_colored_polygon(band, Color(HOOF_COLOR.darkened(0.3), 0.35 * alpha))
	var run: float = after * 260.0
	for k: int in 4:
		var at: Vector2 = along * (-half + fmod(run + k * half * 0.5, half * 2.0))
		draw_circle(at, radius * 0.7, Color(OUTLINE_COLOR_DARK, alpha))
		draw_circle(at, radius * 0.6, Color(WOOL_COLOR, alpha))
		draw_circle(at + along * radius * 0.5, radius * 0.3, Color(HOOF_COLOR.darkened(0.5), alpha))


## La sombra crece y al final cae una piña; al pegar, se parte en pedazos.
func _draw_pinecone(warn: float, after: float, blink: float) -> void:
	if not _struck:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, radius * (0.35 + 0.65 * warn), Color(SHADOW_COLOR, 0.2 + 0.35 * warn))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(CONE_COLOR.lightened(0.3), blink * 0.7), 1.0)
		draw_set_transform(Vector2.ZERO)
		var fall: float = clampf((warn - (1.0 - DROP_PART)) / DROP_PART, 0.0, 1.0)
		if fall > 0.0:
			_draw_cone(Vector2(0, -roundf(DROP_HEIGHT * (1.0 - fall * fall))), 1.0)
		return
	var fade: float = 1.0 - clampf(after / HIT_SHOW, 0.0, 1.0)
	for i: int in 5:
		var direction := Vector2.from_angle(TAU * i / 5.0 + 0.3)
		var at: Vector2 = (direction * radius * (0.3 + 0.7 * (1.0 - fade))).round()
		draw_rect(Rect2(at - Vector2(1, 1), Vector2(2, 2)), Color(CONE_COLOR, fade))


## Una piña: un óvalo de escamas con la punta abajo (en `at`).
func _draw_cone(at: Vector2, alpha: float) -> void:
	var width: float = minf(radius * 0.45, 5.0)
	var height: float = minf(radius * 1.1, 12.0)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-width - 1.0, -height), at + Vector2(width + 1.0, -height),
			at + Vector2(0, 1)]), Color(OUTLINE_COLOR_DARK, alpha))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-width, -height + 1.0), at + Vector2(width, -height + 1.0), at]),
			Color(CONE_COLOR, alpha))
	for row: int in 3:
		var y: float = -height + 3.0 + row * 3.0
		draw_line(at + Vector2(-width * 0.6, y), at + Vector2(width * 0.6, y + 1.0), Color(CONE_COLOR.darkened(0.35), alpha), 1.0)


## La grieta brilla y burbujea (cada vez más rápido); al pegar sale un chorro de lava y, con `linger`,
## queda el charco.
func _draw_lava(warn: float, after: float, blink: float) -> void:
	if not _struck:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, radius * (0.3 + 0.7 * warn), Color(LAVA_COLOR.darkened(0.5), 0.35))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(LAVA_COLOR, blink), 1.0)
		draw_set_transform(Vector2.ZERO)
		draw_line(Vector2(-radius * 0.6, 1), Vector2(-1, -1), Color(EMBER_COLOR, blink), 1.0)
		draw_line(Vector2(-1, -1), Vector2(radius * 0.5, 2), Color(EMBER_COLOR, blink), 1.0)
		var bubbles: float = 4.0 + 16.0 * warn
		for i: int in 3:
			var pop: float = fmod(_elapsed * bubbles * 0.25 + i * 0.37, 1.0)
			var at := Vector2((i - 1) * radius * 0.35, -pop * 4.0).round()
			draw_rect(Rect2(at, Vector2.ONE), Color(CORE_COLOR, 1.0 - pop))
		return
	var spurt: float = clampf(after / 0.25, 0.0, 1.0)
	var spurt_fade: float = 1.0 - clampf((after - 0.25) / 0.25, 0.0, 1.0)
	if spurt_fade > 0.0:
		var height: float = radius * 2.6 * sin(spurt * PI * 0.5)
		draw_rect(Rect2(-radius * 0.35, -height, radius * 0.7, height), Color(LAVA_COLOR, spurt_fade))
		draw_rect(Rect2(-radius * 0.15, -height, radius * 0.3, height), Color(CORE_COLOR, spurt_fade))
		for i: int in 4:
			var drop := Vector2((i - 1.5) * radius * 0.5, -height * (0.6 + 0.1 * i))
			draw_rect(Rect2(drop.round(), Vector2(2, 2)), Color(EMBER_COLOR, spurt_fade))
	if linger <= 0.0:
		return
	var alpha: float = 1.0 - clampf((after - linger) / FADE_TIME, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.7))
	draw_circle(Vector2.ZERO, radius + 1.0, Color(LAVA_COLOR.darkened(0.6), 0.85 * alpha))
	draw_circle(Vector2.ZERO, radius, Color(LAVA_COLOR, 0.8 * alpha))
	draw_circle(Vector2.ZERO, radius * 0.5, Color(CORE_COLOR, 0.45 * alpha * (0.8 + 0.2 * sin(_elapsed * 9.0))))
	draw_set_transform(Vector2.ZERO)
