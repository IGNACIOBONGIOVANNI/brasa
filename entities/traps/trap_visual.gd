class_name TrapVisual
extends Node2D
## Dibujo placeholder de una trampa según su TrapData.Look y su etapa:
## SPIKES: placa con agujeros; avisa asomando las puntas y sale con púas.
## VENT: rejilla redonda; avisa con burbujas y larga una nube de gas del radio del daño.
## POD: vaina de esporas que respira; al avisar se hincha y brilla, revienta en un anillo de esporas y
## queda arrugada mientras se rearma.
## NOZZLE: boquilla de metal; avisa con la ranura al rojo y escupe un chorro de llama en `direction`.

const PLATE_COLOR: Color = Color("3a3344")
const PLATE_LIGHT_COLOR: Color = Color("4b4357")
const OUTLINE_COLOR: Color = Color("120c16")
const HOLE_COLOR: Color = Color("0c080f")
const HOT_COLOR: Color = Color("fff2b0")

var _data: TrapData
var _direction: Vector2 = Vector2.RIGHT
var _stage: Trap.Stage = Trap.Stage.REST
var _progress: float = 0.0
var _recovering: bool = false
var _time: float = 0.0


func configure(data: TrapData, direction: Vector2) -> void:
	_data = data
	_direction = direction
	queue_redraw()


## `recovering`: quieta pero todavía sin poder activarse (la vaina se ve arrugada).
func show_stage(stage: Trap.Stage, progress: float, recovering: bool) -> void:
	_stage = stage
	_progress = progress
	_recovering = recovering
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _stage != Trap.Stage.REST or _data != null and _data.look == TrapData.Look.POD:
		queue_redraw()


func _draw() -> void:
	if _data == null:
		return
	match _data.look:
		TrapData.Look.SPIKES:
			_draw_spikes()
		TrapData.Look.VENT:
			_draw_vent()
		TrapData.Look.POD:
			_draw_pod()
		TrapData.Look.NOZZLE:
			_draw_nozzle()


func _blink() -> bool:
	return int(_time * 12.0) % 2 == 0


func _draw_spikes() -> void:
	draw_rect(Rect2(-7, -7, 14, 14), OUTLINE_COLOR)
	draw_rect(Rect2(-6, -6, 12, 12), PLATE_COLOR)
	draw_rect(Rect2(-6, -6, 12, 1), PLATE_LIGHT_COLOR)
	for y: int in 3:
		for x: int in 3:
			var at := Vector2(-4 + x * 4, -4 + y * 4)
			match _stage:
				Trap.Stage.REST:
					draw_rect(Rect2(at - Vector2(0.5, 0.5), Vector2(2, 2)), HOLE_COLOR)
				Trap.Stage.WARN:
					draw_rect(Rect2(at - Vector2(0.5, 0.5), Vector2(2, 2)), HOLE_COLOR)
					draw_rect(Rect2(at + Vector2(0, -1), Vector2(1, 1)), _data.color if _blink() else HOT_COLOR)
				Trap.Stage.ACTIVE:
					var tip: Vector2 = at + Vector2(0.5, -5)
					var spike := PackedVector2Array([at + Vector2(-1.5, 1), at + Vector2(2.5, 1), tip])
					draw_colored_polygon(spike, _data.color)
					draw_line(at + Vector2(-1.5, 1), tip, OUTLINE_COLOR, 1.0)


