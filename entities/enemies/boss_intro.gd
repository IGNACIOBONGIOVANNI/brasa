class_name BossIntro
extends Node2D
## La entrada de un jefe en su sala (EnemyData.intro): una pequeña cinemática hecha con su dibujo,
## efectos, sonidos y sacudones. Mientras dura, el jefe está en el aire (ni pega ni recibe) y el jugador
## mira (EventBus.cinematic_changed). Al terminar, o al saltearla (Enter o rodar), Enemy.finish_intro
## lo deja pelear. Va como hijo del jefe y dibuja por encima (grietas, raíces, nieve, viento, ojos en
## la oscuridad); se ve siempre, también a oscuras.

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const DUST_SCENE: PackedScene = preload("res://fx/dust_puff.tscn")
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const LIGHT_FLASH_SCENE: PackedScene = preload("res://fx/light_flash.tscn")
const DURATIONS: Dictionary[EnemyData.Intro, float] = {
	EnemyData.Intro.FALL: 2.6, EnemyData.Intro.FORGE_FALL: 2.6, EnemyData.Intro.EMERGE: 3.0,
	EnemyData.Intro.STOMP: 2.8, EnemyData.Intro.SPIN_IN: 2.4, EnemyData.Intro.SHADOW: 2.8,
	EnemyData.Intro.AVALANCHE: 2.8, EnemyData.Intro.GATHER: 2.8, EnemyData.Intro.CHIMNEY: 2.8,
}
## Se puede saltear pasado este tiempo (así un toque de más al entrar no la corta).
const SKIP_AFTER: float = 0.4
const FALL_TIME: float = 1.1
const FALL_HEIGHT: float = 140.0
const CRACK_TIME: float = 1.4
const RISE_TIME: float = 0.8
const SPIN_TIME: float = 1.2
const ROOT_COLOR: Color = Color("9e6bc7")
const DIRT_COLOR: Color = Color("6b4a32")
const EMBER_COLOR: Color = Color("ff8a3d")
const EYE_COLOR: Color = Color("ff4d6d")
const SHADOW_COLOR: Color = Color(0.12, 0.05, 0.15, 0.75)
const SNOW_COLOR: Color = Color("eef4fa")
const WIND_COLOR: Color = Color("dfe9f5")
const BOLT_COLOR: Color = Color("fff27a")
const CORE_COLOR: Color = Color("fff6d5")
const SOOT_COLOR: Color = Color(0.13, 0.11, 0.14, 0.9)
const ASH_COLOR: Color = Color("8a8490")
## CHIMNEY: cuánto cae el hollín antes de que salga.
const SOOT_TIME: float = 1.3

var _enemy: Enemy
var _style: EnemyData.Intro = EnemyData.Intro.NONE
var _duration: float = 2.6
var _time: float = 0.0
var _done: Dictionary[StringName, bool] = {}
var _finished: bool = false
var _dark: bool = false
## SPIN_IN: de dónde sale y adónde llega (global).
var _start: Vector2 = Vector2.ZERO
var _final: Vector2 = Vector2.ZERO


## Llamar antes de agregarla como hija del jefe.
func setup(enemy: Enemy) -> void:
	_enemy = enemy
	_style = enemy.data.intro
	_duration = DURATIONS.get(_style, 2.6)


