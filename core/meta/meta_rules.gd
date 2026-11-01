class_name MetaRules
extends RefCounted
## Cuentas de la meta-progresión: cuántas chispas deja una run, si se cumplió un logro y cuánto de
## una partida está hecho.

const KILLS_PER_SPARK: int = 5
const SPARKS_PER_BOSS: int = 10
const VICTORY_SPARKS: int = 10


## Una chispa cada 5 enemigos, 10 por jefe vencido y 10 más por ganar.
static func sparks_for(record: RunRecord) -> int:
	var sparks: int = floori(record.kills / float(KILLS_PER_SPARK)) + SPARKS_PER_BOSS * record.bosses.size()
	if record.victory:
		sparks += VICTORY_SPARKS
	return sparks


## `profile` tiene que tener ya sumada la run de `record` (los totales la incluyen).
static func is_met(achievement: AchievementData, profile: MetaProfile, record: RunRecord) -> bool:
	match achievement.condition:
		AchievementData.Condition.DEFEAT_BOSS:
			return achievement.boss != null and record.bosses.has(achievement.boss.id)
		AchievementData.Condition.TOTAL_KILLS:
			return profile.total_kills >= achievement.amount
		AchievementData.Condition.KILLS_IN_RUN:
			return record.kills >= achievement.amount
		AchievementData.Condition.ITEMS_IN_RUN:
			return record.items >= achievement.amount
	return false


## Cuánto de la partida está hecho, de 0 a 1: cada logro, cada item y personaje bloqueado que ya se
## consiguió (por logro o en el Taller) y haber ganado una run valen lo mismo. 1 = todo.
static func completion(profile: MetaProfile, achievements: Array[AchievementData],
		characters: Array[CharacterData], items: Array[ItemData]) -> float:
	var total: int = 1
	var done: int = 1 if profile.wins > 0 else 0
	for achievement: AchievementData in achievements:
		total += 1
		if profile.has_achievement(achievement):
			done += 1
	for character: CharacterData in characters:
		if character.locked:
			total += 1
			if profile.unlocked_characters.has(character.id):
				done += 1
	for item: ItemData in items:
		if item.locked:
			total += 1
			if profile.unlocked_items.has(item.id):
				done += 1
	return done / float(total)


## El porcentaje para mostrar: redondeado para abajo (100 % solo con todo hecho).
static func percent(fraction: float) -> int:
	return floori(fraction * 100.0 + 0.0001)
