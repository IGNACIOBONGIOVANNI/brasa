class_name AchievementData
extends Resource
## Un logro: una condición que se revisa al terminar cada run (MetaRules.is_met) y lo que desbloquea
## la primera vez que se cumple.

enum Condition {
	## Vencer a `boss` en una run.
	DEFEAT_BOSS,
	## Llegar a `amount` enemigos sumando todas las runs.
	TOTAL_KILLS,
	## Matar `amount` enemigos en una sola run.
	KILLS_IN_RUN,
	## Terminar una run con `amount` items o más (pasivos, activo y armas además de la pistola).
	ITEMS_IN_RUN,
}

@export var id: StringName = &""
@export var display_name: String = ""
## Qué hay que hacer; se muestra en la lista de logros y en los personajes bloqueados.
@export var description: String = ""
@export var condition: Condition = Condition.DEFEAT_BOSS
@export var boss: EnemyData
@export var amount: int = 0
@export var unlock_items: Array[ItemData] = []
@export var unlock_characters: Array[CharacterData] = []


## Nombres de lo que desbloquea, separados por coma.
func unlocks_text() -> String:
	var names: PackedStringArray = []
	for character: CharacterData in unlock_characters:
		names.append(character.display_name)
	for item: ItemData in unlock_items:
		names.append(item.display_name)
	return ", ".join(names)
