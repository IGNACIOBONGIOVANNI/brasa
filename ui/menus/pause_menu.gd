class_name PauseMenu
extends CanvasLayer
## Pausa (Esc / Start): congela el juego y ofrece seguir, ver la Mochila, guardar y volver al menú,
## abandonar la run (pide confirmación: hay que apretarlo dos veces) o guardar y salir del juego.
## No se abre si el juego ya está pausado por otra cosa (transición de sala, menú de debug).

signal inventory_requested
signal menu_requested
signal abandon_requested
signal quit_requested

const DIM: Color = Color(0, 0, 0, 0.55)
const ABANDON_TEXT: String = "Abandonar la run"
const ABANDON_CONFIRM_TEXT: String = "¿Seguro? Se pierde la run"

var _continue: Button
var _abandon: Button


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var box: VBoxContainer = MenuBuilder.centered_box(root, true)
	box.add_child(MenuBuilder.label("Pausa", 16, MenuBuilder.TITLE_COLOR))
	_continue = MenuBuilder.button("Continuar", close)
	box.add_child(_continue)
	box.add_child(MenuBuilder.button("Mochila", inventory_requested.emit))
	box.add_child(MenuBuilder.button("Guardar y volver al menú", menu_requested.emit))
	_abandon = MenuBuilder.button(ABANDON_TEXT, _on_abandon_pressed)
	_abandon.focus_exited.connect(_cancel_abandon)
	box.add_child(_abandon)
	box.add_child(MenuBuilder.button("Guardar y salir del juego", quit_requested.emit))
	visible = false


func is_open() -> bool:
	return visible


func open() -> void:
	if visible or get_tree().paused:
		return
	visible = true
	get_tree().paused = true
	AudioManager.play_sfx(&"pause")
	MenuBuilder.focus_later(_continue)


func close() -> void:
	if not visible:
		return
	_cancel_abandon()
	visible = false
	get_tree().paused = false


## true si "Abandonar" está esperando la confirmación.
func is_confirming_abandon() -> bool:
	return _abandon.text == ABANDON_CONFIRM_TEXT


## La primera vez pregunta; la segunda abandona.
func _on_abandon_pressed() -> void:
	if is_confirming_abandon():
		abandon_requested.emit()
	else:
		_abandon.text = ABANDON_CONFIRM_TEXT


func _cancel_abandon() -> void:
	_abandon.text = ABANDON_TEXT


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if visible:
		close()
	elif not get_tree().paused:
		open()
	else:
		return
	get_viewport().set_input_as_handled()
