extends GutTest
## ShotSpec: combinación de stats y arma.


func _weapon() -> WeaponData:
	var weapon := WeaponData.new()
	weapon.id = &"test"
	return weapon


func test_neutral_weapon_keeps_stats() -> void:
	var stats := StatBlock.new()
	var spec := ShotSpec.build(stats, _weapon())
	assert_almost_eq(spec.damage, stats.damage, 0.0001)
	assert_almost_eq(spec.speed, stats.shot_speed, 0.0001)
	assert_almost_eq(spec.max_range, stats.shot_range, 0.0001)


func test_weapon_multipliers_apply() -> void:
	var stats := StatBlock.new()
	stats.damage = 4.0
	stats.shot_speed = 100.0
	stats.shot_range = 200.0
	var weapon := _weapon()
	weapon.damage_mult = 1.5
	weapon.shot_speed_mult = 2.0
	weapon.range_mult = 0.5
	var spec := ShotSpec.build(stats, weapon)
	assert_almost_eq(spec.damage, 6.0, 0.0001)
	assert_almost_eq(spec.speed, 200.0, 0.0001)
	assert_almost_eq(spec.max_range, 100.0, 0.0001)


func test_values_are_clamped_to_minimums() -> void:
	var stats := StatBlock.new()
	stats.damage = 0.0
	stats.shot_speed = 1.0
	stats.shot_range = 1.0
	var spec := ShotSpec.build(stats, _weapon())
	assert_almost_eq(spec.damage, ShotSpec.MIN_DAMAGE, 0.0001)
	assert_almost_eq(spec.speed, ShotSpec.MIN_SPEED, 0.0001)
	assert_almost_eq(spec.max_range, ShotSpec.MIN_RANGE, 0.0001)


func test_fire_interval_from_fire_rate() -> void:
	var stats := StatBlock.new()
	stats.fire_rate = 4.0
	var weapon := _weapon()
	assert_almost_eq(ShotSpec.fire_interval(stats, weapon), 0.25, 0.0001)
	weapon.fire_rate_mult = 2.0
	assert_almost_eq(ShotSpec.fire_interval(stats, weapon), 0.125, 0.0001)


func test_fire_interval_is_clamped() -> void:
	var stats := StatBlock.new()
	stats.fire_rate = 0.0
	assert_almost_eq(ShotSpec.fire_interval(stats, _weapon()), 1.0 / ShotSpec.MIN_FIRE_RATE, 0.0001)
	stats.fire_rate = 1000.0
	assert_almost_eq(ShotSpec.fire_interval(stats, _weapon()), 1.0 / ShotSpec.MAX_FIRE_RATE, 0.0001)
