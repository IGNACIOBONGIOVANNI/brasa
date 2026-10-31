class_name MenuBuilder
extends RefCounted
## Atajos para armar los menús placeholder por código (todos usan ui/theme/ui_theme.tres).

const TITLE_COLOR: Color = Color("e8c170")
const MUTED_COLOR: Color = Color("9a93a6")
const OUTLINE_COLOR: Color = Color("120c16")
## Color de las chispas (moneda de la meta-progresión).
const SPARK_COLOR: Color = Color("ffb35c")
const BACKGROUND_COLOR: Color = Color(0.06, 0.05, 0.08)


static func label(text: String, font_size: int = 8, color: Color = Color("f2efe6")) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override(&"font_size", font_size)
	result.add_theme_color_override(&"font_color", color)
	result.add_theme_constant_override(&"outline_size", 2)
	result.add_theme_color_override(&"font_outline_color", OUTLINE_COLOR)
	return result


## Texto alineado a la izquierda que corta líneas en `width` píxeles.
static func paragraph(text: String, width: float, color: Color = Color("f2efe6")) -> Label:
	var result: Label = label(text, 8, color)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size = Vector2(width, 0)
	return result


static func sparks_text(amount: int) -> String:
	return "%d chispa%s" % [amount, "" if amount == 1 else "s"]


## Fondo liso que ocupa toda la pantalla (los menús que no van encima del juego).
static func background(parent: Control) -> void:
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rect := ColorRect.new()
	rect.color = BACKGROUND_COLOR
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(rect)


## Botón que suena al apretarlo y llama a `action`.
static func button(text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.pressed.connect(func() -> void:
		AudioManager.play_sfx(&"ui_select")
		action.call())
	return result


## Caja vertical centrada en `parent` (que ocupa toda la pantalla), dentro de un panel si `panel`.
static func centered_box(parent: Control, panel: bool) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 3)
	if panel:
		var frame := PanelContainer.new()
		center.add_child(frame)
		frame.add_child(box)
	else:
		center.add_child(box)
	return box


## Le da el foco a `control` al final del frame, si para entonces sigue en pantalla (un menú puede
## reemplazarse antes de que llegue el foco).
## Se guarda el id y no el nodo: si el nodo se libera antes, capturarlo da error.
static func focus_later(control: Control) -> void:
	var id: int = control.get_instance_id()
	var grab: Callable = func() -> void:
		var target := instance_from_id(id) as Control
		if target != null and target.is_inside_tree():
			target.grab_focus()
	grab.call_deferred()
