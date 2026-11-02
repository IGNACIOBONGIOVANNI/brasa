class_name FragBombsMove
extends BossMove
## FRAG_BOMBS: tira `count` bombas en arco cerca del jugador (la primera donde está), una cada
## `interval` s. Cada una cae, espera `warn_time` s con la mecha prendida y explota en metralla
## (`pattern`). Son LobShell con mecha: el Pulso las apaga.

const LOB_SHELL_SCENE: PackedScene = preload("res://entities/enemies/lob_shell.tscn")
## Lo que tarda en volar cada bomba.
const FLIGHT_TIME: float = 0.65

var _left: int = 0
var _index: int = 0
var _next: float = 0.0
var _wait: float = 0.0


func _begin() -> void:
	_left = attack.count


func _tick(delta: float) -> bool:
	hold(delta)
	if _left > 0:
		_next -= delta
		if _next <= 0.0:
			_throw(spot_near_target(_index))
			_index += 1
			_left -= 1
			_next = attack.interval
		return false
	_wait += delta
	return _wait >= FLIGHT_TIME


func _throw(at: Vector2) -> void:
	var shell := Fx.spawn(enemy.get_tree(), LOB_SHELL_SCENE, at) as LobShell
	shell.origin = enemy.global_position + Vector2(0, -8)
	shell.duration = FLIGHT_TIME
	shell.fuse = attack.warn_time
	shell.damage = attack.damage
	shell.radius = attack.radius
	shell.pattern = attack.pattern
	shell.speed_multiplier = enemy.bullet_speed_multiplier
	shell.color = enemy.data.body_color.lightened(0.35)
	enemy.visual.play_hit()
	AudioManager.play_sfx(&"lob", 0.1)
