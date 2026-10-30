extends GutTest
## RngStreams: determinismo y aislamiento entre streams.


func _sequence(rng: RandomNumberGenerator, count: int) -> Array[int]:
	var values: Array[int] = []
	for _i: int in count:
		values.append(rng.randi())
	return values


func test_same_seed_gives_same_sequence() -> void:
	var a := RngStreams.new(777)
	var b := RngStreams.new(777)
	assert_eq(_sequence(a.get_stream(RngStreams.FLOOR), 20), _sequence(b.get_stream(RngStreams.FLOOR), 20))


func test_different_seeds_differ() -> void:
	var a := RngStreams.new(1)
	var b := RngStreams.new(2)
	assert_ne(_sequence(a.get_stream(RngStreams.FLOOR), 5), _sequence(b.get_stream(RngStreams.FLOOR), 5))


func test_streams_are_independent_of_each_other() -> void:
	var a := RngStreams.new(42)
	var b := RngStreams.new(42)
	# Consumir mucho loot en "a" no debe cambiar el stream de piso.
	_sequence(a.get_stream(RngStreams.LOOT), 500)
	assert_eq(_sequence(a.get_stream(RngStreams.FLOOR), 10), _sequence(b.get_stream(RngStreams.FLOOR), 10))


func test_named_streams_differ_from_each_other() -> void:
	var s := RngStreams.new(42)
	assert_ne(_sequence(s.get_stream(RngStreams.FLOOR), 5), _sequence(s.get_stream(RngStreams.LOOT), 5))


func test_floor_is_reproducible_regardless_of_history() -> void:
	var played := RngStreams.new(9001)
	_sequence(played.get_stream(RngStreams.FLOOR), 300)
	_sequence(played.get_stream(RngStreams.COMBAT), 300)
	played.set_floor(2)
	var fresh := RngStreams.new(9001)
	fresh.set_floor(2)
	assert_eq(_sequence(played.get_stream(RngStreams.FLOOR), 10), _sequence(fresh.get_stream(RngStreams.FLOOR), 10))


func test_each_floor_has_its_own_sequence() -> void:
	var s := RngStreams.new(5)
	var floor_0: Array[int] = _sequence(s.get_stream(RngStreams.FLOOR), 5)
	s.set_floor(1)
	assert_ne(_sequence(s.get_stream(RngStreams.FLOOR), 5), floor_0)


func test_derive_seed_is_stable() -> void:
	assert_eq(RngStreams.derive_seed(123, &"floor", 0), RngStreams.derive_seed(123, &"floor", 0))
	assert_ne(RngStreams.derive_seed(123, &"floor", 0), RngStreams.derive_seed(123, &"floor", 1))


func test_seed_from_args() -> void:
	assert_eq(RngStreams.seed_from_args(PackedStringArray(["--seed=4242"]), -1), 4242)
	assert_eq(RngStreams.seed_from_args(PackedStringArray(["--demo-input", "--seed=7"]), -1), 7)
	assert_eq(RngStreams.seed_from_args(PackedStringArray(["--seed=abc"]), -1), -1)
	assert_eq(RngStreams.seed_from_args(PackedStringArray([]), 99), 99)
