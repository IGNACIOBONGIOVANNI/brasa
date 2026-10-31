extends GutTest
## RoomReward: la probabilidad de premio y los pesos de cada pickup se respetan.

const ROLLS: int = 4000


func _pickup(id: StringName, weight: float) -> PickupData:
	var pickup := PickupData.new()
	pickup.id = id
	pickup.reward_weight = weight
	return pickup


func _counts(pickups: Array[PickupData], chance: float) -> Dictionary[StringName, int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var counts: Dictionary[StringName, int] = {&"nada": 0}
	for pickup: PickupData in pickups:
		counts[pickup.id] = 0
	for _i: int in ROLLS:
		var result: PickupData = RoomReward.roll(rng, pickups, chance)
		var key: StringName = result.id if result != null else &"nada"
		counts[key] += 1
	return counts


func test_chance_controls_how_often_there_is_a_reward() -> void:
	var pickups: Array[PickupData] = [_pickup(&"moneda", 1.0)]
	var counts: Dictionary[StringName, int] = _counts(pickups, 0.6)
	assert_almost_eq(counts[&"moneda"] / float(ROLLS), 0.6, 0.04)


func test_weights_split_the_rewards() -> void:
	var pickups: Array[PickupData] = [_pickup(&"moneda", 3.0), _pickup(&"llave", 1.0)]
	var counts: Dictionary[StringName, int] = _counts(pickups, 1.0)
	assert_eq(counts[&"nada"], 0)
	assert_almost_eq(counts[&"moneda"] / float(ROLLS), 0.75, 0.04)


func test_zero_weight_never_drops() -> void:
	var pickups: Array[PickupData] = [_pickup(&"moneda", 1.0), _pickup(&"nunca", 0.0)]
	assert_eq(_counts(pickups, 1.0)[&"nunca"], 0)


func test_zero_chance_never_drops() -> void:
	var pickups: Array[PickupData] = [_pickup(&"moneda", 1.0)]
	assert_eq(_counts(pickups, 0.0)[&"moneda"], 0)
