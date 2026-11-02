class_name MoltenMove
extends BossMove
## MOLTEN: golpea el piso y salpica metal fundido: `count` charcos cerca del jugador (el primero
## donde está), uno cada `interval` s. Avisan, queman al caer y quedan `linger` s en el piso.

const SLAM_TRAUMA: float = 0.4

var _left: int = 0
var _index: int = 0
var _next: float = 0.0
var _wait: float = 0.0


func _begin() -> void:
	_left = attack.count
	EventBus.shake_requested.emit(SLAM_TRAUMA)
	AudioManager.play_sfx(&"rumble", 0.05)


func _tick(delta: float) -> bool:
	hold(delta)
	if _left > 0:
		_next -= delta
		if _next <= 0.0:
			var strike: BossStrike = spawn_strike(spot_near_target(_index), BossAttack.Look.EMBER)
			strike.linger = attack.linger
			_index += 1
			_left -= 1
			_next = attack.interval
		return false
	_wait += delta
	return _wait >= attack.warn_time
