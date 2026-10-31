extends ItemHook
## Botiquín (activo): cura un corazón. Con la vida llena no se gasta.

const HEAL: float = 2.0


func on_use(context: HookContext) -> bool:
	var health: HealthComponent = context.player.health
	if health.current >= health.max_health:
		AudioManager.play_sfx(&"empty")
		return false
	health.heal(HEAL)
	AudioManager.play_sfx(&"medkit")
	return true
