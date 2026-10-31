extends Node
## Estado de la run en curso: personaje, piso, tiempo, muertes y jefes vencidos (para el resumen y la
## meta-progresión), stats (los del personaje recalculados con los items), items pasivos, el activo y
## su carga, armas con su munición, el pool de items, cargas de Pulso y monedas, bombas y llaves.
## La vida vive en el HealthComponent del jugador.

signal stats_changed(stats: StatBlock)
signal blanks_changed(count: int)
signal inventory_changed(coins: int, bombs: int, keys: int)
signal items_changed
signal active_changed
signal weapons_changed

const CATALOG_PATH: String = "res://content/items/catalog.tres"
const BASE_WEAPON: WeaponData = preload("res://content/weapons/base_shot.tres")
## Cargas de Pulso al empezar la run.
const START_BLANKS: int = 2
const START_BOMBS: int = 1
## La llave del principio alcanza para abrir la tienda del primer piso.
const START_KEYS: int = 1
const MAX_COUNT: int = 99
## Fracción de la munición máxima que recupera cada arma al limpiar una sala.
const ROOM_CLEAR_AMMO: float = 0.25

var character: CharacterData
var base_stats: StatBlock = StatBlock.new()
var stats: StatBlock = StatBlock.new()
var blanks: int = START_BLANKS
var coins: int = 0
var bombs: int = START_BOMBS
var keys: int = START_KEYS
var items: Array[ItemData] = []
var active_item: ItemData
var active_charge: int = 0
var weapons: Array[WeaponSlot] = []
var current_weapon: int = 0
var item_pool: ItemPool
var floor_index: int = 0
var floor_name: String = ""
## Segundos jugados (sin contar pausas ni transiciones).
var run_time: float = 0.0
var kills: int = 0
## ids de los jefes vencidos en esta run.
var bosses_defeated: Array[StringName] = []


func _ready() -> void:
	EventBus.room_cleared.connect(_on_room_cleared)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	start_run()


## Empieza una run con ese personaje (null = el de por defecto). Los items bloqueados entran al pool
## solo si `profile` los tiene desbloqueados (null = perfil nuevo).
func start_run(run_character: CharacterData = null, profile: MetaProfile = null) -> void:
	character = run_character if run_character != null else MetaConfig.get_default().default_character()
	base_stats = character.stats.duplicate() as StatBlock
	floor_index = 0
	floor_name = ""
	run_time = 0.0
	kills = 0
	bosses_defeated.clear()
	items.clear()
	active_item = null
	active_charge = 0
	weapons = [WeaponSlot.new(BASE_WEAPON)]
	current_weapon = 0
	var catalog := load(CATALOG_PATH) as ItemCatalog
	var unlocks: MetaProfile = profile if profile != null else MetaProfile.new()
	item_pool = ItemPool.new(unlocks.available_items(catalog.items), catalog.filler)
	blanks = START_BLANKS
	coins = 0
	bombs = START_BOMBS
	keys = START_KEYS
	_recompute_stats()
	blanks_changed.emit(blanks)
	_inventory_changed()
	items_changed.emit()
	active_changed.emit()
	weapons_changed.emit()
	if character.start_item != null:
		add_item(character.start_item)


## Items que lleva: pasivos, el activo y las armas además de la pistola.
func item_count() -> int:
	return items.size() + (1 if active_item != null else 0) + weapons.size() - 1


## Lo que la meta-progresión necesita de la run que termina.
func make_record(victory: bool) -> RunRecord:
	var record := RunRecord.new()
	record.victory = victory
	record.floor_reached = floor_index + 1
	record.kills = kills
	record.items = item_count()
	record.bosses = bosses_defeated.duplicate()
	record.character = character.id
	return record


## Le da un item al jugador. Si es un activo y ya tenía otro, devuelve el viejo (para dejarlo en el
## pedestal); si no, null.
func add_item(item: ItemData) -> ItemData:
	item_pool.mark_taken(item)
	match item.kind:
		ItemData.Kind.ACTIVE:
			var previous: ItemData = active_item
			active_item = item
			active_charge = item.max_charge
			active_changed.emit()
			return previous
		ItemData.Kind.WEAPON:
			add_weapon(item.weapon)
		_:
			items.append(item)
			_recompute_stats()
			items_changed.emit()
	return null


## Agrega un arma y la equipa. Si ya la tenía, le llena la munición.
func add_weapon(data: WeaponData) -> void:
	for i: int in weapons.size():
		if weapons[i].weapon == data:
			weapons[i].refill(1.0)
			current_weapon = i
			weapons_changed.emit()
			return
	weapons.append(WeaponSlot.new(data))
	current_weapon = weapons.size() - 1
	weapons_changed.emit()


func current_weapon_slot() -> WeaponSlot:
	return weapons[current_weapon]


## Pasa a la siguiente arma. Devuelve false si hay una sola.
func select_next_weapon() -> bool:
	if weapons.size() < 2:
		return false
	current_weapon = (current_weapon + 1) % weapons.size()
	weapons_changed.emit()
	return true


func is_active_ready() -> bool:
	return active_item != null and active_charge >= active_item.max_charge


func spend_active() -> void:
	active_charge = 0
	active_changed.emit()


func charge_active(amount: int) -> void:
	if active_item == null:
		return
	var was_ready: bool = is_active_ready()
	active_charge = mini(active_item.max_charge, active_charge + amount)
	active_changed.emit()
	if not was_ready and is_active_ready():
		AudioManager.play_sfx(&"active_ready")


## Gasta una carga de Pulso. Devuelve false si no quedaba ninguna.
func use_blank() -> bool:
	if blanks <= 0:
		return false
	blanks -= 1
	blanks_changed.emit(blanks)
	return true


func set_blanks(count: int) -> void:
	blanks = maxi(0, count)
	blanks_changed.emit(blanks)


## Gasta una bomba. Devuelve false si no quedaba ninguna.
func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	_inventory_changed()
	return true


## Gasta una llave. Devuelve false si no quedaba ninguna.
func use_key() -> bool:
	if keys <= 0:
		return false
	keys -= 1
	_inventory_changed()
	return true


func add_coins(amount: int) -> void:
	coins = clampi(coins + amount, 0, MAX_COUNT)
	_inventory_changed()


func add_bombs(amount: int) -> void:
	bombs = clampi(bombs + amount, 0, MAX_COUNT)
	_inventory_changed()


func add_keys(amount: int) -> void:
	keys = clampi(keys + amount, 0, MAX_COUNT)
	_inventory_changed()


func _recompute_stats() -> void:
	stats = StatCalculator.compute(base_stats, items)
	stats_changed.emit(stats)


func _inventory_changed() -> void:
	inventory_changed.emit(coins, bombs, keys)


## Limpiar una sala carga el activo y devuelve algo de munición a cada arma.
func _on_room_cleared(_cell: Vector2i) -> void:
	charge_active(1)
	for slot: WeaponSlot in weapons:
		slot.refill(ROOM_CLEAR_AMMO)


func _on_enemy_killed(_enemy: Node2D) -> void:
	kills += 1


func _on_boss_defeated(boss: Node2D) -> void:
	var data := boss.get(&"data") as EnemyData
	if data != null:
		bosses_defeated.append(data.id)
