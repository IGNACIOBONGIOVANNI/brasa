class_name CharacterSelect
extends Control
## Elegir personaje antes de la run: uno por columna con su dibujo, corazones, descripción e item
## inicial. Los bloqueados se ven en sombra, con el logro que los desbloquea. Esc vuelve al menú.

signal character_chosen(character: CharacterData)
signal back_requested

const CARD_WIDTH: float = 96.0
const PORTRAIT_HEIGHT: float = 30.0
const PORTRAIT_SCALE: float = 2.0
const LOCKED_COLOR: Color = Color("2a2230")

var _row: HBoxContainer
var _buttons: Dictionary[StringName, Button] = {}


func _ready() -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, false)
	box.add_child(MenuBuilder.label("Elegí personaje", 16, MenuBuilder.TITLE_COLOR))
	_row = HBoxContainer.new()
	_row.add_theme_constant_override(&"separation", 6)
	box.add_child(_row)
	var back: Button = MenuBuilder.button("Volver", back_requested.emit)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	SaveManager.profile_changed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func button_for(character: CharacterData) -> Button:
	return _buttons.get(character.id)


func _refresh() -> void:
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for character: CharacterData in SaveManager.config.characters:
		_row.add_child(_card(character))
	MenuBuilder.focus_later(_buttons[SaveManager.selected_character().id])


func _card(character: CharacterData) -> Control:
	var available: bool = SaveManager.profile.is_character_available(character)
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	card.add_theme_constant_override(&"separation", 2)
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(CARD_WIDTH, PORTRAIT_HEIGHT)
	var visual := PlayerVisual.new()
	visual.position = Vector2(CARD_WIDTH / 2.0, PORTRAIT_HEIGHT / 2.0 + 4.0)
	visual.scale = Vector2.ONE * PORTRAIT_SCALE
	visual.set_body_color(character.body_color if available else LOCKED_COLOR)
	portrait.add_child(visual)
	card.add_child(portrait)
	var button: Button = MenuBuilder.button(character.display_name if available else "???",
			character_chosen.emit.bind(character))
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.disabled = not available
	card.add_child(button)
	_buttons[character.id] = button
	if available:
		card.add_child(MenuBuilder.label("%d corazones" % character.hearts(), 8, Color("e0464e")))
		var text: String = character.description
		if character.start_item != null:
			text += ". Arranca con %s" % character.start_item.display_name
		card.add_child(_centered(MenuBuilder.paragraph(text, CARD_WIDTH)))
	else:
		var achievement: AchievementData = SaveManager.config.achievement_unlocking(character)
		var hint: String = "Bloqueado"
		if achievement != null:
			hint += "\n%s" % achievement.description
		card.add_child(_centered(MenuBuilder.paragraph(hint, CARD_WIDTH, MenuBuilder.MUTED_COLOR)))
	return card


func _centered(label: Label) -> Label:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
