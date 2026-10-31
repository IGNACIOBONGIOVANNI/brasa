extends ItemHook
## Esquirlas: cada enemigo que muere revienta en un anillo de balas del jugador.

const SHARDS: int = 6


func on_kill(context: HookContext) -> void:
	fire_from(context.player, context.position, PatternMath.ring(SHARDS, context.player.aim_direction.angle()))
