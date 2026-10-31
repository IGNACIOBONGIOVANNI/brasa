class_name ItemBanner
extends Control
## Cartel que aparece arriba con un título y un subtítulo y se desvanece: el item que se agarró, el
## jefe que aparece o el piso que empieza (con su línea de historia, que se queda más tiempo).

const SHOW_TIME: float = 2.2
const LONG_SHOW_TIME: float = 3.6
const FADE_TIME: float = 0.5
const FONT_SIZE: int = 8
const TITLE_COLOR: Color = Color("f2efe6")
const TEXT_COLOR: Color = Color("b8b0c8")

var _left: float = 0.0
var _title: Label
var _description: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override(&"separation", 0)
	add_child(box)
	_title = _make_label(TITLE_COLOR)
	_description = _make_label(TEXT_COLOR)
	box.add_child(_title)
	box.add_child(_description)
	modulate.a = 0.0


## El nombre lleva la calidad y sale de su color.
func show_item(item: ItemData) -> void:
	show_text("%s · %s" % [item.display_name, item.quality_name()], item.description, SHOW_TIME,
			item.quality_color())


## También sirve para el título de cada piso y el de los jefes.
func show_text(title: String, subtitle: String, seconds: float = SHOW_TIME,
		title_color: Color = TITLE_COLOR) -> void:
	_title.text = title
	_title.add_theme_color_override(&"font_color", title_color)
	_description.text = subtitle
	_left = seconds + FADE_TIME
	modulate.a = 1.0


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(0.0, _left - delta)
	modulate.a = clampf(_left / FADE_TIME, 0.0, 1.0)


func _make_label(color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_constant_override(&"outline_size", 2)
	label.add_theme_color_override(&"font_outline_color", Color("120c16"))
	return label
