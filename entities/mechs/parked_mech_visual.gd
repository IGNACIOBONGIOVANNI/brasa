class_name ParkedMechVisual
extends Node2D
## Dibujo de un armazón parado: cabina vacía, el arma mirando abajo y una luz que titila para avisar
## que se puede subir.

const BLINK_SPEED: float = 2.5

var _data: MechData
var _armor_fraction: float = 1.0
var _time: float = 0.0


func configure(data: MechData, armor_fraction: float) -> void:
	_data = data
	_armor_fraction = armor_fraction
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _data == null:
		return
	MechDrawing.draw(self, _data, Vector2(0.4, 0.9).normalized(), -1, Color.TRANSPARENT, _data.weapon.gun_color,
			_data.weapon.gun_length, 0.0, _armor_fraction, _time)
	if sin(_time * BLINK_SPEED * TAU) > 0.0:
		draw_rect(Rect2(MechDrawing.beacon(_data, true) + Vector2(-1, -2), Vector2(2, 2)), _data.accent_color)
