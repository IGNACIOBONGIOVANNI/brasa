extends GutTest
## WeaponSlot: munición infinita, cargador, recarga desde la reserva y reposición.


func _weapon(ammo: int, magazine: int, reload_time: float = 1.0) -> WeaponData:
	var weapon := WeaponData.new()
	weapon.ammo = ammo
	weapon.magazine = magazine
	weapon.reload_time = reload_time
	return weapon


func test_infinite_weapon_never_runs_out() -> void:
	var slot := WeaponSlot.new(_weapon(-1, -1))
	for _i: int in 500:
		assert_true(slot.can_fire())
		slot.consume()
	assert_false(slot.start_reload(), "sin cargador no recarga")
	assert_eq(slot.loaded(), -1)


func test_magazine_empties_and_reloads_from_reserve() -> void:
	var slot := WeaponSlot.new(_weapon(10, 4))
	for _i: int in 4:
		slot.consume()
	assert_false(slot.can_fire(), "cargador vacío")
	assert_true(slot.start_reload())
	assert_false(slot.can_fire(), "recargando")
	assert_false(slot.update(0.5), "a mitad de la recarga")
	assert_true(slot.update(0.6), "terminó")
	assert_eq(slot.in_magazine, 4)
	assert_eq(slot.reserve, 6)


func test_last_reload_takes_what_is_left() -> void:
	var slot := WeaponSlot.new(_weapon(2, 4))
	for _i: int in 4:
		slot.consume()
	slot.start_reload()
	slot.update(2.0)
	assert_eq(slot.in_magazine, 2)
	assert_eq(slot.reserve, 0)
	for _i: int in 2:
		slot.consume()
	assert_true(slot.is_empty())
	assert_false(slot.start_reload(), "no queda nada para recargar")


func test_full_magazine_does_not_reload() -> void:
	assert_false(WeaponSlot.new(_weapon(10, 4)).start_reload())


func test_weapon_without_magazine_spends_reserve() -> void:
	var slot := WeaponSlot.new(_weapon(3, -1))
	for _i: int in 3:
		assert_true(slot.can_fire())
		slot.consume()
	assert_false(slot.can_fire())
	assert_true(slot.is_empty())


func test_zero_delta_does_not_advance_reload() -> void:
	var slot := WeaponSlot.new(_weapon(10, 4))
	slot.consume()
	slot.start_reload()
	for _i: int in 50:
		assert_false(slot.update(0.0))
	assert_true(slot.is_reloading())


func test_refill_adds_a_fraction_up_to_max() -> void:
	var slot := WeaponSlot.new(_weapon(40, -1))
	for _i: int in 30:
		slot.consume()
	slot.refill(0.25)
	assert_eq(slot.reserve, 20, "10 + 25 % de 40")
	slot.refill(1.0)
	assert_eq(slot.reserve, 40, "no se pasa del máximo")
