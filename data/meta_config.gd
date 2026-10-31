class_name MetaConfig
extends Resource
## Personajes y logros del juego (la meta-progresión). El primer personaje es el de por defecto y
## tiene que estar desbloqueado desde el principio.

const PATH: String = "res://content/meta/meta_config.tres"

@export var characters: Array[CharacterData] = []
@export var achievements: Array[AchievementData] = []


## Se carga en tiempo de ejecución (no con preload): sus items tienen hooks que usan autoloads.
static func get_default() -> MetaConfig:
	return load(PATH) as MetaConfig


func default_character() -> CharacterData:
	return characters[0]


## null si no hay ninguno con ese id.
func character_by_id(id: StringName) -> CharacterData:
	for character: CharacterData in characters:
		if character.id == id:
			return character
	return null


## El logro que desbloquea a ese personaje, o null.
func achievement_unlocking(character: CharacterData) -> AchievementData:
	for achievement: AchievementData in achievements:
		if achievement.unlock_characters.has(character):
			return achievement
	return null
