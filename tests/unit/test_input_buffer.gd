extends GutTest
## InputBuffer: guarda pulsaciones unos ticks y las entrega una sola vez.

var _buffer: InputBuffer


func before_each() -> void:
	_buffer = InputBuffer.new(0.1)


func test_pressed_action_is_consumed_once() -> void:
	_buffer.press(&"dodge")
	assert_true(_buffer.is_buffered(&"dodge"))
	assert_true(_buffer.consume(&"dodge"))
	assert_false(_buffer.consume(&"dodge"), "ya se usó")


func test_unpressed_action_is_not_buffered() -> void:
	assert_false(_buffer.consume(&"dodge"))


func test_press_expires_after_window() -> void:
	_buffer.press(&"dodge")
	_buffer.advance(0.05)
	assert_true(_buffer.is_buffered(&"dodge"), "dentro de la ventana")
	_buffer.advance(0.06)
	assert_false(_buffer.is_buffered(&"dodge"), "pasó la ventana")


func test_window_counts_physics_ticks() -> void:
	_buffer.press(&"dodge")
	for _i: int in 5:
		_buffer.advance(1.0 / 60.0)
	assert_true(_buffer.is_buffered(&"dodge"), "5 ticks después sigue")
	for _i: int in 2:
		_buffer.advance(1.0 / 60.0)
	assert_false(_buffer.is_buffered(&"dodge"), "7 ticks después ya no")


func test_pressing_again_refreshes_the_window() -> void:
	_buffer.press(&"shoot")
	_buffer.advance(0.08)
	_buffer.press(&"shoot")
	_buffer.advance(0.08)
	assert_true(_buffer.is_buffered(&"shoot"))


func test_zero_delta_does_not_expire() -> void:
	# Durante el hit-stop el juego avanza con delta 0.
	_buffer.press(&"blank")
	for _i: int in 100:
		_buffer.advance(0.0)
	assert_true(_buffer.is_buffered(&"blank"))


func test_actions_are_independent() -> void:
	_buffer.press(&"dodge")
	assert_false(_buffer.consume(&"blank"))
	assert_true(_buffer.is_buffered(&"dodge"))


func test_clear_forgets_everything() -> void:
	_buffer.press(&"dodge")
	_buffer.press(&"shoot")
	_buffer.clear()
	assert_false(_buffer.is_buffered(&"dodge"))
	assert_false(_buffer.is_buffered(&"shoot"))
