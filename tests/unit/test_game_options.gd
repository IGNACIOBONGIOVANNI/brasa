extends GutTest
## GameOptions: las opciones de todas las partidas pasan por options.json sin perder nada, se
## recortan si vienen raras y se leen también del guardado de antes de las partidas.


func _round_trip(options: GameOptions) -> GameOptions:
	return GameOptions.from_dict(JSON.parse_string(JSON.stringify(options.to_dict())))


func test_defaults() -> void:
	var options: GameOptions = GameOptions.from_dict({})
	assert_eq(options.volume, 1.0, "volumen al máximo")
	assert_eq(options.music_volume, GameOptions.DEFAULT_MUSIC_VOLUME)
	assert_false(options.fullscreen)
	assert_eq(options.window_scale, WindowScales.DEFAULT_SCALE, "1280x720")
	assert_eq(options.last_slot, 0, "ninguna partida abierta todavía")


func test_round_trip() -> void:
	var options := GameOptions.new()
	options.volume = 0.4
	options.music_volume = 0.3
	options.fullscreen = true
	options.window_scale = 5
	options.last_slot = 3
	var copy: GameOptions = _round_trip(options)
	assert_almost_eq(copy.volume, 0.4, 0.0001)
	assert_almost_eq(copy.music_volume, 0.3, 0.0001)
	assert_true(copy.fullscreen)
	assert_eq(copy.window_scale, 5)
	assert_eq(copy.last_slot, 3)
	assert_eq(int(options.to_dict()["version"]), GameOptions.VERSION)


func test_odd_values_are_clamped_or_ignored() -> void:
	var bad: GameOptions = GameOptions.from_dict({"volume": 7, "music_volume": -2, "fullscreen": "sí",
			"window_scale": 99, "last_slot": 12})
	assert_eq(bad.volume, 1.0, "recortado a 1")
	assert_eq(bad.music_volume, 0.0, "recortado a 0")
	assert_false(bad.fullscreen, "solo true cuenta")
	assert_eq(bad.window_scale, WindowScales.MAX_SCALE, "recortada")
	assert_eq(bad.last_slot, SaveSlots.COUNT)
	assert_eq(GameOptions.from_dict({"window_scale": "grande"}).window_scale, WindowScales.DEFAULT_SCALE)


func test_reads_the_options_of_an_old_save() -> void:
	var old_save: Dictionary = {"version": 1, "sparks": 4, "options": {"volume": 0.5, "fullscreen": true, "window_scale": 3}}
	var options: GameOptions = GameOptions.from_dict(old_save["options"])
	assert_almost_eq(options.volume, 0.5, 0.0001)
	assert_true(options.fullscreen)
	assert_eq(options.window_scale, 3)
	assert_eq(options.music_volume, GameOptions.DEFAULT_MUSIC_VOLUME, "no tenía música")
