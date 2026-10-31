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

var _retry: Button


## `rewards`: lo que dejó la run (null = nada, por ejemplo en los tests del resumen solo).
func show_summary(victory: bool, rewards: MetaProfile.RunRewards = null) -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, true)
	box.add_child(MenuBuilder.label("¡Ganaste!" if victory else "Fin de la run", 16, WIN_COLOR if victory else LOSE_COLOR))
	box.add_child(MenuBuilder.label("%s · Piso %d · %s" % [RunState.character.display_name, RunState.floor_index + 1, RunState.floor_name]))
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
	if rewards != null:
		_add_rewards(box, rewards)
	_retry = MenuBuilder.button("Otra run", retry_requested.emit)
	box.add_child(_retry)
	box.add_child(MenuBuilder.button("Menú", menu_requested.emit))
	MenuBuilder.focus_later(_retry)


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
		AudioManager.play_sfx(&"achievement")


## "m:ss".
static func format_time(seconds: float) -> String:
	var total: int = floori(seconds)
	return "%d:%02d" % [floori(total / 60.0), total % 60]
