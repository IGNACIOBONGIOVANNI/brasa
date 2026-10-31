class_name AchievementsMenu
extends Control
## Tabla de logros (cuáles están hechos, qué hay que hacer y qué desbloquean) y los totales de todas
## las runs. Esc vuelve al menú.

signal back_requested

const DONE_COLOR: Color = Color("7fb069")
const COLUMNS: int = 3

var _table: GridContainer
var _totals: Label
var _back: Button


func _ready() -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, true)
	box.add_child(MenuBuilder.label("Logros", 16, MenuBuilder.TITLE_COLOR))
	_totals = MenuBuilder.label("", 8, MenuBuilder.MUTED_COLOR)
	box.add_child(_totals)
	_table = GridContainer.new()
	_table.columns = COLUMNS
	_table.add_theme_constant_override(&"h_separation", 8)
	_table.add_theme_constant_override(&"v_separation", 1)
	box.add_child(_table)
	_back = MenuBuilder.button("Volver", back_requested.emit)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_back)
	SaveManager.profile_changed.connect(_refresh)
	_refresh()
	MenuBuilder.focus_later(_back)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _refresh() -> void:
	var profile: MetaProfile = SaveManager.profile
	for child: Node in _table.get_children():
		_table.remove_child(child)
		child.queue_free()
	for header: String in ["Logro", "Cómo", "Desbloquea"]:
		_cell(header, MenuBuilder.TITLE_COLOR)
	var achievements: Array[AchievementData] = SaveManager.config.achievements
	var done: int = 0
	for achievement: AchievementData in achievements:
		var got: bool = profile.has_achievement(achievement)
		if got:
			done += 1
		_cell(achievement.display_name, DONE_COLOR if got else Color("f2efe6"))
		_cell(achievement.description, MenuBuilder.MUTED_COLOR)
		_cell(achievement.unlocks_text(), DONE_COLOR if got else MenuBuilder.MUTED_COLOR)
	_totals.text = "Logros %d/%d · Runs %d · Victorias %d · Enemigos %d" % [
		done, achievements.size(), profile.runs, profile.wins, profile.total_kills]


func _cell(text: String, color: Color) -> void:
	var cell: Label = MenuBuilder.label(text, 8, color)
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_table.add_child(cell)
