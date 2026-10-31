extends Node
## Herramientas de debug, solo en builds debug.
## F1: overlay con FPS, seed y cantidad de balas.
## F2: muestra las formas de colisión (cuerpos, hurtboxes en verde, hitboxes en rojo).
## F3: menú de desarrollo con los comandos que registra la escena actual (pausa el juego).
## Argumentos de usuario (después de "--"): --debug-overlay muestra el overlay al arrancar,
## --demo-input simula input (ver DemoInput) para capturas y corridas automáticas, y
## --quit-frames=N cierra el juego prolijo (Main.quit_game) a los N frames. Usar este y no el
## --quit-after de Godot, que sale de golpe y deja avisos de audio sin liberar.

const OVERLAY_LAYER: int = 100
const FONT_SIZE: int = 8
const QUIT_FRAMES_PREFIX: String = "--quit-frames="


## Comando del menú F3. Se descarta solo cuando su dueño sale del árbol.
class DevCommand:
	var owner_node: Node
	var label: String
	var action: Callable


var _layer: CanvasLayer
var _label: Label
var _menu_layer: CanvasLayer
var _menu_list: VBoxContainer
var _commands: Array[DevCommand] = []
## Frame en el que se cierra el juego (--quit-frames). -1 = nunca.
var _quit_at_frame: int = -1


func _ready() -> void:
	if not OS.is_debug_build():
		set_process(false)
		set_process_unhandled_input(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_build_menu()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_layer.visible = "--debug-overlay" in args
	if "--demo-input" in args:
		add_child(DemoInput.new())
	for arg: String in args:
		if arg.begins_with(QUIT_FRAMES_PREFIX) and arg.trim_prefix(QUIT_FRAMES_PREFIX).is_valid_int():
			_quit_at_frame = arg.trim_prefix(QUIT_FRAMES_PREFIX).to_int()


## Agrega un comando al menú F3 mientras `owner_node` siga en el árbol.
func add_command(owner_node: Node, label: String, action: Callable) -> void:
	var command := DevCommand.new()
	command.owner_node = owner_node
	command.label = label
	command.action = action
	_commands.append(command)


func is_menu_open() -> bool:
	return _menu_layer != null and _menu_layer.visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		_layer.visible = not _layer.visible
	elif event.is_action_pressed(&"debug_hitboxes"):
		_toggle_hitboxes()
	elif event.is_action_pressed(&"debug_menu"):
		_set_menu_open(not is_menu_open())
	elif is_menu_open() and event.is_action_pressed(&"ui_cancel"):
		_set_menu_open(false)
	else:
		return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _quit_at_frame >= 0 and Engine.get_process_frames() >= _quit_at_frame:
		_quit_at_frame = -1
		_quit_game()
	if not _layer.visible:
		return
	_label.text = "FPS %d\nseed %d\nbalas %d" % [
		Engine.get_frames_per_second(),
		GameRNG.get_run_seed(),
		get_tree().get_node_count_in_group(Bullet.GROUP),
	]


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = OVERLAY_LAYER
	add_child(_layer)
	_label = Label.new()
	_style_label(_label)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.position = Vector2(-4, 2)
	_layer.add_child(_label)


func _build_menu() -> void:
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = OVERLAY_LAYER + 1
	_menu_layer.visible = false
	add_child(_menu_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_menu_layer.add_child(panel)
	_menu_list = VBoxContainer.new()
	_menu_list.add_theme_constant_override(&"separation", 1)
	panel.add_child(_menu_list)


func _set_menu_open(open: bool) -> void:
	_menu_layer.visible = open
	get_tree().paused = open
	if open:
		_fill_menu()


func _fill_menu() -> void:
	for child: Node in _menu_list.get_children():
		child.queue_free()
	var alive: Array[DevCommand] = []
	for command: DevCommand in _commands:
		if is_instance_valid(command.owner_node) and command.owner_node.is_inside_tree():
			alive.append(command)
	_commands = alive
	var title := Label.new()
	title.text = "Menú dev (F3 o Esc cierra)"
	_style_label(title)
	_menu_list.add_child(title)
	var first: Button = null
	for command: DevCommand in _commands:
		var button := _add_button(command.label)
		button.pressed.connect(_run_command.bind(command))
		if first == null:
			first = button
	var close := _add_button("Cerrar")
	close.pressed.connect(_set_menu_open.bind(false))
	(first if first != null else close).grab_focus.call_deferred()


func _add_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override(&"font_size", FONT_SIZE)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_menu_list.add_child(button)
	return button


func _run_command(command: DevCommand) -> void:
	_set_menu_open(false)
	if is_instance_valid(command.owner_node):
		command.action.call()


func _quit_game() -> void:
	var main := get_tree().current_scene as Main
	if main != null:
		main.quit_game()
	else:
		get_tree().quit()


## Prende o apaga el dibujo de las formas de colisión de toda la escena.
func _toggle_hitboxes() -> void:
	var tree: SceneTree = get_tree()
	tree.debug_collisions_hint = not tree.debug_collisions_hint
	_redraw_shapes(tree.root)


func _redraw_shapes(node: Node) -> void:
	if node is CollisionShape2D or node is CollisionPolygon2D:
		(node as CanvasItem).queue_redraw()
	for child: Node in node.get_children():
		_redraw_shapes(child)


func _style_label(label: Label) -> void:
	label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	label.add_theme_constant_override(&"outline_size", 2)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
