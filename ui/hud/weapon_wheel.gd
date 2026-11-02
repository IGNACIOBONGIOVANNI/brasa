class_name WeaponWheel
extends Control
## Rueda de armas: manteniendo el botón de cambiar de arma (Tab o LB) se abre en el medio de la
## pantalla y el juego se pausa. Se marca un arma apuntando hacia ella (con el mouse desde el medio, o
## con un stick) y al soltar el botón se equipa. Cada arma muestra su número (las teclas 1 a 9 la
## equipan directo, sin abrir la rueda) y abajo sale el nombre y la munición de la marcada. Esc la
## cierra sin cambiar nada.

const RADIUS: float = 32.0
const BACK_RADIUS: float = 46.0
const SLOT_RADIUS: float = 9.0
## Distancia mínima del mouse al medio para marcar (si no, queda la que estaba).
const MOUSE_DEADZONE: float = 8.0
const STICK_DEADZONE: float = 0.4
const BACK_COLOR: Color = Color(0.05, 0.04, 0.07, 0.82)
const RING_COLOR: Color = Color("4b4357")
const MARK_COLOR: Color = Color("ffd166")
const TEXT_COLOR: Color = Color("f2efe6")
const OUTLINE_COLOR: Color = Color("120c16")

var _open: bool = false
var _choice: int = -1
var _info: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_info = MenuBuilder.label("", 8)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_info)


func is_open() -> bool:
	return _open


## Abre la rueda (si hay más de un arma y nada más pausó el juego).
func open() -> void:
	if _open or get_tree().paused or RunState.weapons.size() < 2:
		return
	_open = true
	_choice = RunState.current_weapon
	visible = true
	get_tree().paused = true
	AudioManager.play_sfx(&"ui_select")
	_refresh_info()
	queue_redraw()


## La que está marcada ahora (-1 si está cerrada).
func choice() -> int:
	return _choice if _open else -1


## Marca el arma más cercana a la dirección `direction` (desde el medio).
func point_at(direction: Vector2) -> void:
	var count: int = RunState.weapons.size()
	if direction == Vector2.ZERO or count == 0:
		return
	var best: int = _choice
	var best_dot: float = -INF
	for i: int in count:
		var dot: float = slot_direction(i, count).dot(direction.normalized())
		if dot > best_dot:
			best_dot = dot
			best = i
	if best != _choice:
		_choice = best
		_refresh_info()
		queue_redraw()


## Cierra la rueda; con `apply`, equipa la marcada.
func close(apply: bool) -> void:
	if not _open:
		return
	_open = false
	visible = false
	get_tree().paused = false
	if apply and RunState.select_weapon(_choice):
		AudioManager.play_sfx(&"weapon_swap")
	_choice = -1


## Hacia dónde queda el arma `index` de `count` (la primera arriba, en el sentido del reloj).
static func slot_direction(index: int, count: int) -> Vector2:
	return Vector2.from_angle(-PI * 0.5 + TAU * index / maxi(1, count))


func _process(_delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed(&"pause"):
		close(false)
		return
	var stick: Vector2 = Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	if stick.length() < STICK_DEADZONE:
		stick = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if stick.length() >= STICK_DEADZONE:
		point_at(stick)
	else:
		var mouse: Vector2 = get_local_mouse_position() - size * 0.5
		if mouse.length() >= MOUSE_DEADZONE:
			point_at(mouse)
	if not Input.is_action_pressed(&"swap_weapon"):
		close(true)


func _refresh_info() -> void:
	if _choice < 0 or _choice >= RunState.weapons.size():
		_info.text = ""
		return
	var slot: WeaponSlot = RunState.weapons[_choice]
	var ammo: String = "sin límite" if slot.is_infinite() else ("%d / %d" % [slot.loaded(), slot.reserve] if slot.has_magazine() else str(slot.loaded()))
	_info.text = "%d · %s · %s" % [_choice + 1, slot.weapon.display_name, ammo]
	_info.position = Vector2(size.x * 0.5 - 80.0, size.y * 0.5 + BACK_RADIUS + 2.0)
	_info.size = Vector2(160.0, 10.0)


func _draw() -> void:
	if not _open:
		return
	var center: Vector2 = (size * 0.5).round()
	draw_circle(center, BACK_RADIUS, BACK_COLOR)
	draw_arc(center, RADIUS, 0.0, TAU, 32, RING_COLOR, 1.0)
	var count: int = RunState.weapons.size()
	for i: int in count:
		var slot: WeaponSlot = RunState.weapons[i]
		var at: Vector2 = (center + slot_direction(i, count) * RADIUS).round()
		var marked: bool = i == _choice
		draw_circle(at, SLOT_RADIUS, OUTLINE_COLOR)
		if marked:
			draw_arc(at, SLOT_RADIUS, 0.0, TAU, 16, MARK_COLOR, 1.0)
		var icon: PackedStringArray = slot.weapon.display_icon()
		var icon_size: Vector2 = PixelIcons.size_of(icon)
		var color: Color = slot.weapon.icon_color if not slot.is_empty() else slot.weapon.icon_color.darkened(0.5)
		PixelBitmap.paint_outlined(self, icon, (at - icon_size * 0.5).round(), color, OUTLINE_COLOR)
		if i < 9:
			PixelIcons.paint_number(self, i + 1, 1, at + Vector2(-SLOT_RADIUS, -SLOT_RADIUS - 2.0),
					MARK_COLOR if marked else TEXT_COLOR, OUTLINE_COLOR)
	if _choice >= 0:
		draw_line(center, (center + slot_direction(_choice, count) * (RADIUS - SLOT_RADIUS - 2.0)).round(), MARK_COLOR, 1.0)