func _draw_vent() -> void:
	draw_circle(Vector2.ZERO, 6.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, 5.0, PLATE_COLOR)
	for x: int in [-3, -1, 1, 3]:
		draw_rect(Rect2(x - 0.5, -3, 1, 6), HOLE_COLOR)
	match _stage:
		Trap.Stage.WARN:
			for i: int in 3:
				var rise: float = fmod(_time * 1.8 + i * 0.33, 1.0)
				draw_rect(Rect2(Vector2(-3 + i * 3, -2 - rise * 8.0).round(), Vector2(2, 2)), Color(_data.color, 0.9 - rise * 0.6))
		Trap.Stage.ACTIVE:
			var fade: float = 1.0 - _progress * 0.5
			var wobble: float = sin(_time * 9.0) * 1.0
			draw_circle(Vector2.ZERO, _data.radius + wobble, Color(_data.color, 0.32 * fade))
			draw_circle(Vector2(-4, -3), _data.radius * 0.55, Color(_data.color, 0.3 * fade))
			draw_circle(Vector2(5, 2), _data.radius * 0.45, Color(_data.color, 0.3 * fade))
			draw_arc(Vector2.ZERO, _data.radius + wobble, 0.0, TAU, 24, Color(_data.color, 0.6 * fade), 1.0)


func _draw_pod() -> void:
	draw_set_transform(Vector2(0, 3), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	var shell: Color = _data.color.darkened(0.55)
	match _stage:
		Trap.Stage.REST:
			var size: float = 2.5 if _recovering else 4.0 + sin(_time * 2.0) * 0.4
			draw_circle(Vector2(0, -1), size + 1.0, OUTLINE_COLOR)
			draw_circle(Vector2(0, -1), size, shell)
			if not _recovering:
				draw_circle(Vector2(0, -2), 1.5, _data.color)
		Trap.Stage.WARN:
			var swell: float = 4.0 + _progress * 2.5
			draw_circle(Vector2(0, -1), swell + 1.0, OUTLINE_COLOR)
			draw_circle(Vector2(0, -1), swell, shell.lerp(_data.color, _progress * 0.6))
			draw_circle(Vector2(0, -2), 1.5 + _progress * 2.0, HOT_COLOR if _blink() else _data.color)
		Trap.Stage.ACTIVE:
			var ring: float = _data.radius * (0.4 + 0.6 * _progress)
			draw_arc(Vector2.ZERO, ring, 0.0, TAU, 28, Color(_data.color, 1.0 - _progress), 2.0)
			draw_circle(Vector2.ZERO, ring, Color(_data.color, 0.18 * (1.0 - _progress)))
			for i: int in 10:
				var at: Vector2 = (Vector2.from_angle(TAU * i / 10.0 + i) * ring * (0.5 + 0.5 * fmod(i * 0.37, 1.0))).round()
				draw_rect(Rect2(at, Vector2.ONE), _data.color)


func _draw_nozzle() -> void:
	draw_set_transform(Vector2.ZERO, _direction.angle())
	draw_rect(Rect2(-5, -5, 10, 10), OUTLINE_COLOR)
	draw_rect(Rect2(-4, -4, 8, 8), PLATE_COLOR)
	draw_rect(Rect2(-4, -4, 8, 1), PLATE_LIGHT_COLOR)
	var slit: Color = HOLE_COLOR
	if _stage == Trap.Stage.WARN:
		slit = _data.color if _blink() else HOT_COLOR
	elif _stage == Trap.Stage.ACTIVE:
		slit = HOT_COLOR
	draw_rect(Rect2(2, -2, 2, 4), slit)
	if _stage == Trap.Stage.WARN:
		for i: int in 3:
			var x: float = 6.0 + fmod(_time * 40.0 + i * 13.0, _data.length - 6.0)
			draw_rect(Rect2(x, -0.5 + (i - 1) * 2, 1, 1), _data.color)
	elif _stage == Trap.Stage.ACTIVE:
		var flicker: float = sin(_time * 30.0) * 1.0
		var half: float = _data.radius
		draw_rect(Rect2(4, -half - flicker * 0.5, _data.length - 4.0, half * 2.0 + flicker), Color(_data.color, 0.85))
		draw_rect(Rect2(4, -half * 0.5, _data.length - 8.0 + flicker * 2.0, half), HOT_COLOR)
	draw_set_transform(Vector2.ZERO)
