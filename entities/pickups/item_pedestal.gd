class_name ItemPedestal
extends Area2D
## Pedestal con un item: gratis en el tesoro, con precio en la tienda. Se agarra al tocarlo si
## alcanzan las monedas. Si es un activo y el jugador ya tenía otro, el viejo queda en el pedestal
## (gratis) y hay que salir y volver a entrar para agarrarlo; lo mismo después de no tener plata.

const SPARKLE_SCENE: PackedScene = preload("res://fx/burst.tscn")

var item: ItemData
var price: int = 0
## Hasta que el jugador salga del pedestal no se intenta de nuevo.
var _waiting_exit: bool = false

@onready var _visual: ItemPedestalVisual = $Visual


## Se puede llamar antes de agregarlo al árbol.
func set_item(new_item: ItemData, new_price: int) -> void:
	item = new_item
	price = new_price
	if is_node_ready():
		_refresh_visual()


func _ready() -> void:
	_refresh_visual()


func _physics_process(_delta: float) -> void:
	var player: Player = null
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			player = body as Player
	if player == null:
		_waiting_exit = false
		return
	if _waiting_exit or item == null or player.is_dead():
		return
	_try_take()


func _try_take() -> void:
	if price > RunState.coins:
		_waiting_exit = true
		AudioManager.play_sfx(&"empty")
		return
	if price > 0:
		RunState.add_coins(-price)
		AudioManager.play_sfx(&"buy")
	var taken: ItemData = item
	var previous: ItemData = RunState.add_item(taken)
	EventBus.item_picked.emit(taken)
	AudioManager.play_sfx(&"item_pickup")
	var sparkle := Fx.spawn(get_tree(), SPARKLE_SCENE, global_position + Vector2(0, -10)) as CPUParticles2D
	sparkle.color = taken.get_icon_color()
	item = previous
	price = 0
	_waiting_exit = previous != null
	_refresh_visual()


func _refresh_visual() -> void:
	_visual.set_item(item, price)
