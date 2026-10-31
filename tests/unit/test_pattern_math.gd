extends GutTest
## PatternMath: direcciones de los cuatro patrones (anillo, espiral, abanico, apuntado).

const EPSILON: float = 0.0001


func _pattern(kind: BulletPatternData.Kind, count: int) -> BulletPatternData:
	var pattern := BulletPatternData.new()
	pattern.kind = kind
	pattern.count = count
	return pattern


func _assert_angle(direction: Vector2, degrees: float, text: String = "") -> void:
	assert_almost_eq(angle_difference(direction.angle(), deg_to_rad(degrees)), 0.0, EPSILON, text)


func test_ring_is_evenly_spaced_and_normalized() -> void:
	var dirs: Array[Vector2] = PatternMath.directions(_pattern(BulletPatternData.Kind.RING, 8), Vector2.RIGHT, 0)
	assert_eq(dirs.size(), 8)
	var total := Vector2.ZERO
	for i: int in dirs.size():
		assert_almost_eq(dirs[i].length(), 1.0, EPSILON, "normalizada")
		_assert_angle(dirs[i], 45.0 * i)
		total += dirs[i]
	assert_almost_eq(total.length(), 0.0, EPSILON, "simétrico")


func test_ring_odd_volleys_shift_half_a_step() -> void:
	var pattern := _pattern(BulletPatternData.Kind.RING, 8)
	_assert_angle(PatternMath.directions(pattern, Vector2.RIGHT, 1)[0], 22.5, "ráfaga 1")
	_assert_angle(PatternMath.directions(pattern, Vector2.RIGHT, 2)[0], 0.0, "ráfaga 2")


func test_ring_ignores_aim() -> void:
	var pattern := _pattern(BulletPatternData.Kind.RING, 6)
	assert_eq(PatternMath.directions(pattern, Vector2.UP, 0), PatternMath.directions(pattern, Vector2.RIGHT, 0))


func test_spiral_rotates_each_volley() -> void:
	var pattern := _pattern(BulletPatternData.Kind.SPIRAL, 3)
	pattern.rotation_step_degrees = 20.0
	var first: Array[Vector2] = PatternMath.directions(pattern, Vector2.RIGHT, 0)
	_assert_angle(first[0], 0.0)
	_assert_angle(first[1], 120.0, "brazos separados 120°")
	_assert_angle(PatternMath.directions(pattern, Vector2.RIGHT, 1)[0], 20.0)
	_assert_angle(PatternMath.directions(pattern, Vector2.RIGHT, 3)[0], 60.0)


func test_fan_is_centered_on_aim() -> void:
	var pattern := _pattern(BulletPatternData.Kind.FAN, 5)
	pattern.spread_degrees = 60.0
	var dirs: Array[Vector2] = PatternMath.directions(pattern, Vector2.DOWN * 30.0, 0)
	assert_eq(dirs.size(), 5)
	var expected: Array[float] = [60.0, 75.0, 90.0, 105.0, 120.0]
	for i: int in dirs.size():
		_assert_angle(dirs[i], expected[i], "bala %d" % i)


func test_fan_with_one_bullet_goes_to_aim() -> void:
	var dirs: Array[Vector2] = PatternMath.directions(_pattern(BulletPatternData.Kind.FAN, 1), Vector2.LEFT, 0)
	assert_eq(dirs.size(), 1)
	_assert_angle(dirs[0], 180.0)


func test_aimed_fires_one_bullet_at_target() -> void:
	var dirs: Array[Vector2] = PatternMath.directions(_pattern(BulletPatternData.Kind.AIMED, 5), Vector2(3, 4), 2)
	assert_eq(dirs.size(), 1, "AIMED ignora count")
	assert_almost_eq(dirs[0].x, 0.6, EPSILON)
	assert_almost_eq(dirs[0].y, 0.8, EPSILON)


func test_angle_offset_rotates_pattern() -> void:
	var pattern := _pattern(BulletPatternData.Kind.AIMED, 1)
	pattern.angle_offset_degrees = 10.0
	_assert_angle(PatternMath.directions(pattern, Vector2.RIGHT, 0)[0], 10.0)


func test_count_below_one_fires_one_bullet() -> void:
	var dirs: Array[Vector2] = PatternMath.directions(_pattern(BulletPatternData.Kind.RING, 0), Vector2.RIGHT, 0)
	assert_eq(dirs.size(), 1)
