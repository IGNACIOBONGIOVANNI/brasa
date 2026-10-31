extends GutTest
## HealthMath: daño, curación, muerte y corazones del HUD.

const FULL: HealthMath.Heart = HealthMath.Heart.FULL
const HALF: HealthMath.Heart = HealthMath.Heart.HALF
const EMPTY: HealthMath.Heart = HealthMath.Heart.EMPTY


func test_damage_reduces_health() -> void:
	assert_almost_eq(HealthMath.damaged(6.0, 1.0), 5.0, 0.0001)
	assert_almost_eq(HealthMath.damaged(10.0, 2.5), 7.5, 0.0001)


func test_damage_never_goes_below_zero() -> void:
	assert_eq(HealthMath.damaged(1.0, 5.0), 0.0)


func test_negative_damage_is_ignored() -> void:
	assert_eq(HealthMath.damaged(3.0, -2.0), 3.0)


func test_heal_is_capped_at_max() -> void:
	assert_eq(HealthMath.healed(2.0, 1.0, 6.0), 3.0)
	assert_eq(HealthMath.healed(5.0, 4.0, 6.0), 6.0, "el sobrante se pierde")


func test_negative_heal_is_ignored() -> void:
	assert_eq(HealthMath.healed(3.0, -2.0, 6.0), 3.0)


func test_heal_clamps_when_max_dropped_below_current() -> void:
	assert_eq(HealthMath.healed(8.0, 0.0, 6.0), 6.0)


func test_dead_only_at_zero() -> void:
	assert_true(HealthMath.is_dead(0.0))
	assert_false(HealthMath.is_dead(0.5))


func test_heart_states_full_half_empty() -> void:
	var expected: Array[HealthMath.Heart] = [FULL, FULL, HALF]
	assert_eq(HealthMath.heart_states(5, 6), expected)
	expected = [FULL, FULL, FULL]
	assert_eq(HealthMath.heart_states(6, 6), expected)
	expected = [HALF, EMPTY]
	assert_eq(HealthMath.heart_states(1, 4), expected)


func test_heart_states_clamp_out_of_range_values() -> void:
	var expected: Array[HealthMath.Heart] = [FULL, FULL, FULL]
	assert_eq(HealthMath.heart_states(9, 6), expected, "más vida que contenedores")
	expected = [EMPTY, EMPTY, EMPTY]
	assert_eq(HealthMath.heart_states(-3, 6), expected, "vida negativa")


func test_odd_max_adds_a_container() -> void:
	var expected: Array[HealthMath.Heart] = [FULL, HALF, EMPTY]
	assert_eq(HealthMath.heart_states(3, 5), expected)
