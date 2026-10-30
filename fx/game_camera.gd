class_name GameCamera
extends Camera2D
## Cámara fija de la sala con screenshake por "trauma": cada pedido suma, decae sola.
## El desplazamiento es lineal con el trauma (no al cuadrado) para que un disparo se note con
## ~1 px; los golpes fuertes piden más trauma. Se redondea a píxeles enteros.

@export var max_offset: Vector2 = Vector2(5, 4)
@export var decay_per_second: float = 1.5

var _trauma: float = 0.0


func _ready() -> void:
	EventBus.shake_requested.connect(add_trauma)


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	_trauma = maxf(0.0, _trauma - decay_per_second * delta)
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.COSMETIC)
	offset = Vector2(
		max_offset.x * _trauma * rng.randf_range(-1.0, 1.0),
		max_offset.y * _trauma * rng.randf_range(-1.0, 1.0)
	).round()
