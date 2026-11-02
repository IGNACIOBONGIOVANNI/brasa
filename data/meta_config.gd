class_name MetaConfig
extends Resource
## Personajes, logros y capítulos del juego (la meta-progresión). El primer personaje es el de por
## defecto y tiene que estar desbloqueado desde el principio. Un capítulo se puede jugar si alguno de
## sus personajes está disponible.

const PATH: String = "res://content/meta/meta_config.tres"

@export var characters: Array[CharacterData] = []
@export var achievements: Array[AchievementData] = []
## En orden (el primero es el de siempre).
@export var chapters: Array[RunConfig] = []


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


## El capítulo que juega ese personaje (el primero si no hay uno con su número).
func chapter_of(character: CharacterData) -> RunConfig:
	for chapter: RunConfig in chapters:
		if chapter.number == character.chapter:
			return chapter
	return chapters[0]


func characters_of(chapter: RunConfig) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for character: CharacterData in characters:
		if character.chapter == chapter.number:
			result.append(character)
	return result


## true si alguno de sus personajes está disponible en ese perfil.
func is_chapter_available(chapter: RunConfig, profile: MetaProfile) -> bool:
	for character: CharacterData in characters_of(chapter):
		if profile.is_character_available(character):
			return true
	return false


## El logro que desbloquea a ese personaje, o null.
func achievement_unlocking(character: CharacterData) -> AchievementData:
	for achievement: AchievementData in achievements:
		if achievement.unlock_characters.has(character):
			return achievement
	return null
