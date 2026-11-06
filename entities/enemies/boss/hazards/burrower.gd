class_name Burrower
extends Node2D
## Una raíz que avanza bajo tierra (BurrowersMove): un montículo que deja grietas atrás y persigue al
## jugador a `speed` px/s durante `hunt_time` s, adentro de `area`. Después se frena y deja en su lugar
## un golpe avisado (BossStrike de raíz: tiembla `warn_time` s y revienta en `radius`, con `pattern`).
## Mientras corre no lastima.

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const STRIKE_SCENE: PackedScene = preload("res://entities/enemies/boss_strike.tscn")
const DIRT: Color = Color("6b4a32")
const CRACK: Color = Color("9e6bc7")
const TRAIL_POINTS: int = 6
## Cuánto dobla por segundo (no puede dar la vuelta en el acto: se lo puede gambetear).
const TURN_RATE: float = 2.6

var speed: float = 60.0
var hunt_time: float = 2.0
var warn_time: float = 0.6
var radius: float = 14.0
var damage: float = 1.0
var pattern: BulletPatternData
var speed_multiplier: float = 1.0
var area: Rect2 = Rect2(-120, -72, 240, 144)
var direction: Vector2 = Vector2.DOWN
var _time: float = 0.0
var _trail: PackedVector2Array = []


func _ready() -> void:
	add_to_group(BossMove.HAZARD_GROUP)
	material = UNSHADED


func _physics_process(delta: float) -> void:
	_time += delta
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player != null:
		var wanted: Vector2 = player.global_position - global_position
		if wanted.length() > 1.0:
			var angle: float = direction.angle()
			var turn: float = clampf(angle_difference(angle, wanted.angle()), -TURN_RATE * delta, TURN_RATE * delta)
			direction = Vector2.from_angle(angle + turn)
	var next: Vector2 = global_position + direction * speed * delta
	global_position = Vector2(clampf(next.x, area.position.x, area.end.x), clampf(next.y, area.position.y, area.end.y))
	if _trail.is_empty() or _trail[-1].distance_to(global_position) >= 4.0:
		_trail.append(global_position)
		if _trail.size() > TRAIL_POINTS:
			_trail.remove_at(0)
	if _time >= hunt_time:
		_erupt()


func _erupt() -> void:
	var strike := Fx.spawn(get_tree(), STRIKE_SCENE, global_position) as BossStrike
	strike.look = BossAttack.Look.ROOT
	strike.warn_time = warn_time
	strike.damage = damage
	strike.radius = radius
	strike.pattern = pattern
	strike.speed_multiplier = speed_multiplier
	AudioManager.play_sfx(&"burrow", 0.1)
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for i: int in _trail.size():
		var at: Vector2 = _trail[i] - global_position
		var alpha: float = float(i + 1) / _trail.size()
		draw_rect(Rect2(at.round() - Vector2(1, 0), Vector2(2, 1)), Color(CRACK, 0.5 * alpha))
	var wobble: float = sin(_time * 18.0)
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 6.0, Color("1b1420"))
	draw_circle(Vector2.ZERO, 5.0, DIRT)
	draw_set_transform(Vector2.ZERO)
	for pebble: Vector2 in [Vector2(-3, -1), Vector2(2, -2), Vector2(0, 1)]:
		draw_rect(Rect2(pebble + Vector2(roundf(wobble), 0), Vector2.ONE), DIRT.lightened(0.35))
	draw_line(Vector2(-2, -1), Vector2(1, -4 - absf(wobble)), CRACK, 1.0)