func _ready() -> void:
	material = UNSHADED
	var visual: EnemyVisual = _enemy.visual
	match _style:
		EnemyData.Intro.FALL, EnemyData.Intro.FORGE_FALL:
			visual.set_lift(FALL_HEIGHT)
		EnemyData.Intro.EMERGE:
			_enemy.flash.fade = 0.0
			visual.intro_scale = Vector2(1.0, 0.05)
		EnemyData.Intro.STOMP:
			_darken(0.92, 0.2)
			_enemy.flash.fade = 0.0
		EnemyData.Intro.SPIN_IN:
			_final = _enemy.global_position
			_start = Vector2(_enemy.room_rect().position.x + 6.0, _final.y)
			_enemy.global_position = _start
		EnemyData.Intro.SHADOW:
			_darken(0.6, 0.3)
			_enemy.flash.fade = 0.0
		EnemyData.Intro.AVALANCHE:
			_enemy.flash.fade = 0.0
			visual.intro_scale = Vector2(0.15, 0.15)
		EnemyData.Intro.GATHER:
			_enemy.flash.fade = 0.0
			visual.intro_scale = Vector2(1.6, 1.6)
		EnemyData.Intro.CHIMNEY:
			_enemy.flash.fade = 0.0
			visual.intro_scale = Vector2(1.0, 0.05)


## Cuánto dura (para el menú de debug y los tests).
func duration() -> float:
	return _duration


func _physics_process(delta: float) -> void:
	_time += delta
	if _time > SKIP_AFTER and (Input.is_action_just_pressed(&"ui_accept") or Input.is_action_just_pressed(&"dodge")):
		_finish()
		return
	match _style:
		EnemyData.Intro.FALL, EnemyData.Intro.FORGE_FALL:
			_tick_fall()
		EnemyData.Intro.EMERGE:
			_tick_emerge()
		EnemyData.Intro.STOMP:
			_tick_stomp()
		EnemyData.Intro.SPIN_IN:
			_tick_spin()
		EnemyData.Intro.SHADOW:
			_tick_shadow()
		EnemyData.Intro.AVALANCHE:
			_tick_avalanche()
		EnemyData.Intro.GATHER:
			_tick_gather()
		EnemyData.Intro.CHIMNEY:
			_tick_chimney()
	if _time >= _duration:
		_finish()


func _process(_delta: float) -> void:
	queue_redraw()


## Termina (al final o salteada): deja todo como estaba y el jefe pelea.
func _finish() -> void:
	if _finished:
		return
	_restore()
	_enemy.finish_intro()
	queue_free()


## Si el jefe se va antes de terminar (debug, fin de la run), el jugador no puede quedar trabado.
func _exit_tree() -> void:
	if _finished:
		return
	_restore()
	EventBus.cinematic_changed.emit(false)


func _restore() -> void:
	_finished = true
	var visual: EnemyVisual = _enemy.visual
	visual.set_lift(0.0)
	_enemy.flash.fade = 1.0
	visual.intro_scale = Vector2.ONE
	visual.intro_offset = Vector2.ZERO
	visual.rotation = 0.0
	visual.set_alert(false)
	if _style == EnemyData.Intro.SPIN_IN:
		_enemy.global_position = _final
	if _dark:
		EventBus.darkness_requested.emit(0.0, 0.3)
		_dark = false


## true una sola vez, el primer tick en que la cinemática pasa `at` segundos.
func _once(key: StringName, at: float) -> bool:
	if _time < at or _done.has(key):
		return false
	_done[key] = true
	return true


func _darken(amount: float, fade: float) -> void:
	_dark = amount > 0.0
	EventBus.darkness_requested.emit(amount, fade)


func _shake(trauma: float) -> void:
	EventBus.shake_requested.emit(trauma)


func _dust(at: Vector2, color: Color) -> void:
	var dust := Fx.spawn(get_tree(), DUST_SCENE, global_position + at) as CPUParticles2D
	dust.color = color


func _burst(color: Color, amount: int) -> void:
	var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position + Vector2(0, -4)) as CPUParticles2D
	burst.color = color
	burst.amount = amount


func _flash(color: Color, size: float) -> void:
	var glow := Fx.spawn(get_tree(), LIGHT_FLASH_SCENE, global_position) as LightFlash
	glow.color = color
	glow.texture_scale = size
	glow.duration = 0.5


func _roar(at: float) -> void:
	if _once(&"roar", at):
		_enemy.visual.set_alert(true)
		_enemy.visual.play_hit()
		_shake(0.4)
		AudioManager.play_sfx(&"boss_phase", 0.05)
	if _once(&"quiet", at + 0.5):
		_enemy.visual.set_alert(false)


