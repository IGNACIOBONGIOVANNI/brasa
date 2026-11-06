class_name RunSummary
extends Control
## Resumen al terminar la run (ganando o muriendo): personaje, piso alcanzado, tiempo, enemigos,
## items, seed y lo ganado para el progreso (chispas y logros nuevos). Lee la run de RunState.

signal retry_requested
signal menu_requested

const WIN_COLOR: Color = Color("7ad1ff")
const LOSE_COLOR: Color = Color("e0464e")
const ACHIEVEMENT_COLOR: Color = Color("7fb069")
## Logros nuevos que se listan uno por uno; si hay más, se resumen en una línea.
const MAX_ACHIEVEMENT_LINES: int = 2
## Los items del resumen van en filas; si no entran, "+N" (así los botones siempre se ven).
const ITEMS_PER_ROW: int = 18
const MAX_ITEM_ROWS: int = 2
## El aviso de logro suena después del de victoria o derrota.
const ACHIEVEMENT_SFX_DELAY: float = 0.6
## Una línea de historia debajo del título (ver docs/LORE.md).
const VICTORY_TEXT: String = "La fragua vuelve a prender y arriba las casas se entibian. Nadie pregunta con qué."
const DEFEAT_TEXT: String = "Tu chispa vuelve al Taller. El herrero la sopla otra vez; cada vez la recuerda menos."
const STORY_WIDTH: float = 220.0
const STORY_FONT: int = 7

var _retry: Button


## La línea de historia debajo del título: la del capítulo de la run (o la de siempre).
static func story_text(victory: bool) -> String:
	var text: String = ""
	if RunState.chapter != null:
		text = RunState.chapter.victory_text if victory else RunState.chapter.defeat_text
	if text.is_empty():
		text = VICTORY_TEXT if victory else DEFEAT_TEXT
	return text


## `rewards`: lo que dejó la run (null = nada, por ejemplo en los tests del resumen solo).
func show_summary(victory: bool, rewards: MetaProfile.RunRewards = null) -> void:
	MenuBuilder.background(self)
	AudioManager.play_sfx(&"victory" if victory else &"defeat")
	var box: VBoxContainer = MenuBuilder.centered_box(self, true)
	box.add_child(MenuBuilder.label("¡Ganaste!" if victory else "Fin de la run", 16, WIN_COLOR if victory else LOSE_COLOR))
	var story: Label = MenuBuilder.paragraph(story_text(victory), STORY_WIDTH, MenuBuilder.MUTED_COLOR)
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override(&"font_size", STORY_FONT)
	box.add_child(story)
	box.add_child(MenuBuilder.label("%s · Piso %d · %s" % [RunState.character.display_name, RunState.floor_index + 1, RunState.floor_name]))
	box.add_child(MenuBuilder.label("Tiempo %s · Enemigos %d · seed %d" % [format_time(RunState.run_time), RunState.kills,
			GameRNG.get_run_seed()]))
	var items: Array[ItemData] = RunState.items.duplicate()
	if RunState.active_item != null:
		items.append(RunState.active_item)
	if not items.is_empty():
		box.add_child(items_grid(items))
	if rewards != null:
		_add_rewards(box, rewards)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 8)
	_retry = MenuBuilder.button("Otra run", retry_requested.emit)
	buttons.add_child(_retry)
	buttons.add_child(MenuBuilder.button("Menú", menu_requested.emit))
	box.add_child(buttons)
	MenuBuilder.focus_later(_retry)


## Los items en filas de ITEMS_PER_ROW, como mucho MAX_ITEM_ROWS (lo que sobra, "+N").
static func items_grid(items: Array[ItemData]) -> Control:
	var limit: int = ITEMS_PER_ROW * MAX_ITEM_ROWS
	var shown: Array[ItemData] = items.slice(0, limit)
	var extra: int = items.size() - shown.size()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var grid := ItemsDisplay.new()
	grid.columns = ITEMS_PER_ROW
	var rows: int = ceili(float(shown.size()) / ITEMS_PER_ROW)
	grid.custom_minimum_size = Vector2(mini(shown.size(), ITEMS_PER_ROW) * ItemsDisplay.SPACING, rows * ItemsDisplay.ROW_HEIGHT)
	grid.set_items(shown)
	row.add_child(grid)
	if extra > 0:
		row.add_child(MenuBuilder.label("+%d" % extra, 8, MenuBuilder.MUTED_COLOR))
	return row


func _add_rewards(box: VBoxContainer, rewards: MetaProfile.RunRewards) -> void:
	box.add_child(MenuBuilder.label("+%s (tenés %d)" % [MenuBuilder.sparks_text(rewards.sparks), SaveManager.profile.sparks],
			8, MenuBuilder.SPARK_COLOR))
	for i: int in mini(rewards.achievements.size(), MAX_ACHIEVEMENT_LINES):
		var achievement: AchievementData = rewards.achievements[i]
		box.add_child(MenuBuilder.label("Logro: %s · desbloquea %s" % [achievement.display_name, achievement.unlocks_text()],
				8, ACHIEVEMENT_COLOR))
	var extra: int = rewards.achievements.size() - MAX_ACHIEVEMENT_LINES
	if extra > 0:
		box.add_child(MenuBuilder.label("y %d logro%s más" % [extra, "" if extra == 1 else "s"], 8, ACHIEVEMENT_COLOR))
	if not rewards.achievements.is_empty():
		get_tree().create_timer(ACHIEVEMENT_SFX_DELAY).timeout.connect(AudioManager.play_sfx.bind(&"achievement"))


## "m:ss".
static func format_time(seconds: float) -> String:
	var total: int = floori(seconds)
	return "%d:%02d" % [floori(total / 60.0), total % 60]
