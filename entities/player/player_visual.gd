@tool
class_name PlayerVisual
extends Node2D
## Placeholder del jugador dibujado por código: sombra, cuerpo, ojos y arma que sigue la mira (con
## el color y largo del arma equipada). Según el personaje (`look`) es la chispa o el carnero (lana,
## cara oscura y cuernos enrulados; al embestir baja la cabeza con los cuernos adelante). También dibuja el rol (bolita que gira, sin arma), la muerte
## (tirado, ojos en cruz), el escudo del Caparazón y, si maneja un armazón, el armazón con la chispa
## en la cabina (MechDrawing).
## Se reemplaza por un sprite animado manteniendo set_aim(), play_fire(), set_rolling(), set_dead(),
## set_gun(), set_body_color(), show_shield(), set_mech(), set_walking() y set_charging().

const FLASH_TIME: float = 0.05
const RECOIL_PIXELS: float = 2.0
## Píxeles por segundo que recupera el arma después del retroceso.
const RECOIL_RECOVERY: float = 20.0
## Radianes por segundo que gira la "bolita" al rodar.
const ROLL_SPIN_SPEED: float = 26.0
const SHIELD_COLOR: Color = Color("7ad1ff")
## Pasos por segundo de las patas del armazón.
const MECH_STEPS_PER_SECOND: float = 6.0
## El carnero: bollos de lana alrededor del cuerpo, cara y cuernos.
const WOOL_PUFFS: Array[Vector2] = [Vector2(-4, -1), Vector2(4, -1), Vector2(-3, -6), Vector2(3, -6),
		Vector2(-3, 2), Vector2(3, 2)]
const RAM_FACE_COLOR: Color = Color("4a3a2e")
const RAM_HORN_COLOR: Color = Color("c49a62")
const RAM_EYE_COLOR: Color = Color("f2efe6")

@export var body_color: Color = Color("e8c170")
@export var outline_color: Color = Color("1b1420")
@export var gun_color: Color = Color("8a8a9e")
@export var gun_length: float = 6.0
@export var flash_color: Color = Color("fff6d5")
@export var look: CharacterData.Look = CharacterData.Look.SPARK:
	set(value):
		look = value
		queue_redraw()

var aim_direction: Vector2 = Vector2.RIGHT
var _flash_left: float = 0.0
var _recoil: float = 0.0
var _rolling: bool = false
var _roll_spin: float = 0.0
var _dead: bool = false
var _shield_left: float = 0.0
var _time: float = 0.0
var _mech: MechData
var _mech_armor: float = 1.0
var _walking: bool = false
var _walk_time: float = 0.0
var _charging: bool = false
var _charge_direction: Vector2 = Vector2.RIGHT


## El color del personaje elegido.
func set_body_color(color: Color) -> void:
	body_color = color
	queue_redraw()


func set_gun(color: Color, length: float) -> void:
	gun_color = color
	gun_length = length
	queue_redraw()


## El armazón que maneja (null = a pie) y cuánto blindaje le queda (0 a 1).
func set_mech(mech: MechData, armor_fraction: float) -> void:
	_mech = mech
	_mech_armor = armor_fraction
	queue_redraw()


func set_walking(walking: bool) -> void:
	_walking = walking


func show_shield(seconds: float) -> void:
	_shield_left = seconds
	queue_redraw()


func set_aim(direction: Vector2) -> void:
	if direction != aim_direction:
		aim_direction = direction
		queue_redraw()


func play_fire() -> void:
	_flash_left = FLASH_TIME
	_recoil = RECOIL_PIXELS
	queue_redraw()


func set_rolling(rolling: bool) -> void:
	_rolling = rolling
	_roll_spin = 0.0
	queue_redraw()


## Embistiendo hacia `direction` (cabeza baja, cuernos adelante).
func set_charging(charging: bool, direction: Vector2) -> void:
	_charging = charging
	_charge_direction = direction
	queue_redraw()


func set_dead(dead: bool) -> void:
	_dead = dead
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _shield_left > 0.0:
		_shield_left = maxf(0.0, _shield_left - delta)
		queue_redraw()
	if _mech != null:
		if _walking:
			_walk_time += delta
		queue_redraw()
	if _rolling:
		_roll_spin += ROLL_SPIN_SPEED * delta
		queue_redraw()
	if _flash_left > 0.0 or _recoil > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
		_recoil = maxf(0.0, _recoil - RECOIL_RECOVERY * delta)
		queue_redraw()


