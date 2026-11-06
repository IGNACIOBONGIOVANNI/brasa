class_name PedestalInfo
extends Control
## Cartel de abajo con el item del pedestal más cercano al jugador: el nombre (del color de su
## calidad), qué es, cuánto cuesta y su descripción, la misma que en la Mochila (ItemData.describe).
## Solo fuera de combate (sin enemigos vivos) y con el jugador a REACH px o menos; con varios cerca
## (la tienda), el más cercano. Va abajo en el medio, o arriba si el jugador está en la mitad de abajo
## de la pantalla (así nunca lo tapa).

## Hasta dónde se lee un pedestal: más que lo que hace falta para agarrarlo, así se lee antes de tocarlo.
const REACH: float = 44.0
const PADDING: float = 3.0
const BACK_COLOR: Color = Color(0.05, 0.04, 0.07, 0.82)
const BORDER_COLOR: Color = Color("4b4357")
const KIND_COLOR: Color = Color("b8b0c8")
const TEXT_COLOR: Color = Color("f2efe6")
## Con el jugador más abajo que esto (en la pantalla de 320 x 180) el cartel sube.
const SCREEN_MIDDLE: float = 90.0
## Dónde va el cartel cuando sube (debajo de los corazones).
const TOP_Y: float = 20.0

var player: Player
var _pedestal_id: int = 0
var _item: ItemData
var _price: int = -1
## Arriba o abajo, y la altura de abajo (la que le dio el HUD).
var _at_top: bool = false
var _bottom_y: float = 0.0
var _box: VBoxContainer
var _title: Label
var _kind: Label
var _text: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_y = position.y
	_box = VBoxContainer.new()
	_box.add_theme_constant_override(&"separation", 0)
	add_child(_box)
	_title = MenuBuilder.label("", 8)
	_kind = MenuBuilder.label("", 8, KIND_COLOR)
	_text = MenuBuilder.label("", 8, TEXT_COLOR)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label: Label in [_title, _kind, _text]:
		label.custom_minimum_size = Vector2(size.x - PADDING * 2.0, 0)
		_box.add_child(label)
	_box.resized.connect(_layout)
	visible = false


## El item que está mostrando (null si no hay cartel).
func shown_item() -> ItemData:
	return _item if visible else null


func is_at_top() -> bool:
	return _at_top


func title_text() -> String:
	return _title.text


func kind_text() -> String:
	return _kind.text


func description_text() -> String:
	return _text.text


func _process(_delta: float) -> void:
	var pedestal: ItemPedestal = _nearest()
	if pedestal == null:
		visible = false
		_item = null
		_pedestal_id = 0
		return
	if pedestal.get_instance_id() != _pedestal_id or pedestal.item != _item or pedestal.price != _price:
		_fill(pedestal)
	var top: bool = player.get_global_transform_with_canvas().origin.y > SCREEN_MIDDLE
	if top != _at_top:
		_at_top = top
		position.y = TOP_Y if top else _bottom_y
		_layout()
	visible = true


## El pedestal con item más cercano al jugador, si está a REACH o menos y no hay pelea.
func _nearest() -> ItemPedestal:
	if not is_instance_valid(player) or player.is_dead() or _in_combat():
		return null
	var best: ItemPedestal = null
	var best_distance: float = REACH
	for node: Node in get_tree().get_nodes_in_group(ItemPedestal.GROUP):
		var pedestal := node as ItemPedestal
		if pedestal.item == null or pedestal.is_queued_for_deletion():
			continue
		var distance: float = pedestal.global_position.distance_to(player.global_position)
		if distance <= best_distance:
			best = pedestal
			best_distance = distance
	return best


func _in_combat() -> bool:
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		if not node.is_queued_for_deletion():
			return true
	return false


func _fill(pedestal: ItemPedestal) -> void:
	_pedestal_id = pedestal.get_instance_id()
	_item = pedestal.item
	_price = pedestal.price
	_title.text = "%s · %s" % [_item.display_name, _item.quality_name()]
	_title.add_theme_color_override(&"font_color", _item.quality_color())
	var parts: PackedStringArray = [kind_name(_item)]
	var cost: String = price_text(pedestal.price, pedestal.health_price)
	if cost != "":
		parts.append(cost)
	_kind.text = " · ".join(parts)
	_text.text = _item.describe()


## Qué es el item, en pocas palabras.
static func kind_name(item: ItemData) -> String:
	match item.kind:
		ItemData.Kind.WEAPON:
			return "Arma"
		ItemData.Kind.ACTIVE:
			return "Activo (se carga en %d salas)" % item.max_charge
	return "Pasivo"


## Lo que cuesta llevárselo ("" si es gratis).
static func price_text(price: int, health_price: int) -> String:
	if price > 0:
		return "%d moneda%s" % [price, "" if price == 1 else "s"]
	if health_price > 0:
		var hearts: int = ceili(health_price * 0.5)
		return "cuesta %d corazón%s de vida máxima" % [hearts, "" if hearts == 1 else "es"]
	return ""


## Abajo, el cartel crece para arriba desde el borde de abajo; arriba, para abajo desde el de arriba.
func _layout() -> void:
	_box.position = Vector2(PADDING, PADDING if _at_top else size.y - _box.size.y - PADDING)
	queue_redraw()


func _draw() -> void:
	var back := Rect2(_box.position - Vector2.ONE * PADDING, _box.size + Vector2.ONE * PADDING * 2.0)
	draw_rect(back, BACK_COLOR)
	draw_rect(back, BORDER_COLOR, false, 1.0)
