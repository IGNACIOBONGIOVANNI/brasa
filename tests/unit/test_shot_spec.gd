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


func test_weapon_impact_values_pass_through() -> void:
	var weapon := _weapon()
	weapon.knockback = 55.0
	weapon.impact_sfx_id = &"thud"
	var spec := ShotSpec.build(StatBlock.new(), weapon)
	assert_almost_eq(spec.knockback, 55.0, 0.0001)
	assert_eq(spec.impact_sfx_id, &"thud")


func test_bullet_behaviors_come_from_stats() -> void:
	var stats := StatBlock.new()
	stats.bounces = 2.0
	stats.pierce = 1.0
	stats.homing = 0.5
	stats.shot_size = 2.0
	var spec := ShotSpec.build(stats, _weapon())
	assert_eq(spec.bounces, 2)
	assert_eq(spec.pierce, 1)
	assert_almost_eq(spec.homing, 0.5, 0.0001)
	assert_almost_eq(spec.radius, _weapon().bullet_radius * 2.0, 0.0001)


func test_pattern_spec_copies_pattern_values() -> void:
	var pattern := BulletPatternData.new()
	pattern.damage = 1.0
	pattern.bullet_speed = 75.0
	pattern.bullet_range = 300.0
	pattern.knockback = 90.0
	var spec := ShotSpec.from_pattern(pattern)
	assert_almost_eq(spec.damage, 1.0, 0.0001)
	assert_almost_eq(spec.speed, 75.0, 0.0001)
	assert_almost_eq(spec.max_range, 300.0, 0.0001)
	assert_almost_eq(spec.knockback, 90.0, 0.0001)
	assert_eq(spec.impact_sfx_id, &"", "las balas enemigas no suenan al chocar")


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
