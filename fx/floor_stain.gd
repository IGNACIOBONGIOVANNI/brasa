class_name FloorStain
extends Node2D
## Mancha que deja un enemigo al morir: queda unos segundos en el piso y se desvanece.

const LIFETIME: float = 8.0
const FADE_TIME: float = 2.5
const DROPLETS: int = 3

@export var color: Color = Color(0.4, 0.15, 0.15)
@export var radius: float = 7.0

var _age: float = 0.0
## Gotas alrededor de la mancha: x, y = posición, z = radio.
var _droplets: Array[Vector3] = []


func _ready() -> void:
	# Forma un poco irregular con el stream cosmético (no afecta al juego).
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.COSMETIC)
	for _i: int in DROPLETS:
		var offset := Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.8, 1.3)
		_droplets.append(Vector3(offset.x, offset.y * 0.5, rng.randf_range(1.0, 2.0)))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
	elif _age > LIFETIME - FADE_TIME:
		modulate.a = (LIFETIME - _age) / FADE_TIME


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO)
	for droplet: Vector3 in _droplets:
		draw_circle(Vector2(droplet.x, droplet.y), droplet.z, color)
