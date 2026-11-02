class_name WindGust
extends Node2D
## Una ráfaga de viento (solo se ve): rayitas que corren en `direction` durante `duration` s, en una
## franja de `width` px de ancho y `length` de largo que arranca acá, o (con `cone` > 0) en un
## abanico de `cone` grados. Se ve también en la oscuridad. El empujón lo da quien sopla
## (Player.push).

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const STREAKS: int = 22
const STREAK_LENGTH: float = 7.0
const COLOR: Color = Color(0.86, 0.93, 1.0, 0.75)
const FADE_IN: float = 0.15
const FADE_OUT: float = 0.3

var direction: Vector2 = Vector2.RIGHT
var length: float = 120.0
var width: float = 40.0
var cone: float = 0.0
var duration: float = 1.0
var speed: float = 240.0
var _elapsed: float = 0.0
var _seeds: PackedFloat32Array = []


func _ready() -> void:
	material = UNSHADED
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.COSMETIC)
	for i: int in STREAKS * 2:
		_seeds.append(rng.randf())


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade: float = clampf(minf(_elapsed / FADE_IN, (duration - _elapsed) / FADE_OUT), 0.0, 1.0)
	var side: Vector2 = direction.orthogonal()
	for i: int in STREAKS:
		var lateral: float = _seeds[i * 2] - 0.5
		var travel: float = fmod(_seeds[i * 2 + 1] * length + _elapsed * speed, length)
		var along: Vector2 = direction
		var start: Vector2 = side * lateral * width
		if cone > 0.0:
			along = direction.rotated(deg_to_rad(cone) * lateral)
			start = Vector2.ZERO
		start += along * travel
		draw_line(start, start + along * STREAK_LENGTH, Color(COLOR, COLOR.a * fade), 1.0)
