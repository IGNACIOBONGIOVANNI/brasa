class_name MainMenu
extends Control
## Menú principal: título, chispas, Jugar (lleva a elegir personaje), Taller, Logros, Opciones y
## Salir, y un recordatorio de los controles.

signal play_requested
signal workshop_requested
signal achievements_requested
signal options_requested
signal quit_requested

const CONTROLS: String = "WASD mover · mouse apuntar · click disparar · espacio rodar\nE bomba · F Pulso · Q activo · R recargar · Tab cambiar arma · Esc pausa"
## Alto que ocupa la ayuda de controles abajo: los botones se centran en lo que queda arriba.
const CONTROLS_HEIGHT: float = 28.0

var _play: Button
var _sparks: Label


func _ready() -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, false)
	(box.get_parent() as Control).offset_bottom = -CONTROLS_HEIGHT
	box.add_child(MenuBuilder.label(ProjectSettings.get_setting("application/config/name"), 16, MenuBuilder.TITLE_COLOR))
	_sparks = MenuBuilder.label("", 8, MenuBuilder.SPARK_COLOR)
	box.add_child(_sparks)
	_play = MenuBuilder.button("Jugar", play_requested.emit)
	box.add_child(_play)
	box.add_child(MenuBuilder.button("Taller", workshop_requested.emit))
	box.add_child(MenuBuilder.button("Logros", achievements_requested.emit))
	box.add_child(MenuBuilder.button("Opciones", options_requested.emit))
	box.add_child(MenuBuilder.button("Salir", quit_requested.emit))
	var controls: Label = MenuBuilder.label(CONTROLS, 8, MenuBuilder.MUTED_COLOR)
	controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 4)
	controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
	controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(controls)
	SaveManager.profile_changed.connect(_refresh)
	_refresh()
	MenuBuilder.focus_later(_play)


func _refresh() -> void:
	_sparks.text = MenuBuilder.sparks_text(SaveManager.profile.sparks)
