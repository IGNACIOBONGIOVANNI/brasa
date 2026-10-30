class_name Player
extends CharacterBody2D
## Jugador: movimiento con aceleración y fricción, mira con mouse o stick derecho, disparo.
## Se apunta con el último dispositivo usado: mover el mouse vuelve a la mira por mouse,
## inclinar el stick derecho la pasa al stick.

const GROUP: StringName = &"player"
const STICK_AIM_DEADZONE: float = 0.35

@export var acceleration: float = 1000.0
@export var friction: float = 1200.0

var aim_direction: Vector2 = Vector2.RIGHT
var _aim_with_mouse: bool = true

@onready var _visual: PlayerVisual = $Visual
@onready var _weapon: WeaponComponent = $WeaponComponent


func _ready() -> void:
	add_to_group(GROUP)
	_weapon.fired.connect(_on_weapon_fired)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_aim_with_mouse = true


func _physics_process(delta: float) -> void:
	var stats: StatBlock = RunState.stats
	_move(stats, delta)
	_update_aim()
	if Input.is_action_pressed(&"shoot"):
		_weapon.try_fire(stats, aim_direction)


func _move(stats: StatBlock, delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var rate: float = acceleration if input_dir != Vector2.ZERO else friction
	velocity = velocity.move_toward(input_dir * stats.move_speed, rate * delta)
	move_and_slide()


func _update_aim() -> void:
	var stick: Vector2 = Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	if stick.length() > STICK_AIM_DEADZONE:
		_aim_with_mouse = false
		aim_direction = stick.normalized()
	elif _aim_with_mouse:
		var to_mouse: Vector2 = get_global_mouse_position() - _weapon.global_position
		if to_mouse.length() > 1.0:
			aim_direction = to_mouse.normalized()
	_visual.set_aim(aim_direction)


func _on_weapon_fired(_direction: Vector2) -> void:
	_visual.play_fire()
