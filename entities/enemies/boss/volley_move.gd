class_name VolleyMove
extends BossMove
## VOLLEY: dispara el patrón `count` veces, una cada `interval` s (quieto).

var _left: int = 0
var _next: float = 0.0


func _begin() -> void:
	_left = attack.count


func _tick(delta: float) -> bool:
	hold(delta)
	if enemy.emitter.is_firing():
		return false
	if _left <= 0 or attack.pattern == null or not enemy.has_target():
		return true
	_next -= delta
	if _next <= 0.0:
		_left -= 1
		_next = attack.interval
		enemy.emitter.fire(attack.pattern, enemy.target)
	return false


func _end() -> void:
	enemy.emitter.stop()
