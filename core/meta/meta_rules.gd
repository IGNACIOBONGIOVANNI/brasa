class_name MetaRules
extends RefCounted
## Cuentas de la meta-progresión: cuántas chispas deja una run y si se cumplió un logro.

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
