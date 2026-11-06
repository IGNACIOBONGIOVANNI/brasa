class_name ItemPedestal
extends Area2D
## Pedestal con un item: gratis en el tesoro, con precio en monedas en la tienda o en vida en el
## Altar (`health_price`, medios corazones de vida máxima: se entrega el contenedor entero, solo si
## queda al menos un corazón). Se agarra al tocarlo si alcanza.
## Si es un activo y el jugador ya tenía otro, el viejo queda en el pedestal (gratis) y hay que
## salir y volver a entrar para agarrarlo; lo mismo después de no alcanzar el precio.

## Se agarró el item (el Altar saca los otros pedestales).
signal item_taken

const SPARKLE_SCENE: PackedScene = preload("res://fx/burst.tscn")
const VANISH_SCENE: PackedScene = preload("res://fx/dust_puff.tscn")

var item: ItemData
var price: int = 0
var health_price: int = 0
## Hasta que el jugador salga del pedestal no se intenta de nuevo.
var _waiting_exit: bool = false

@onready var _visual: ItemPedestalVisual = $Visual


## Se puede llamar antes de agregarlo al árbol.
func set_item(new_item: ItemData, new_price: int, new_health_price: int = 0) -> void:
	item = new_item
	price = new_price
	health_price = new_health_price
	if is_node_ready():
		_refresh_visual()


## Desaparece con una nube de polvo (los pedestales del Altar que no se eligieron).
func vanish() -> void:
	Fx.spawn(get_tree(), VANISH_SCENE, global_position)
	queue_free()


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
	if price > RunState.coins or (health_price > 0 and not RunState.can_sacrifice(health_price)):
		_waiting_exit = true
		AudioManager.play_sfx(&"empty")
		return
	if price > 0:
		RunState.add_coins(-price)
		AudioManager.play_sfx(&"buy")
	if health_price > 0:
		RunState.sacrifice_health(health_price)
		AudioManager.play_sfx(&"altar")
	var taken: ItemData = item
	var previous: ItemData = RunState.add_item(taken)
	EventBus.item_picked.emit(taken)
	AudioManager.play_sfx(&"item_pickup")
	var sparkle := Fx.spawn(get_tree(), SPARKLE_SCENE, global_position + Vector2(0, -10)) as CPUParticles2D
	sparkle.color = taken.get_icon_color()
	item = previous
	price = 0
	health_price = 0
	_waiting_exit = previous != null
	_refresh_visual()
	item_taken.emit()


func _refresh_visual() -> void:
	_visual.set_item(item, price, health_price)
