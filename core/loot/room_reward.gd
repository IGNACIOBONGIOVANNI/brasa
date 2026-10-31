class_name RoomReward
extends RefCounted
## Sorteo de la recompensa por limpiar una sala: con probabilidad `chance` sale un pickup, elegido
## según su reward_weight. Usar el stream LOOT.


static func roll(rng: RandomNumberGenerator, pickups: Array[PickupData], chance: float) -> PickupData:
	if rng.randf() >= chance:
		return null
	var total: float = 0.0
	for pickup: PickupData in pickups:
		total += maxf(0.0, pickup.reward_weight)
	if total <= 0.0:
		return null
	var pick: float = rng.randf() * total
	var last: PickupData = null
	for pickup: PickupData in pickups:
		if pickup.reward_weight <= 0.0:
			continue
		last = pickup
		pick -= pickup.reward_weight
		if pick < 0.0:
			return pickup
	return last