func _draw() -> void:
	# Sombra achatada en los pies.
	draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	if _dead:
		_draw_dead()
	elif _mech != null:
		var step: int = int(_walk_time * MECH_STEPS_PER_SECOND) % 2 if _walking else -1
		MechDrawing.draw(self, _mech, aim_direction, step, body_color,
				gun_color, gun_length, _recoil, _mech_armor, _time)
	elif _charging:
		_draw_charging()
	elif _rolling:
		_draw_rolling()
	else:
		_draw_standing()
	if _shield_left > 0.0 and not _dead:
		# Parpadea el último segundo para avisar que se termina.
		var visible_now: bool = _shield_left > 1.0 or fmod(_time, 0.2) < 0.1
		if visible_now:
			draw_arc(Vector2(0, -2), 10.0 + sin(_time * 6.0), 0.0, TAU, 24, Color(SHIELD_COLOR, 0.8), 1.0)
			draw_circle(Vector2(0, -2), 10.0, Color(SHIELD_COLOR, 0.12))


func _draw_standing() -> void:
	# Si apunta hacia arriba, el arma queda detrás del cuerpo.
	var gun_behind: bool = aim_direction.y < -0.3
	if gun_behind:
		_draw_gun()
	if look == CharacterData.Look.RAM:
		_draw_ram(Vector2(0, -2), aim_direction, false)
	else:
		draw_circle(Vector2(0, -2), 6.0, outline_color)
		draw_circle(Vector2(0, -2), 5.0, body_color)
		var eyes: Vector2 = (aim_direction * 1.5).round()
		draw_rect(Rect2(Vector2(-3, -4) + eyes, Vector2(1, 2)), outline_color)
		draw_rect(Rect2(Vector2(1, -4) + eyes, Vector2(1, 2)), outline_color)
	if not gun_behind:
		_draw_gun()


## El carnero mirando hacia `facing`: lana, cara oscura con dos ojos y un cuerno enrulado a cada
## lado. `lowered`: la cabeza gacha de la embestida (la cara adelantada, los cuernos al frente).
func _draw_ram(center: Vector2, facing: Vector2, lowered: bool) -> void:
	for puff: Vector2 in WOOL_PUFFS:
		draw_circle(center + puff, 3.5, outline_color)
	draw_circle(center, 6.0, outline_color)
	for puff: Vector2 in WOOL_PUFFS:
		draw_circle(center + puff, 2.5, body_color)
	draw_circle(center, 5.0, body_color)
	var face: Vector2 = center + (facing * (4.0 if lowered else 2.0)).round() + Vector2(0, 1 if lowered else 0)
	var side: Vector2 = facing.orthogonal()
	for sign_x: float in [-1.0, 1.0]:
		var horn: Vector2 = (face + side * sign_x * 3.5 - facing * (0.0 if lowered else 1.5)).round()
		draw_arc(horn, 2.0, 0.0, TAU * 0.8, 8, outline_color, 2.0)
		draw_arc(horn, 2.0, 0.0, TAU * 0.8, 8, RAM_HORN_COLOR, 1.0)
	draw_circle(face, 2.6, outline_color)
	draw_circle(face, 2.0, RAM_FACE_COLOR)
	if facing.y > -0.5:
		for sign_x: float in [-1.0, 1.0]:
			draw_rect(Rect2((face + side * sign_x * 1.0 + Vector2(-0.5, -1.0)).round(), Vector2(1, 1)), RAM_EYE_COLOR)


## Embestida: el cuerpo inclinado hacia adelante (la chispa sin carnero, igual que rodar).
func _draw_charging() -> void:
	if look != CharacterData.Look.RAM:
		_draw_rolling()
		return
	_draw_ram((Vector2(0, -1) + _charge_direction * 1.5).round(), _charge_direction, true)


func _draw_gun() -> void:
	draw_set_transform(Vector2(0, -1), aim_direction.angle())
	var start: float = 4.0 - _recoil
	draw_rect(Rect2(start - 1.0, -2.0, gun_length + 2.0, 4.0), outline_color)
	draw_rect(Rect2(start, -1.0, gun_length, 2.0), gun_color)
	if _flash_left > 0.0:
		draw_circle(Vector2(start + gun_length + 2.0, 0.0), 2.5, flash_color)
	draw_set_transform(Vector2.ZERO)


func _draw_rolling() -> void:
	# Bolita más baja que el cuerpo normal, con una franja que gira.
	var center := Vector2(0, 0)
	draw_circle(center, 5.0, outline_color)
	draw_circle(center, 4.0, body_color)
	var band: Vector2 = Vector2.from_angle(_roll_spin) * 3.0
	draw_line(center - band, center + band, outline_color, 1.0)


func _draw_dead() -> void:
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.3, 0.6))
	draw_circle(Vector2.ZERO, 6.0, outline_color)
	draw_circle(Vector2.ZERO, 5.0, body_color.darkened(0.3))
	draw_set_transform(Vector2.ZERO)
	for eye_x: float in [-3.0, 2.0]:
		draw_line(Vector2(eye_x - 1, 0), Vector2(eye_x + 1, 2), outline_color, 1.0)
		draw_line(Vector2(eye_x - 1, 2), Vector2(eye_x + 1, 0), outline_color, 1.0)
