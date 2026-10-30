extends Node
## Herramientas de debug, solo en builds debug.
## F1: overlay con FPS, seed y cantidad de balas.
## Argumentos de usuario (después de "--"): --debug-overlay lo muestra al arrancar,
## --demo-input simula input (ver DemoInput) para capturas y corridas automáticas.

const OVERLAY_LAYER: int = 100
const FONT_SIZE: int = 8

var _layer: CanvasLayer
var _label: Label


func _ready() -> void:
	if not OS.is_debug_build():
		set_process(false)
		set_process_unhandled_input(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_layer.visible = "--debug-overlay" in args
	if "--demo-input" in args:
		add_child(DemoInput.new())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		_layer.visible = not _layer.visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
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
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_label.add_theme_constant_override(&"outline_size", 2)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.position = Vector2(-4, 2)
	_layer.add_child(_label)
