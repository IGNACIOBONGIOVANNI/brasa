extends ItemHook
## Rencor: al recibir daño suelta un anillo de balas.

const BULLETS: int = 8


func on_damaged(context: HookContext) -> void:
	if not context.player.is_dead():
		fire_ring(context.player, BULLETS)
