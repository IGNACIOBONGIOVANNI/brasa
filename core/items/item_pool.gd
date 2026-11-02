class_name ItemPool
extends RefCounted
## Sorteo de items de una run. Primero se tira la calidad con las chances del pool (tesoro, tienda,
## jefe, secreta) y después sale un item al azar de esa calidad. Un item nunca sale dos veces en la
## misma run: si la calidad que tocó ya no tiene items se baja a la de abajo y, si no queda nada
## abajo, se sube hasta A como mucho (S y S++ solo salen si los pide la tirada: si no, al vaciarse los
## comunes saldrían sí o sí). Si no queda nada devuelve el de relleno, que sí puede repetirse. Usar el
## stream LOOT.

## Chance de cada calidad (C, B, A, S, S++) en cada pool, en %. La tienda nunca vende S++; la secreta
## es la que más chances da de lo mejor.
const QUALITY_WEIGHTS: Dictionary[int, Array] = {
	ItemData.POOL_TREASURE: [50.0, 31.5, 15.0, 3.0, 0.5],
	ItemData.POOL_SHOP: [55.0, 30.0, 13.0, 2.0, 0.0],
	ItemData.POOL_BOSS: [20.0, 42.5, 29.0, 7.0, 1.5],
	ItemData.POOL_SECRET: [15.0, 36.0, 35.0, 10.0, 4.0],
}
## La calidad más alta a la que se puede subir cuando la que tocó está vacía.
const MAX_FALLBACK_QUALITY: int = ItemData.Quality.A

var _items: Array[ItemData] = []
var _filler: ItemData
var _taken: Dictionary[StringName, bool] = {}


func _init(items: Array[ItemData], filler: ItemData) -> void:
	_items = items.duplicate()
	_filler = filler


func draw(pool: int, rng: RandomNumberGenerator) -> ItemData:
	for quality: int in _fallback_order(roll_quality(pool, rng)):
		var candidates: Array[ItemData] = _candidates(pool, quality)
		if not candidates.is_empty():
			var chosen: ItemData = candidates[rng.randi_range(0, candidates.size() - 1)]
			_taken[chosen.id] = true
			return chosen
	return _filler


## Tira la calidad según las chances del pool.
static func roll_quality(pool: int, rng: RandomNumberGenerator) -> int:
	var weights: Array = QUALITY_WEIGHTS[pool]
	var total: float = 0.0
	for weight: float in weights:
		total += weight
	var pick: float = rng.randf() * total
	for quality: int in weights.size():
		pick -= weights[quality]
		if pick < 0.0:
			return quality
	return ItemData.Quality.C


## La calidad que tocó, después las de abajo y por último las de arriba hasta A.
static func _fallback_order(quality: int) -> Array[int]:
	var order: Array[int] = []
	for lower: int in range(quality, -1, -1):
		order.append(lower)
	for higher: int in range(quality + 1, MAX_FALLBACK_QUALITY + 1):
		order.append(higher)
	return order


func _candidates(pool: int, quality: int) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item: ItemData in _items:
		if item.quality == quality and item.is_in_pool(pool) and not _taken.has(item.id):
			result.append(item)
	return result


## Lo saca del sorteo (por ejemplo, si se consiguió por debug).
func mark_taken(item: ItemData) -> void:
	if item != _filler:
		_taken[item.id] = true


## ids de los items que ya salieron (para guardar la run).
func taken_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in _taken:
		result.append(id)
	return result


## Saca del sorteo un item por su id (al seguir una run guardada).
func mark_taken_id(id: StringName) -> void:
	if _filler == null or id != _filler.id:
		_taken[id] = true


func remaining(pool: int) -> int:
	var count: int = 0
	for item: ItemData in _items:
		if item.is_in_pool(pool) and not _taken.has(item.id):
			count += 1
	return count
