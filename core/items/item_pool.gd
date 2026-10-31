class_name ItemPool
extends RefCounted
## Sorteo de items de una run. Cada pool (tesoro, tienda, jefe, secreta) pesa las rarezas distinto y
## un item nunca sale dos veces en la misma run. Si un pool se queda sin items devuelve el de relleno,
## que sí puede repetirse. Usar el stream LOOT.

## Peso de cada rareza (común, poco común, rara) según el pool.
const RARITY_WEIGHTS: Dictionary[int, Vector3] = {
	ItemData.POOL_TREASURE: Vector3(1.0, 0.6, 0.3),
	ItemData.POOL_SHOP: Vector3(1.0, 0.5, 0.15),
	ItemData.POOL_BOSS: Vector3(0.4, 1.0, 0.6),
	ItemData.POOL_SECRET: Vector3(0.6, 1.0, 0.5),
}

var _items: Array[ItemData] = []
var _filler: ItemData
var _taken: Dictionary[StringName, bool] = {}


func _init(items: Array[ItemData], filler: ItemData) -> void:
	_items = items.duplicate()
	_filler = filler


func draw(pool: int, rng: RandomNumberGenerator) -> ItemData:
	var candidates: Array[ItemData] = []
	var weights: Array[float] = []
	var total: float = 0.0
	for item: ItemData in _items:
		if item.is_in_pool(pool) and not _taken.has(item.id):
			var weight: float = RARITY_WEIGHTS[pool][item.rarity]
			candidates.append(item)
			weights.append(weight)
			total += weight
	if candidates.is_empty() or total <= 0.0:
		return _filler
	var pick: float = rng.randf() * total
	var chosen: ItemData = candidates[candidates.size() - 1]
	for i: int in candidates.size():
		pick -= weights[i]
		if pick < 0.0:
			chosen = candidates[i]
			break
	_taken[chosen.id] = true
	return chosen


## Lo saca del sorteo (por ejemplo, si se consiguió por debug).
func mark_taken(item: ItemData) -> void:
	if item != _filler:
		_taken[item.id] = true


func remaining(pool: int) -> int:
	var count: int = 0
	for item: ItemData in _items:
		if item.is_in_pool(pool) and not _taken.has(item.id):
			count += 1
	return count
