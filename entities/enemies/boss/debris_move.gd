class_name DebrisMove
extends BossMove
## DEBRIS: el techo tiembla y caen cascotes cerca del jugador, uno cada `interval` s; cada uno avisa
## con su sombra. Termina cuando cayó el último. Lo que cae depende de `look` (piedras, carámbanos o
## rayos).

const RUMBLE_TRAUMA: float = 0.3

var _left: int = 0
var _index: int = 0
var _next: float = 0.0
var _wait: float = 0.0


func _on_windup() -> void:
	AudioManager.play_sfx(&"rumble", 0.05)
	EventBus.shake_requested.emit(RUMBLE_TRAUMA)


func _begin() -> void:
	_left = attack.count


func _tick(delta: float) -> bool:
	hold(delta)
	if _left > 0:
		_next -= delta
		if _next <= 0.0:
			var strike: BossStrike = spawn_strike(spot_near_target(_index), attack.look)
			strike.pattern = attack.pattern
			_index += 1
			_left -= 1
			_next = attack.interval
		return false
	_wait += delta
	return _wait >= attack.warn_time
