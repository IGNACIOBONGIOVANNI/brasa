class_name ItemHookRunner
extends Node
## Lleva los ItemHook de los items del jugador (los pasivos y el activo) y les reparte los eventos.
## Los eventos que llegan desde callbacks de física (golpes, muertes, daño) se despachan diferidos:
## un hook puede crear balas o nodos sin romper nada.

var _hooks: Dictionary[ItemData, ItemHook] = {}

@onready var _player: Player = owner as Player


func _ready() -> void:
	RunState.items_changed.connect(_sync)
	RunState.active_changed.connect(_sync)
	EventBus.enemy_hit.connect(_on_enemy_hit)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.room_cleared.connect(_on_room_cleared)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.pickup_collected.connect(_on_pickup_collected)
	_sync()


func on_shoot(direction: Vector2) -> void:
	var context: HookContext = _context(_player.global_position)
	context.direction = direction
	_dispatch(&"on_shoot", context)


## Usa el activo. Devuelve true si se usó.
func use_active() -> bool:
	var hook: ItemHook = _hooks.get(RunState.active_item)
	return hook != null and hook.on_use(_context(_player.global_position))


## Crea los hooks de los items nuevos y suelta los de los que ya no están (un activo reemplazado).
## Los que siguen conservan su estado (por ejemplo, contadores).
func _sync() -> void:
	var wanted: Array[ItemData] = RunState.items.duplicate()
	if RunState.active_item != null:
		wanted.append(RunState.active_item)
	for item: ItemData in _hooks.keys():
		if not wanted.has(item):
			_hooks.erase(item)
	for item: ItemData in wanted:
		if item.hook_script != null and not _hooks.has(item):
			var hook := item.hook_script.new() as ItemHook
			hook.item = item
			_hooks[item] = hook


func _context(at: Vector2) -> HookContext:
	var context := HookContext.new()
	context.player = _player
	context.position = at
	return context


func _dispatch(method: StringName, context: HookContext) -> void:
	if not is_inside_tree() or _player.is_dead():
		return
	for hook: ItemHook in _hooks.values():
		hook.call(method, context)


func _on_enemy_hit(enemy: Node2D, info: HitInfo) -> void:
	var context: HookContext = _context(enemy.global_position)
	context.enemy = enemy
	context.amount = info.damage
	_dispatch.call_deferred(&"on_hit", context)


func _on_enemy_killed(enemy: Node2D) -> void:
	var context: HookContext = _context(enemy.global_position)
	context.enemy = enemy
	_dispatch.call_deferred(&"on_kill", context)


func _on_room_cleared(cell: Vector2i) -> void:
	var context: HookContext = _context(_player.global_position)
	context.room_cell = cell
	_dispatch.call_deferred(&"on_room_clear", context)


func _on_player_damaged(amount: float) -> void:
	var context: HookContext = _context(_player.global_position)
	context.amount = amount
	_dispatch.call_deferred(&"on_damaged", context)


func _on_pickup_collected(pickup: PickupData) -> void:
	var context: HookContext = _context(_player.global_position)
	context.pickup = pickup
	_dispatch.call_deferred(&"on_pickup", context)