func _radius() -> float:
	return _enemy.data.visual_radius


# --- Cada entrada ---------------------------------------------------------------------------------


## Cae del techo: la sombra crece (EnemyVisual con lift), choca con un sacudón, polvo y un aro.
func _tick_fall() -> void:
	if _once(&"rumble", 0.0):
		_shake(0.15)
		AudioManager.play_sfx(&"rumble")
	if _time < FALL_TIME:
		var k: float = _time / FALL_TIME
		_enemy.visual.set_lift(FALL_HEIGHT * (1.0 - k * k))
	if _once(&"land", FALL_TIME):
		_enemy.visual.set_lift(0.0)
		_enemy.visual.play_hit()
		_shake(0.9)
		EventBus.hitstop_requested.emit(0.08)
		var forge: bool = _style == EnemyData.Intro.FORGE_FALL
		for i: int in 8:
			_dust(Vector2.from_angle(TAU * i / 8.0) * _radius() * 1.2 + Vector2(0, 4), EMBER_COLOR if forge else Color("8a7f86"))
		_burst(EMBER_COLOR if forge else _enemy.data.body_color, 30)
		_flash(EMBER_COLOR if forge else _enemy.data.body_color.lightened(0.4), 3.0)
		AudioManager.play_sfx(&"explosion")
		AudioManager.play_sfx(&"molten" if forge else &"debris", 0.05)
	_roar(1.8)


## Sale de la tierra: grietas que crecen con temblores, revientan raíces y el jefe sube desde abajo.
func _tick_emerge() -> void:
	if _time < CRACK_TIME:
		var pulse: int = int(_time / 0.25)
		if _once(StringName("pulse_%d" % pulse), pulse * 0.25):
			_shake(0.1 + 0.15 * _time / CRACK_TIME)
			_dust(Vector2.from_angle(TAU * pulse / 7.0 + 0.4) * 40.0 * _time / CRACK_TIME, DIRT_COLOR)
	if _once(&"rumble", 0.0):
		AudioManager.play_sfx(&"rumble")
	if _once(&"rumble_2", 0.7):
		AudioManager.play_sfx(&"rumble")
	if _once(&"burst", CRACK_TIME):
		_enemy.flash.fade = 1.0
		_shake(0.85)
		EventBus.hitstop_requested.emit(0.06)
		_burst(DIRT_COLOR, 36)
		AudioManager.play_sfx(&"root")
		AudioManager.play_sfx(&"rock_break", 0.05)
	if _time >= CRACK_TIME:
		var k: float = clampf((_time - CRACK_TIME) / RISE_TIME, 0.0, 1.0)
		var rise: float = 1.0 - pow(1.0 - k, 3.0)
		_enemy.visual.intro_scale = Vector2(1.0, lerpf(0.05, 1.0, rise))
	_roar(2.3)


## Dos ojos en la oscuridad, dos pisotones que sacuden la sala y vuelve la luz.
func _tick_stomp() -> void:
	for stomp: Array in [[&"stomp_1", 1.0], [&"stomp_2", 1.5]]:
		if _once(stomp[0], stomp[1]):
			_shake(0.45)
			_dust(Vector2(-6, 6), Color("8a7f86"))
			_dust(Vector2(6, 6), Color("8a7f86"))
			AudioManager.play_sfx(&"ram_hit", 0.05)
	if _once(&"light", 1.9):
		_darken(0.0, 0.3)
	if _time >= 1.9:
		_enemy.flash.fade = clampf((_time - 1.9) / 0.3, 0.0, 1.0)
	if _once(&"bellow", 2.2):
		AudioManager.play_sfx(&"ram")
	_roar(2.2)


