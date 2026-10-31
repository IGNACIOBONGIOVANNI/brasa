extends ItemHook
## Caparazón (activo): unos segundos de invulnerabilidad, con un escudo visible.

const DURATION: float = 3.0


func on_use(context: HookContext) -> bool:
	context.player.health.grant_invulnerability(DURATION)
	context.player.visual.show_shield(DURATION)
	return true
