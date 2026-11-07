class_name FlashComponent
extends Node
## Efectos de color sobre el dibujo de una entidad (el nodo `target`):
## - flash(): destello de un color, blanco al recibir daño.
## - blink(): parpadeo de transparencia durante los i-frames.
## - start_pulse() / stop_pulse(): destello intermitente mientras dura un telegraph.
## - fade: transparencia que se suma a todo lo anterior (la entrada de un jefe lo hace aparecer).

const SHADER: Shader = preload("res://fx/flash.gdshader")
const BLINK_PERIOD: float = 0.1
const BLINK_ALPHA: float = 0.3
const PULSE_PERIOD: float = 0.12
const PULSE_AMOUNT: float = 0.8

@export var target: CanvasItem

var _material: ShaderMaterial
var _flash_left: float = 0.0
var _flash_color: Color = Color.WHITE
var _blink_left: float = 0.0
var _pulsing: bool = false
var _pulse_color: Color = Color.WHITE
var _pulse_time: float = 0.0
## 1 = se ve entero, 0 = invisible.
var fade: float = 1.0


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	target.material = _material


func flash(duration: float, color: Color = Color.WHITE) -> void:
	_flash_left = duration
	_flash_color = color


func blink(duration: float) -> void:
	_blink_left = duration


func start_pulse(color: Color) -> void:
	_pulsing = true
	_pulse_color = color
	_pulse_time = 0.0


func stop_pulse() -> void:
	_pulsing = false


func _process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	_blink_left = maxf(0.0, _blink_left - delta)
	_pulse_time += delta
	var amount: float = 0.0
	var color: Color = _flash_color
	if _flash_left > 0.0:
		amount = 1.0
	elif _pulsing and fmod(_pulse_time, PULSE_PERIOD) < PULSE_PERIOD * 0.5:
		amount = PULSE_AMOUNT
		color = _pulse_color
	_material.set_shader_parameter(&"flash_amount", amount)
	_material.set_shader_parameter(&"flash_color", color)
	var blink_on: bool = _blink_left > 0.0 and fmod(_blink_left, BLINK_PERIOD) < BLINK_PERIOD * 0.5
	var tint: Color = target.modulate
	tint.a = (BLINK_ALPHA if blink_on else 1.0) * fade
	target.modulate = tint