## Entra girando desde un costado, frena en su lugar y corta el aire dos veces.
func _tick_spin() -> void:
	var k: float = clampf(_time / SPIN_TIME, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - k, 3.0)
	_enemy.global_position = _start.lerp(_final, eased)
	_enemy.visual.rotation = (1.0 - eased) * 14.0
	if k < 1.0:
		var step: int = int(_time / 0.25)
		if _once(StringName("whirl_%d" % step), step * 0.25):
			AudioManager.play_sfx(&"snip", 0.15)
	for cut: Array in [[&"cut_1", 1.4], [&"cut_2", 1.75]]:
		if _once(cut[0], cut[1]):
			_shake(0.3)
			AudioManager.play_sfx(&"snip")
	_roar(2.0)


## Se arma de las sombras: jirones oscuros que se juntan, primero los ojos y después el cuerpo.
func _tick_shadow() -> void:
	if _once(&"whisper", 0.0):
		AudioManager.play_sfx(&"darkness")
	if _time >= 1.0:
		_enemy.flash.fade = clampf((_time - 1.0) / 0.8, 0.0, 1.0)
	if _once(&"burst", 1.8):
		_darken(0.0, 0.3)
		_shake(0.6)
		_burst(Color("3a2040"), 30)
		AudioManager.play_sfx(&"ram")
	_roar(2.2)


## Cae nieve, la montaña crece desde el piso y abre los ojos con un sacudón.
func _tick_avalanche() -> void:
	if _once(&"rumble", 0.0):
		_shake(0.2)
		AudioManager.play_sfx(&"rumble")
	if _once(&"rumble_2", 0.8):
		_shake(0.3)
	if _time >= 0.6:
		_enemy.flash.fade = 1.0
		var k: float = clampf((_time - 0.6) / 1.1, 0.0, 1.0)
		var size: float = lerpf(0.15, 1.0, 1.0 - pow(1.0 - k, 2.0))
		_enemy.visual.intro_scale = Vector2(size, size)
	if _once(&"wake", 1.8):
		_shake(0.7)
		_burst(SNOW_COLOR, 30)
		AudioManager.play_sfx(&"icicle")
	_roar(1.8)


## El viento se arremolina, lo forma de a poco y cae un rayo.
func _tick_gather() -> void:
	if _once(&"gust", 0.0):
		AudioManager.play_sfx(&"gust")
	if _once(&"gust_2", 1.0):
		AudioManager.play_sfx(&"gust")
	if _time >= 1.0:
		var k: float = clampf((_time - 1.0) / 0.8, 0.0, 1.0)
		_enemy.flash.fade = k
		var size: float = lerpf(1.6, 1.0, k)
		_enemy.visual.intro_scale = Vector2(size, size)
	if _once(&"bolt", 1.8):
		_flash(Color.WHITE, 4.0)
		_shake(0.7)
		EventBus.hitstop_requested.emit(0.05)
		AudioManager.play_sfx(&"bolt")
	_roar(2.2)


## Cae hollín como por una chimenea y se amontona; de la pila sale él, sacude la ceniza y golpea dos
## veces el piso con la caña.
func _tick_chimney() -> void:
	if _once(&"rumble", 0.0):
		_shake(0.15)
		AudioManager.play_sfx(&"debris")
	if _once(&"rumble_2", 0.6):
		AudioManager.play_sfx(&"debris", 0.1)
	if _once(&"rise", SOOT_TIME):
		_enemy.flash.fade = 1.0
		_shake(0.6)
		_burst(ASH_COLOR, 34)
		_dust(Vector2(-8, 6), ASH_COLOR)
		_dust(Vector2(8, 6), ASH_COLOR)
		AudioManager.play_sfx(&"gust")
	if _time >= SOOT_TIME:
		var k: float = clampf((_time - SOOT_TIME) / 0.6, 0.0, 1.0)
		_enemy.visual.intro_scale = Vector2(1.0, lerpf(0.05, 1.0, 1.0 - pow(1.0 - k, 3.0)))
	for tap: Array in [[&"tap_1", 2.0], [&"tap_2", 2.3]]:
		if _once(tap[0], tap[1]):
			_shake(0.25)
			_dust(Vector2(10, 8), ASH_COLOR)
			AudioManager.play_sfx(&"ram_hit", 0.1)
	_roar(2.1)


