class_name MainMenu
extends Control
## Menú principal: título, la partida abierta con su progreso y sus chispas, Jugar (lleva a elegir
## personaje), Taller, Logros, Opciones y Cambiar partida (si hay partidas) de a dos, Salir y un
## recordatorio de los controles.

signal play_requested
signal workshop_requested
signal achievements_requested
signal options_requested
signal change_slot_requested
signal quit_requested

const CONTROLS: String = "WASD mover · mouse apuntar · click disparar · espacio rodar\nE bomba (mantené para tirarla) · F Pulso · Q activo · R recargar\nTab cambiar arma · I mochila · Esc pausa"
## Tamaño de la ayuda de controles (más chica que los botones: son tres líneas).
const CONTROLS_FONT: int = 7
## Alto que ocupa la ayuda de controles abajo: los botones se centran en lo que queda arriba.
const CONTROLS_HEIGHT: float = 34.0
## Ancho de cada botón de la grilla (los dos de una fila iguales).
const GRID_BUTTON_WIDTH: float = 80.0

var _play: Button
var _slot: Label
var _sparks: Label


func _ready() -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, false)
	(box.get_parent() as Control).offset_bottom = -CONTROLS_HEIGHT
	box.add_child(MenuBuilder.label(MenuBuilder.GAME_TITLE, 16, MenuBuilder.TITLE_COLOR))
	var status := HBoxContainer.new()
	status.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	status.add_theme_constant_override(&"separation", 3)
	_slot = MenuBuilder.label("", 8, MenuBuilder.MUTED_COLOR)
	_slot.visible = SaveManager.slot > 0
	status.add_child(_slot)
	_sparks = MenuBuilder.label("", 8, MenuBuilder.SPARK_COLOR)
	status.add_child(_sparks)
	box.add_child(status)
	_play = MenuBuilder.button("Jugar", play_requested.emit)
	box.add_child(_play)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 3)
	grid.add_theme_constant_override(&"v_separation", 3)
	var more: Array[Button] = [MenuBuilder.button("Taller", workshop_requested.emit),
			MenuBuilder.button("Logros", achievements_requested.emit), MenuBuilder.button("Opciones", options_requested.emit)]
	if SaveManager.has_slots():
		more.append(MenuBuilder.button("Cambiar partida", change_slot_requested.emit))
	for button: Button in more:
		button.custom_minimum_size = Vector2(GRID_BUTTON_WIDTH, 0)
		grid.add_child(button)
	box.add_child(grid)
	box.add_child(MenuBuilder.button("Salir", quit_requested.emit))
	var controls: Label = MenuBuilder.label(CONTROLS, CONTROLS_FONT, MenuBuilder.MUTED_COLOR)
	controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 4)
	controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
	controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(controls)
	SaveManager.profile_changed.connect(_refresh)
	_refresh()
	MenuBuilder.focus_later(_play)


func _refresh() -> void:
	_slot.text = "Partida %d · %d %% ·" % [SaveManager.slot, MetaRules.percent(SaveManager.completion())]
	_sparks.text = MenuBuilder.sparks_text(SaveManager.profile.sparks)
