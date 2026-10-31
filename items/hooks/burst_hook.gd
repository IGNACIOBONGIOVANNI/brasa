extends ItemHook
## Estallido (activo): dispara un anillo grande de balas alrededor del jugador.

const BULLETS: int = 14
const TRAUMA: float = 0.4


func on_use(context: HookContext) -> bool:
	fire_ring(context.player, BULLETS)
	EventBus.shake_requested.emit(TRAUMA)
	return true
