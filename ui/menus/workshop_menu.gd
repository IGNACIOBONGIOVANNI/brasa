class_name WorkshopMenu
extends Control
## Taller: se gastan las chispas en meter items nuevos en los pools de las runs (los del catálogo
## bloqueados que tienen costo). Esc vuelve al menú.

signal back_requested

const NAME_WIDTH: float = 190.0
const ICON_SIZE: Vector2 = Vector2(9, 9)
const BOUGHT_COLOR: Color = Color("7fb069")

var _sparks: Label
var _list: VBoxContainer
var _back: Button
var _buttons: Dictionary[StringName, Button] = {}
var _items: Array[ItemData] = []


func _ready() -> void:
	MenuBuilder.background(self)
	_items = (load(RunState.CATALOG_PATH) as ItemCatalog).workshop_items()
	var box: VBoxContainer = MenuBuilder.centered_box(self, true)
	box.add_child(MenuBuilder.label("Taller", 16, MenuBuilder.TITLE_COLOR))
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_sparks = MenuBuilder.label("", 8, MenuBuilder.SPARK_COLOR)
	header.add_child(_sparks)
	header.add_child(MenuBuilder.label("· lo que compres empieza a salir en las runs", 8, MenuBuilder.MUTED_COLOR))
	box.add_child(header)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 3)
	box.add_child(_list)
	_back = MenuBuilder.button("Volver", back_requested.emit)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_back)
	SaveManager.profile_changed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func button_for(item: ItemData) -> Button:
	return _buttons.get(item.id)


## Rearma la lista. Si el foco estaba en la lista (o en ningún lado) queda en la misma fila, o en la
## primera compra posible, o en Volver.
func _refresh() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	var focused_row: int = _list.get_children().find(focused.get_parent()) if focused != null else -1
	_sparks.text = MenuBuilder.sparks_text(SaveManager.profile.sparks)
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for item: ItemData in _items:
		_list.add_child(_row(item))
	if focused == null or focused_row >= 0:
		MenuBuilder.focus_later(_focus_target(focused_row))


func _focus_target(preferred_row: int) -> Control:
	if preferred_row >= 0 and preferred_row < _items.size() and not button_for(_items[preferred_row]).disabled:
		return button_for(_items[preferred_row])
	for item: ItemData in _items:
		if not button_for(item).disabled:
			return button_for(item)
	return _back


func _row(item: ItemData) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	var icon := ItemsDisplay.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var single: Array[ItemData] = [item]
	icon.set_items(single)
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override(&"separation", 0)
	text.add_child(MenuBuilder.paragraph(item.display_name, NAME_WIDTH))
	text.add_child(MenuBuilder.paragraph(item.description, NAME_WIDTH, MenuBuilder.MUTED_COLOR))
	row.add_child(text)
	var bought: bool = SaveManager.profile.is_item_available(item)
	var button: Button = MenuBuilder.button("Comprado" if bought else MenuBuilder.sparks_text(item.unlock_cost),
			_buy.bind(item))
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.disabled = not SaveManager.profile.can_buy(item)
	if bought:
		button.add_theme_color_override(&"font_disabled_color", BOUGHT_COLOR)
	row.add_child(button)
	_buttons[item.id] = button
	return row


func _buy(item: ItemData) -> void:
	if SaveManager.buy(item):
		AudioManager.play_sfx(&"buy")
