extends GutTest
## Resoluciones de la ventana: múltiplos de 320x180 que entran en el monitor.


func test_only_sizes_that_fit_the_screen() -> void:
	var expected: Array[int] = [2, 3, 4, 5]
	assert_eq(WindowScales.available(Vector2i(1904, 1000)), expected, "monitor de 1080p: hasta 1600x900")
	var exact: Array[int] = [2, 3, 4]
	assert_eq(WindowScales.available(Vector2i(1280, 720)), exact, "entra justo")
	var tiny: Array[int] = [WindowScales.MIN_SCALE]
	assert_eq(WindowScales.available(Vector2i(500, 300)), tiny, "siempre queda la más chica")


func test_next_cycles_and_wraps() -> void:
	var options: Array[int] = [2, 3, 4, 5]
	assert_eq(WindowScales.next(4, options), 5)
	assert_eq(WindowScales.next(5, options), 2, "después de la más grande, la más chica")
	assert_eq(WindowScales.next(8, options), 2, "una guardada que ya no entra")


func test_text_pixels_always_cover_whole_screen_pixels() -> void:
	assert_eq(WindowScales.scale_for(Vector2i(1280, 720)), 4)
	assert_eq(WindowScales.scale_for(Vector2i(1920, 1080)), 6)
	assert_eq(WindowScales.scale_for(Vector2i(1366, 768)), 4, "con bordes: la escala entera que entra")
	for scale: int in range(1, WindowScales.MAX_SCALE + 1):
		var text_pixel: float = scale / WindowScales.text_oversampling(scale)
		assert_eq(text_pixel, roundf(text_pixel), "escala %d: píxel de letra entero" % scale)
	assert_eq(WindowScales.text_oversampling(4), 2.0, "en 1280x720, medio píxel del mundo")


func test_fit_falls_back_to_the_biggest_that_fits() -> void:
	var options: Array[int] = [2, 3, 4]
	assert_eq(WindowScales.fit(6, options), 4)
	assert_eq(WindowScales.fit(3, options), 3)
	assert_eq(WindowScales.size_of(4), Vector2i(1280, 720))
