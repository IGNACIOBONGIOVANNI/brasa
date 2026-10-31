class_name PauseMenu
extends CanvasLayer
## Pausa (Esc / Start): congela el juego y ofrece seguir, ver la Mochila, volver al menú o salir.
## No se abre si el juego ya está pausado por otra cosa (transición de sala, menú de debug).

signal inventory_requested
signal menu_requested
signal quit_requested

const DIM: Color = Color(0, 0, 0, 0.55)

var _continue: Button


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
	box.add_child(MenuBuilder.button("Volver al menú", menu_requested.emit))
	box.add_child(MenuBuilder.button("Salir del juego", quit_requested.emit))
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
	visible = false
	get_tree().paused = false


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
