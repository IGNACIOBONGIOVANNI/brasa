class_name RunSummary
extends Control
## Resumen al terminar la run (ganando o muriendo): piso alcanzado, tiempo, enemigos, items y seed.
## Lee todo de RunState.

signal retry_requested
signal menu_requested

const BACKGROUND: Color = Color(0.06, 0.05, 0.08)
const WIN_COLOR: Color = Color("7ad1ff")
const LOSE_COLOR: Color = Color("e0464e")

var _retry: Button


func show_summary(victory: bool) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var box: VBoxContainer = MenuBuilder.centered_box(self, true)
	box.add_child(MenuBuilder.label("¡Ganaste!" if victory else "Fin de la run", 16, WIN_COLOR if victory else LOSE_COLOR))
	box.add_child(MenuBuilder.label("Piso %d · %s" % [RunState.floor_index + 1, RunState.floor_name]))
	box.add_child(MenuBuilder.label("Tiempo %s · Enemigos %d" % [format_time(RunState.run_time), RunState.kills]))
	var items: Array[ItemData] = RunState.items.duplicate()
	if RunState.active_item != null:
		items.append(RunState.active_item)
	if not items.is_empty():
		var row := ItemsDisplay.new()
		row.custom_minimum_size = Vector2(items.size() * ItemsDisplay.SPACING, 8)
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.set_items(items)
		box.add_child(row)
	box.add_child(MenuBuilder.label("seed %d" % GameRNG.get_run_seed(), 8, MenuBuilder.MUTED_COLOR))
	_retry = MenuBuilder.button("Otra run", retry_requested.emit)
	box.add_child(_retry)
	box.add_child(MenuBuilder.button("Menú", menu_requested.emit))
	MenuBuilder.focus_later(_retry)


## "m:ss".
static func format_time(seconds: float) -> String:
	var total: int = floori(seconds)
	return "%d:%02d" % [floori(total / 60.0), total % 60]
