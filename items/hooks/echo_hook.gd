extends ItemHook
## Eco: cada SHOTS_PER_ECHO disparos sale otra bala para el lado contrario.

const SHOTS_PER_ECHO: int = 4

var _shots: int = 0


func on_shoot(context: HookContext) -> void:
	_shots += 1
	if _shots < SHOTS_PER_ECHO:
		return
	_shots = 0
	var back: Array[Vector2] = [-context.direction]
	fire_from(context.player, context.position + Vector2(0, -2), back)
