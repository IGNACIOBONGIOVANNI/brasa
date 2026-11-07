class_name SootSweepMove
extends ChargesMove
## SOOT_SWEEP (el Deshollinador): embiste como CHARGES con la escoba baja y deja atrás una estela de
## nubes de hollín (AshPuff), una cada `spread` px. Cada nube se hincha `linger` s y revienta en las
## balas de `pattern`: hay que salir de la estela antes de que estalle, no solo esquivar la embestida.

## Lo más chica que puede ser la distancia entre nubes.
const MIN_SPACING: float = 10.0

var _last_puff: Vector2 = Vector2.ZERO
var _spacing: float = 18.0


func _begin() -> void:
	_spacing = maxf(MIN_SPACING, attack.spread)
	super._begin()


func _next(step: ChargesMove.Step) -> void:
	if step == ChargesMove.Step.DASH:
		_last_puff = enemy.global_position
		AudioManager.play_sfx(&"gust", 0.1)
	super._next(step)


func _tick(delta: float) -> bool:
	var done: bool = super._tick(delta)
	if _step == ChargesMove.Step.DASH and enemy.global_position.distance_to(_last_puff) >= _spacing:
		_drop_puff(enemy.global_position)
		_last_puff = enemy.global_position
	return done


func _end_dash() -> void:
	# Una nube más donde frenó (también al chocar).
	if enemy.global_position.distance_to(_last_puff) >= _spacing * 0.5:
		_drop_puff(enemy.global_position)
	super._end_dash()


func _drop_puff(at: Vector2) -> void:
	var puff := AshPuff.new()
	puff.radius = attack.radius
	puff.life = maxf(0.3, attack.linger)
	puff.pattern = attack.pattern
	puff.speed_multiplier = enemy.bullet_speed_multiplier
	puff.spin = rng().randf() * TAU
	place(puff, at)
