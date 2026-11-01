class_name RuleDisplay
extends Control
## Arriba, en el medio: la regla de la sala mientras dura el combate (con Contrarreloj, los segundos
## que quedan para el premio extra; si se acaban, en gris).

const FONT_SIZE: int = 8
const SPENT_COLOR: Color = Color("6f687a")

var _rule: RoomRule
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_label.add_theme_constant_override(&"outline_size", 2)
	_label.add_theme_color_override(&"font_outline_color", Color("120c16"))
	add_child(_label)
	visible = false


## null la esconde.
func set_rule(rule: RoomRule) -> void:
	_rule = rule
	visible = rule != null
	set_time_left(INF)


func set_time_left(seconds: float) -> void:
	if _rule == null:
		return
	var color: Color = _rule.color
	var text: String = _rule.display_name
	if not is_inf(seconds):
		if seconds > 0.0:
			text = "%s · %d s" % [text, ceili(seconds)]
		else:
			text = "%s · sin premio" % text
			color = SPENT_COLOR
	_label.text = text
	_label.add_theme_color_override(&"font_color", color)


func shown_text() -> String:
	return _label.text if visible else ""