# --- Dibujos ---------------------------------------------------------------------------------------


func _draw() -> void:
	match _style:
		EnemyData.Intro.FALL, EnemyData.Intro.FORGE_FALL:
			_draw_fall()
		EnemyData.Intro.EMERGE:
			_draw_emerge()
		EnemyData.Intro.STOMP:
			_draw_eyes(0.4, 2.2)
			_draw_stomp_rings()
		EnemyData.Intro.SPIN_IN:
			_draw_spin()
		EnemyData.Intro.SHADOW:
			_draw_shadow()
			_draw_eyes(0.8, 1.9)
		EnemyData.Intro.AVALANCHE:
			_draw_snowfall()
		EnemyData.Intro.GATHER:
			_draw_gather()
		EnemyData.Intro.CHIMNEY:
			_draw_chimney()


func _draw_fall() -> void:
	var forge: bool = _style == EnemyData.Intro.FORGE_FALL
	if forge and _time < FALL_TIME:
		# Brasas que llueven antes de que caiga.
		for i: int in 14:
			var x: float = fmod(i * 47.3, 220.0) - 110.0
			var y: float = fmod(_time * (70.0 + (i % 4) * 25.0) + i * 31.0, 150.0) - 110.0
			draw_rect(Rect2(Vector2(x, y).round(), Vector2(1, 2)), Color(EMBER_COLOR, 0.8))
	var after: float = _time - FALL_TIME
	if after >= 0.0 and after < 0.6:
		var k: float = after / 0.6
		var color: Color = EMBER_COLOR if forge else _enemy.data.body_color.lightened(0.4)
		draw_arc(Vector2(0, 2), 12.0 + 90.0 * k, 0.0, TAU, 40, Color(color, 1.0 - k), 3.0 if forge else 2.0)
		if forge:
			draw_arc(Vector2(0, 2), 8.0 + 60.0 * k, 0.0, TAU, 32, Color(CORE_COLOR, (1.0 - k) * 0.7), 1.0)


func _draw_emerge() -> void:
	var grow: float = clampf(_time / CRACK_TIME, 0.0, 1.0)
	# Las grietas se apagan cuando ya salió.
	var fade: float = 1.0 - clampf((_time - 2.2) / 0.7, 0.0, 1.0)
	var glow: float = (0.6 + 0.4 * sin(_time * 18.0)) * fade
	for i: int in 7:
		var direction := Vector2.from_angle(TAU * i / 7.0 + 0.4)
		var side: Vector2 = direction.orthogonal()
		var points := PackedVector2Array([Vector2(0, 4)])
		var length: float = 52.0 * grow
		var steps: int = 6
		for s: int in range(1, steps + 1):
			var along: float = length * s / steps
			points.append(Vector2(0, 4) + direction * along + side * (2.0 if s % 2 == 0 else -2.0))
		draw_polyline(points, Color(ROOT_COLOR.darkened(0.6), 0.6 * fade), 3.0)
		draw_polyline(points, Color(ROOT_COLOR, glow), 1.0)
	if _time < CRACK_TIME:
		return
	var after: float = _time - CRACK_TIME
	# Raíces que revientan alrededor y se vuelven a hundir.
	var height: float = 24.0 * sin(PI * clampf(after / 0.9, 0.0, 1.0))
	if height > 0.5:
		for i: int in 6:
			var at: Vector2 = Vector2.from_angle(TAU * i / 6.0 + 0.2) * 24.0 + Vector2(0, 4)
			var spike := PackedVector2Array([at + Vector2(-4, 2), at + Vector2(1, -height), at + Vector2(4, 2)])
			draw_colored_polygon(spike, ROOT_COLOR.darkened(0.25))
			draw_line(at + Vector2(1, -height), at + Vector2(-1, 1), ROOT_COLOR.lightened(0.3), 1.0)
	# La tierra que levanta al salir, delante de sus pies.
	var mound: float = 1.0 - clampf(after / (RISE_TIME + 0.4), 0.0, 1.0)
	if mound > 0.0:
		draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, _radius() * 1.4 * (0.5 + 0.5 * mound) + 1.0, Color("1b1420"))
		draw_circle(Vector2.ZERO, _radius() * 1.4 * (0.5 + 0.5 * mound), DIRT_COLOR)
		draw_set_transform(Vector2.ZERO)
		for pebble: Vector2 in [Vector2(-8, 3), Vector2(5, 4), Vector2(-2, 6), Vector2(9, 2)]:
			draw_rect(Rect2(pebble, Vector2.ONE), DIRT_COLOR.lightened(0.4))


