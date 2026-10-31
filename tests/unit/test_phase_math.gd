extends GutTest
## PhaseMath: la fase del jefe según su vida.

var _thresholds: Array[float] = [1.0, 0.6, 0.25]


func test_full_health_is_first_phase() -> void:
	assert_eq(PhaseMath.phase_for(1.0, _thresholds), 0)
	assert_eq(PhaseMath.phase_for(0.61, _thresholds), 0)


func test_crossing_a_threshold_changes_phase() -> void:
	assert_eq(PhaseMath.phase_for(0.6, _thresholds), 1, "justo en el umbral")
	assert_eq(PhaseMath.phase_for(0.4, _thresholds), 1)
	assert_eq(PhaseMath.phase_for(0.25, _thresholds), 2)
	assert_eq(PhaseMath.phase_for(0.0, _thresholds), 2)


func test_single_phase_is_always_zero() -> void:
	var single: Array[float] = [1.0]
	assert_eq(PhaseMath.phase_for(0.1, single), 0)
