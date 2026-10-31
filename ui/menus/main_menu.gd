class_name MainMenu
extends Control
## Menú principal: título, Jugar y Salir, y un recordatorio de los controles.

signal play_requested
signal quit_requested

const BACKGROUND: Color = Color(0.06, 0.05, 0.08)
const CONTROLS: String = "WASD mover · mouse apuntar · click disparar · espacio rodar\nE bomba · F Pulso · Q activo · R recargar · Tab cambiar arma · Esc pausa"

var _play: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var box: VBoxContainer = MenuBuilder.centered_box(self, false)
	box.add_child(MenuBuilder.label(ProjectSettings.get_setting("application/config/name"), 16, MenuBuilder.TITLE_COLOR))
	box.add_child(MenuBuilder.label("un roguelite de salas", 8, MenuBuilder.MUTED_COLOR))
	box.add_child(Control.new())
	_play = MenuBuilder.button("Jugar", play_requested.emit)
	box.add_child(_play)
	box.add_child(MenuBuilder.button("Salir", quit_requested.emit))
	var controls: Label = MenuBuilder.label(CONTROLS, 8, MenuBuilder.MUTED_COLOR)
	controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 4)
	controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
	controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(controls)
	MenuBuilder.focus_later(_play)
