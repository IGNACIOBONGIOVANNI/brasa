class_name Pickup
extends Area2D
## Pickup en el piso (moneda, corazón, bomba o llave). Se agarra al tocarlo; el corazón solo si al
## jugador le falta vida (si no, queda ahí para después). Los premios de sala aparecen con un
## saltito y no se pueden agarrar hasta que caen.

const POP_TIME: float = 0.35
const POP_HEIGHT: float = 10.0
const SPARKLE_SCENE: PackedScene = preload("res://fx/bullet_impact.tscn")

@export var data: PickupData

var _pop_left: float = 0.0

@onready var _visual: PickupVisual = $Visual


func _ready() -> void:
	assert(data != null, "Pickup: falta asignar data (PickupData)")
	_visual.kind = data.kind


func pop() -> void:
	_pop_left = POP_TIME


func _physics_process(delta: float) -> void:
	if _pop_left > 0.0:
		_pop_left = maxf(0.0, _pop_left - delta)
		var t: float = 1.0 - _pop_left / POP_TIME
		_visual.position = Vector2(0, -POP_HEIGHT * 4.0 * t * (1.0 - t))
		return
	for body: Node2D in get_overlapping_bodies():
		var player := body as Player
		if player != null and _try_collect(player):
			return


func _try_collect(player: Player) -> bool:
	match data.kind:
		PickupData.Kind.HEART:
			if player.is_dead() or player.health.current >= player.health.max_health:
				return false
			player.health.heal(data.amount)
		PickupData.Kind.COIN:
			RunState.add_coins(data.amount)
		PickupData.Kind.BOMB:
			RunState.add_bombs(data.amount)
		PickupData.Kind.KEY:
			RunState.add_keys(data.amount)
	AudioManager.play_sfx(data.sfx_id, 0.05)
	var sparkle := Fx.spawn(get_tree(), SPARKLE_SCENE, global_position) as CPUParticles2D
	sparkle.color = _visual.main_color()
	queue_free()
	return true
