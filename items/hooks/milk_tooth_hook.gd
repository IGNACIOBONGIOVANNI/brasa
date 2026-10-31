extends ItemHook
## Diente de leche: cada KILLS_PER_HEAL enemigos muertos cura medio corazón.

const KILLS_PER_HEAL: int = 6

var _kills: int = 0


func on_kill(context: HookContext) -> void:
	_kills += 1
	if _kills < KILLS_PER_HEAL:
		return
	_kills = 0
	context.player.health.heal(1.0)
	AudioManager.play_sfx(&"pickup_heart", 0.05)
