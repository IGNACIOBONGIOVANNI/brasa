class_name PatternMath
extends RefCounted
## Direcciones de cada ráfaga de un BulletPatternData. Sin nodos: se testea directo.


## Direcciones normalizadas de la ráfaga número `volley_index` (desde 0).
## `aim` apunta al objetivo; RING y SPIRAL no lo usan (su referencia es la derecha).
static func directions(pattern: BulletPatternData, aim: Vector2, volley_index: int) -> Array[Vector2]:
	var count: int = maxi(1, pattern.count)
	var offset: float = deg_to_rad(pattern.angle_offset_degrees)
	match pattern.kind:
		BulletPatternData.Kind.RING:
			# Las ráfagas impares se corren media separación para tapar los huecos de la anterior.
			var half_step: float = PI / count if volley_index % 2 == 1 else 0.0
			return _circle(count, offset + half_step)
		BulletPatternData.Kind.SPIRAL:
			return _circle(count, offset + deg_to_rad(pattern.rotation_step_degrees) * volley_index)
		BulletPatternData.Kind.FAN:
			return _arc(count, aim.angle() + offset, deg_to_rad(pattern.spread_degrees))
	# AIMED: una sola bala directo al objetivo.
	var single: Array[Vector2] = [Vector2.from_angle(aim.angle() + offset)]
	return single


static func _circle(count: int, start_angle: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for i: int in count:
		result.append(Vector2.from_angle(start_angle + TAU * i / count))
	return result


static func _arc(count: int, center_angle: float, spread: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if count == 1:
		result.append(Vector2.from_angle(center_angle))
		return result
	var step: float = spread / (count - 1)
	var start: float = center_angle - spread * 0.5
	for i: int in count:
		result.append(Vector2.from_angle(start + step * i))
	return result