## Dos ojos rojos que brillan (en la oscuridad) entre `from` y `to` segundos; parpadean una vez.
func _draw_eyes(from: float, to: float) -> void:
	if _time < from or _time >= to or (_time > from + 0.5 and _time < from + 0.62):
		return
	var r: float = _radius()
	var pulse: float = 0.7 + 0.3 * sin(_time * 8.0)
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(side * r * 0.4, -r * 0.2 - 2.0)
		draw_circle(eye, 4.0, Color(EYE_COLOR, 0.25 * pulse))
		draw_rect(Rect2(eye - Vector2(1.5, 1), Vector2(3, 2)), Color(EYE_COLOR, pulse))


func _draw_stomp_rings() -> void:
	for at: float in [1.0, 1.5]:
		var k: float = (_time - at) / 0.45
		if k >= 0.0 and k < 1.0:
			draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, 10.0 + 60.0 * k, 0.0, TAU, 32, Color(0.75, 0.7, 0.75, 1.0 - k), 2.0)
			draw_set_transform(Vector2.ZERO)
	if _time >= 2.0 and _time < 2.4:
		var spark: float = 1.0 - (_time - 2.0) / 0.4
		var at := Vector2(0, -_radius() * 1.15 - 2.0)
		draw_line(at + Vector2(-4, 0) * spark, at + Vector2(4, 0) * spark, Color(CORE_COLOR, spark), 1.0)
		draw_line(at + Vector2(0, -4) * spark, at + Vector2(0, 4) * spark, Color(CORE_COLOR, spark), 1.0)


func _draw_spin() -> void:
	var k: float = clampf(_time / SPIN_TIME, 0.0, 1.0)
	if k < 1.0:
		for i: int in 4:
			var y: float = -10.0 + i * 6.0
			draw_line(Vector2(-6.0 - 30.0 * (1.0 - k), y), Vector2(-8.0, y), Color(WIND_COLOR, 0.5 * (1.0 - k)), 1.0)
	for at: float in [1.4, 1.75]:
		var t: float = (_time - at) / 0.2
		if t >= 0.0 and t < 1.0:
			var fade: float = 1.0 - t
			draw_line(Vector2(-14, -14), Vector2(14, 10), Color(CORE_COLOR, fade), 2.0)
			draw_line(Vector2(14, -14), Vector2(-14, 10), Color(CORE_COLOR, fade), 2.0)


func _draw_shadow() -> void:
	var gather: float = clampf(_time / 1.7, 0.0, 1.0)
	if gather >= 1.0:
		return
	for i: int in 14:
		var angle: float = TAU * i / 14.0 + _time * 0.8
		var distance: float = 90.0 * (1.0 - gather) + 6.0
		var at: Vector2 = Vector2.from_angle(angle) * distance + Vector2(0, -2)
		var size: float = 3.0 + 1.5 * sin(_time * 6.0 + i)
		draw_circle(at, size, SHADOW_COLOR)
		draw_circle(at - Vector2.from_angle(angle) * 3.0, size * 0.6, Color(SHADOW_COLOR, 0.4))


