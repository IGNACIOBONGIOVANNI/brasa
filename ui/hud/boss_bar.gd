class_name BossBar
extends Control
## Barra de vida del jefe (abajo, adentro de la sala): nombre, vida y marcas donde cambia de fase.
## Aparece con EventBus.boss_spawned y se va cuando el jefe muere o sale de la escena (cambio de piso).

const BAR_HEIGHT: float = 4.0
const OUTLINE_COLOR: Color = Color("120c16")
const EMPTY_COLOR: Color = Color("3a2a3f")
const FILL_COLOR: Color = Color("e0464e")
const HIT_COLOR: Color = Color("f2efe6")
const HIT_FLASH: float = 0.08

var _boss: Enemy
var _fraction: float = 1.0
var _flash_left: float = 0.0
var _name: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name = MenuBuilder.label("")
	_name.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	_name.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_name.position.y = -2.0
	add_child(_name)
	visible = false


func track(boss: Node2D) -> void:
	_boss = boss as Enemy
	if _boss == null:
		return
	_name.text = _boss.data.display_name
	_fraction = 1.0
	_boss.health.health_changed.connect(_on_health_changed)
	_boss.tree_exiting.connect(untrack.bind(_boss), CONNECT_ONE_SHOT)
	visible = true
	queue_redraw()


func untrack(boss_node: Node2D) -> void:
	if _boss != null and boss_node != _boss:
		return
	_boss = null
	visible = false


func _on_health_changed(current: float, max_value: float) -> void:
	_fraction = clampf(current / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	_flash_left = HIT_FLASH
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
		queue_redraw()


func _draw() -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	var bar := Rect2(0, size.y - BAR_HEIGHT, size.x, BAR_HEIGHT)
	draw_rect(bar.grow(1.0), OUTLINE_COLOR)
	draw_rect(bar, EMPTY_COLOR)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _fraction, bar.size.y)), HIT_COLOR if _flash_left > 0.0 else FILL_COLOR)
	for boss_phase: BossPhase in _boss.data.phases:
		if boss_phase.health_fraction < 1.0:
			var x: float = bar.position.x + bar.size.x * boss_phase.health_fraction
			draw_rect(Rect2(x, bar.position.y, 1.0, bar.size.y), OUTLINE_COLOR)
