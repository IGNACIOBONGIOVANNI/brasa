class_name IntroScreen
extends Control
## Intro de la historia (ver docs/LORE.md): las líneas aparecen de a una sobre una brasa que titila.
## Aceptar (Enter, click, A) muestra la que sigue o, si ya están todas, termina; Esc la saltea.
## Main la muestra la primera vez que se aprieta Jugar y desde Opciones.

signal finished

const LINES: PackedStringArray = [
	"Debajo de Campana Honda ardía la Fragua Madre, el fuego que calentaba todas las casas.",
	"Un invierno la campana de la iglesia se desplomó al sótano y la fragua se apagó de golpe.",
	"El pueblo quedó frío y a oscuras.",
	"La última chispa de esa fragua tomó forma: Brasa. Baja a buscar lo que se quedó con el fuego.",
]
const TEXT_WIDTH: float = 230.0
## Segundos entre una línea y la siguiente si no se aprieta nada.
const LINE_DELAY: float = 2.6
const FADE_TIME: float = 0.6
const EMBER_SCALE: float = 3.0
const EMBER_COLORS: Array[Color] = [Color("ffb35c"), Color("ffd27a"), Color("e0643c")]

var _labels: Array[Label] = []
var _shown: int = 0
var _until_next: float = 0.0
var _done: bool = false
var _ember: Control
var _time: float = 0.0


func _ready() -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, false)
	box.add_theme_constant_override(&"separation", 6)
	_ember = Control.new()
	_ember.custom_minimum_size = Vector2(TEXT_WIDTH, 5 * EMBER_SCALE)
	_ember.draw.connect(_draw_ember)
	box.add_child(_ember)
	for line: String in LINES:
		var label: Label = MenuBuilder.paragraph(line, TEXT_WIDTH)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.modulate.a = 0.0
		box.add_child(label)
		_labels.append(label)
	var hint: Label = MenuBuilder.label("Enter: seguir · Esc: saltear", 7, MenuBuilder.MUTED_COLOR)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 4)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(hint)
	advance()


func lines_shown() -> int:
	return _shown


## Muestra la línea que sigue o, si ya están todas, termina.
func advance() -> void:
	if _shown >= _labels.size():
		_finish()
		return
	var label: Label = _labels[_shown]
	create_tween().tween_property(label, ^"modulate:a", 1.0, FADE_TIME)
	_shown += 1
	_until_next = LINE_DELAY


func skip() -> void:
	_finish()


func _process(delta: float) -> void:
	_time += delta
	_ember.queue_redraw()
	if _shown < _labels.size():
		_until_next -= delta
		if _until_next <= 0.0:
			advance()


## La tecla se marca como usada antes de actuar: al terminar, Main cambia de pantalla y la intro ya
## no está en el árbol (get_viewport() daría null).
func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		skip()
	elif event.is_action_pressed(&"ui_accept") or (click != null and click.pressed):
		get_viewport().set_input_as_handled()
		AudioManager.play_sfx(&"ui_select")
		advance()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


## Una brasa de píxeles en forma de rombo que cambia de color.
func _draw_ember() -> void:
	var color: Color = EMBER_COLORS[int(_time * 6.0) % EMBER_COLORS.size()]
	var center := Vector2(_ember.size.x / 2.0, _ember.size.y / 2.0)
	for cell: Vector2 in [Vector2(0, -2), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-2, 0),
			Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(-1, 1), Vector2(0, 1),
			Vector2(1, 1), Vector2(0, 2)]:
		var core: bool = absf(cell.x) + absf(cell.y) <= 1.0
		_ember.draw_rect(Rect2(center + (cell - Vector2(0.5, 0.5)) * EMBER_SCALE, Vector2.ONE * EMBER_SCALE),
				Color("fff6d5") if core and int(_time * 6.0) % 2 == 0 else color)