func _draw_snowfall() -> void:
	var fade: float = 1.0 - clampf((_time - 2.2) / 0.6, 0.0, 1.0)
	if fade <= 0.0:
		return
	for i: int in 40:
		var x: float = fmod(i * 97.3, 260.0) - 130.0
		var speed: float = 55.0 + (i % 5) * 14.0
		var y: float = fmod(_time * speed + i * 37.0, 170.0) - 110.0
		var drift: float = sin(_time * 2.0 + i) * 2.0
		draw_rect(Rect2(Vector2(x + drift, y).round(), Vector2(2, 2) if i % 3 == 0 else Vector2.ONE), Color(SNOW_COLOR, 0.85 * fade))


func _draw_gather() -> void:
	var build: float = clampf(_time / 1.8, 0.0, 1.0)
	var fade: float = 1.0 - clampf((_time - 1.8) / 0.6, 0.0, 1.0)
	if fade > 0.0:
		for arm: int in 6:
			var points := PackedVector2Array()
			for k: int in 12:
				var angle: float = -_time * 3.0 + TAU * arm / 6.0 + k * 0.35
				points.append(Vector2.from_angle(angle) * 110.0 * (1.0 - k / 12.0) * (1.0 - 0.3 * build))
			draw_polyline(points, Color(WIND_COLOR, (0.15 + 0.35 * build) * fade), 1.0)
		for i: int in 16:
			var pull: float = fmod(_time * 0.7 + i / 16.0, 1.0)
			var at: Vector2 = Vector2.from_angle(TAU * i / 16.0 + _time) * 100.0 * (1.0 - pull)
			draw_rect(Rect2(at.round(), Vector2.ONE), Color(SNOW_COLOR, fade))
	var bolt: float = (_time - 1.8) / 0.2
	if bolt >= 0.0 and bolt < 1.0:
		var points := PackedVector2Array()
		var y: float = -140.0
		var i: int = 0
		while y < -4.0:
			points.append(Vector2(0.0 if i == 0 else (5.0 if i % 2 == 0 else -5.0), y))
			y += 14.0
			i += 1
		points.append(Vector2(0, -4))
		draw_polyline(points, Color(BOLT_COLOR, 1.0 - bolt), 3.0)
		draw_polyline(points, Color(CORE_COLOR, 1.0 - bolt), 1.0)


func _draw_chimney() -> void:
	var pour: float = 1.0 - clampf((_time - SOOT_TIME + 0.2) / 0.4, 0.0, 1.0)
	if pour > 0.0:
		# La columna de hollín que cae desde arriba.
		for i: int in 34:
			var x: float = (fmod(i * 7.3, 14.0) - 7.0) * (0.6 + 0.4 * pour)
			var y: float = fmod(_time * (120.0 + (i % 5) * 18.0) + i * 23.0, 150.0) - 146.0
			var flake: Color = ASH_COLOR if i % 2 == 0 else SOOT_COLOR
			draw_rect(Rect2(Vector2(x, y).round(), Vector2(2, 2) if i % 3 == 0 else Vector2.ONE), Color(flake, 0.9 * pour))
	# La pila que crece al pie y se deshace cuando sale.
	var pile: float = clampf(_time / SOOT_TIME, 0.0, 1.0)
	if _time > SOOT_TIME:
		pile = 1.0 - clampf((_time - SOOT_TIME) / 0.9, 0.0, 1.0)
	if pile > 0.0:
		draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, _radius() * 1.2 * pile + 1.0, Color("120c16"))
		draw_circle(Vector2.ZERO, _radius() * 1.2 * pile, ASH_COLOR.darkened(0.35))
		draw_circle(Vector2(-2, -3), _radius() * 0.7 * pile, ASH_COLOR)
		draw_set_transform(Vector2.ZERO)
