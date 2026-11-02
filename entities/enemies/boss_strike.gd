class_name BossStrike
extends Node2D
## Golpe de jefe que avisa dónde va a pegar: durante `warn_time` se ve la marca (la sombra del
## cascote que cae, la grieta de la raíz que va a salir, los tres tajos del zarpazo, el círculo del
## metal fundido) y después pega una vez a quien esté adentro. Con `linger` > 0 queda en el piso
## lastimando a quien lo pise (los i-frames del jugador marcan el ritmo). Rodando no lastima (el
## jugador está invulnerable). Un círculo de `radius`, o con `slash` un tajo de -slash a slash del
## ancho de `radius`. Se ve siempre, también en la oscuridad (sin sombra).

const GROUP: StringName = &"boss_strikes"
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")
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
	if look == BossAttack.Look.STONE:
		EventBus.shake_requested.emit(TRAUMA)
		var dust := Fx.spawn(get_tree(), DUST_SCENE, global_position) as CPUParticles2D
		dust.color = STONE_COLOR
	elif look == BossAttack.Look.CLAW:
		var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position) as CPUParticles2D
		burst.color = CLAW_COLOR
		burst.amount = 8
	if pattern != null:
		var spec := ShotSpec.from_pattern(pattern)
		spec.speed *= speed_multiplier
		for direction: Vector2 in PatternMath.ring(pattern.count, deg_to_rad(pattern.angle_offset_degrees)):
			Bullet.spawn(get_tree(), BULLET_SCENE, spec, global_position + direction * REACH, direction,
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
