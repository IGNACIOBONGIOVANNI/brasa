class_name ChapterSelect
extends Control
## Elegir capítulo antes de elegir personaje (Main la muestra solo si hay más de uno disponible): uno
## por fila con su nombre, su línea y sus pisos. Los bloqueados se ven en sombra, con lo que hay que
## hacer para jugarlos. Esc vuelve al menú.

signal chapter_chosen(chapter: RunConfig)
signal back_requested

const TEXT_WIDTH: float = 220.0

var _buttons: Array[Button] = []


func _ready() -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, false)
	box.add_child(MenuBuilder.label("Elegí capítulo", 16, MenuBuilder.TITLE_COLOR))
	var focus: Button = null
	var last: RunConfig = SaveManager.config.chapter_of(SaveManager.selected_character())
	for chapter: RunConfig in SaveManager.config.chapters:
		var button: Button = _add_chapter(box, chapter)
		if focus == null and not button.disabled:
			focus = button
		if chapter == last and not button.disabled:
			focus = button
	var back: Button = MenuBuilder.button("Volver", back_requested.emit)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	MenuBuilder.focus_later(focus if focus != null else back)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


## El botón del capítulo número `number` (1, 2...).
func button_for(number: int) -> Button:
	return _buttons[number - 1]


func _add_chapter(box: VBoxContainer, chapter: RunConfig) -> Button:
	var available: bool = SaveManager.config.is_chapter_available(chapter, SaveManager.profile)
	var title: String = "Capítulo %d · %s" % [chapter.number, chapter.display_name if available else "???"]
	var button: Button = MenuBuilder.button(title, chapter_chosen.emit.bind(chapter))
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.disabled = not available
	box.add_child(button)
	_buttons.append(button)
	var text: String
	if available:
		var names: PackedStringArray = []
		for floor_theme: FloorTheme in chapter.floors:
			names.append(floor_theme.display_name)
		text = "%s\n%s" % [chapter.description, " · ".join(names)]
	else:
		text = "Bloqueado: %s" % _unlock_hint(chapter)
	var line: Label = MenuBuilder.paragraph(text, TEXT_WIDTH, MenuBuilder.MUTED_COLOR)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(line)
	return button


## Lo que desbloquea a algún personaje del capítulo.
func _unlock_hint(chapter: RunConfig) -> String:
	for character: CharacterData in SaveManager.config.characters_of(chapter):
		var achievement: AchievementData = SaveManager.config.achievement_unlocking(character)
		if achievement != null:
			return achievement.description.to_lower()
	return "todavía no"
