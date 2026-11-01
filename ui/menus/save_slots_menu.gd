class_name SaveSlotsMenu
extends Control
## Pantalla de partidas (lo primero que se ve): los cuatro espacios de guardado, cada uno con su
## progreso de 0 a 100 % (MetaRules.completion), runs y victorias, o "vacía". Elegir una la abre (una
## vacía empieza de cero); "Borrar" pide confirmación. Arranca con el foco en la última partida
## abierta. Salir cierra el juego.

signal slot_chosen(slot: int)
signal quit_requested

const NAME_WIDTH: float = 70.0
## Lo que va al lado del nombre (progreso y Borrar, o la pregunta): fijo, así la pantalla no cambia de
## ancho al preguntar.
const SIDE_WIDTH: float = 180.0

var _list: VBoxContainer
var _slot_buttons: Array[Button] = []
## Partida que se está por borrar (pidiendo confirmación); 0 = ninguna.
var _confirming: int = 0
var _confirm_button: Button


func _ready() -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, true)
	box.add_child(MenuBuilder.label("Partidas", 16, MenuBuilder.TITLE_COLOR))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 4)
	box.add_child(_list)
	var quit: Button = MenuBuilder.button("Salir", quit_requested.emit)
	quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(quit)
	_refresh()
	MenuBuilder.focus_later(button_for(SaveManager.last_slot()))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _confirming > 0:
		get_viewport().set_input_as_handled()
		cancel_delete()


## El botón que abre la partida `slot`.
func button_for(slot: int) -> Button:
	return _slot_buttons[slot - 1]


## Pide confirmación para borrar la partida `slot` (la fila pasa a preguntar).
func ask_delete(slot: int) -> void:
	_confirming = slot
	_refresh()
	MenuBuilder.focus_later(_confirm_button)


func confirm_delete() -> void:
	var slot: int = _confirming
	_confirming = 0
	SaveManager.delete_slot(slot)
	_refresh()
	MenuBuilder.focus_later(button_for(slot))


func cancel_delete() -> void:
	var slot: int = _confirming
	_confirming = 0
	_refresh()
	MenuBuilder.focus_later(button_for(slot))


## Texto de la fila de una partida (lo usan los tests).
static func detail_text(info: SaveSlots.Info) -> String:
	if not info.used:
		return "vacía"
	return "%d %% · %d run%s · %d victoria%s" % [MetaRules.percent(info.completion), info.runs,
			"" if info.runs == 1 else "s", info.wins, "" if info.wins == 1 else "s"]


func _refresh() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_slot_buttons.clear()
	for slot: int in range(1, SaveSlots.COUNT + 1):
		_list.add_child(_row(slot))


func _row(slot: int) -> Control:
	var info: SaveSlots.Info = SaveManager.slot_info(slot)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	var open: Button = MenuBuilder.button("Partida %d" % slot, slot_chosen.emit.bind(slot))
	open.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	row.add_child(open)
	_slot_buttons.append(open)
	var side := HBoxContainer.new()
	side.custom_minimum_size = Vector2(SIDE_WIDTH, 0)
	side.add_theme_constant_override(&"separation", 6)
	row.add_child(side)
	if slot == _confirming:
		var question: Label = MenuBuilder.label("¿Borrarla?", 8, MenuBuilder.MUTED_COLOR)
		question.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		side.add_child(question)
		_confirm_button = MenuBuilder.button("Sí, borrar", confirm_delete)
		side.add_child(_confirm_button)
		side.add_child(MenuBuilder.button("No", cancel_delete))
		return row
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail.add_theme_constant_override(&"separation", 2)
	var meter := ProgressMeter.new()
	meter.value = info.completion
	meter.visible = info.used
	detail.add_child(meter)
	var text: Label = MenuBuilder.label(detail_text(info), 7, Color("f2efe6") if info.used else MenuBuilder.MUTED_COLOR)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail.add_child(text)
	side.add_child(detail)
	var delete: Button = MenuBuilder.button("Borrar", ask_delete.bind(slot))
	delete.disabled = not info.used
	side.add_child(delete)
	return row
