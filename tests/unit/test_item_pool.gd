extends GutTest
## ItemPool: respeta los pools, no repite, devuelve relleno al vaciarse y pesa las calidades.


func _item(id: StringName, pools: int, quality: ItemData.Quality = ItemData.Quality.C) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.pools = pools
	item.quality = quality
	return item


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_only_items_of_the_pool_come_out() -> void:
	var items: Array[ItemData] = [_item(&"a", ItemData.POOL_TREASURE), _item(&"b", ItemData.POOL_SHOP)]
	var pool := ItemPool.new(items, _item(&"relleno", 0))
	assert_eq(pool.draw(ItemData.POOL_SHOP, _rng(1)).id, &"b")


func test_items_never_repeat_and_then_filler() -> void:
	var items: Array[ItemData] = [_item(&"a", ItemData.POOL_TREASURE), _item(&"b", ItemData.POOL_TREASURE)]
	var pool := ItemPool.new(items, _item(&"relleno", 0))
	var rng := _rng(5)
	var first: ItemData = pool.draw(ItemData.POOL_TREASURE, rng)
	var second: ItemData = pool.draw(ItemData.POOL_TREASURE, rng)
	assert_ne(first.id, second.id, "no repite")
	assert_eq(pool.draw(ItemData.POOL_TREASURE, rng).id, &"relleno", "vacío = relleno")
	assert_eq(pool.draw(ItemData.POOL_TREASURE, rng).id, &"relleno", "el relleno se repite")


func test_taken_items_leave_every_pool() -> void:
	var both: int = ItemData.POOL_TREASURE | ItemData.POOL_SHOP
	var items: Array[ItemData] = [_item(&"a", both)]
	var pool := ItemPool.new(items, _item(&"relleno", 0))
	assert_eq(pool.draw(ItemData.POOL_TREASURE, _rng(1)).id, &"a")
	assert_eq(pool.remaining(ItemData.POOL_SHOP), 0, "tampoco sale en la tienda")


func test_mark_taken_removes_an_item() -> void:
	var a: ItemData = _item(&"a", ItemData.POOL_TREASURE)
	var items: Array[ItemData] = [a]
	var pool := ItemPool.new(items, _item(&"relleno", 0))
	pool.mark_taken(a)
	assert_eq(pool.remaining(ItemData.POOL_TREASURE), 0)


func test_same_seed_same_draws() -> void:
	var items: Array[ItemData] = []
	for i: int in 10:
		items.append(_item(StringName("i%d" % i), ItemData.POOL_TREASURE, i % ItemData.Quality.size() as ItemData.Quality))
	var first := ItemPool.new(items, null)
	var second := ItemPool.new(items, null)
	var rng_a := _rng(77)
	var rng_b := _rng(77)
	for _i: int in 6:
		assert_eq(first.draw(ItemData.POOL_TREASURE, rng_a).id, second.draw(ItemData.POOL_TREASURE, rng_b).id)


func test_quality_weights_favor_c_in_shop() -> void:
	var common_wins: int = 0
	var rare_wins: int = 0
	for seed_value: int in 400:
		var items: Array[ItemData] = [
			_item(&"comun", ItemData.POOL_SHOP, ItemData.Quality.C),
			_item(&"rara", ItemData.POOL_SHOP, ItemData.Quality.A),
		]
		var drawn: ItemData = ItemPool.new(items, null).draw(ItemData.POOL_SHOP, _rng(seed_value))
		if drawn.id == &"comun":
			common_wins += 1
		else:
			rare_wins += 1
	# Pesos 1.0 contra 0.15: la común sale ~87 % de las veces.
	assert_between(common_wins / 400.0, 0.8, 0.94)
	assert_gt(rare_wins, 0, "la rara también puede salir")


func test_every_pool_weighs_every_quality_and_better_is_rarer() -> void:
	for pool: int in ItemPool.QUALITY_WEIGHTS:
		var weights: Array = ItemPool.QUALITY_WEIGHTS[pool]
		assert_eq(weights.size(), ItemData.Quality.size(), "pool %d: un peso por calidad" % pool)
		assert_gt(weights[ItemData.Quality.A], weights[ItemData.Quality.S], "pool %d: S más raro que A" % pool)
		assert_gte(weights[ItemData.Quality.S], weights[ItemData.Quality.S_PLUS_PLUS], "pool %d: S++ el más raro" % pool)


func test_the_shop_never_sells_s_plus_plus() -> void:
	var items: Array[ItemData] = [_item(&"spp", ItemData.POOL_SHOP, ItemData.Quality.S_PLUS_PLUS)]
	assert_eq(ItemPool.new(items, _item(&"relleno", 0)).draw(ItemData.POOL_SHOP, _rng(3)).id, &"relleno")


func test_secret_gives_the_best_chance_of_s_plus_plus() -> void:
	var weights: Dictionary[int, Array] = ItemPool.QUALITY_WEIGHTS
	var secret: float = weights[ItemData.POOL_SECRET][ItemData.Quality.S_PLUS_PLUS]
	for pool: int in [ItemData.POOL_TREASURE, ItemData.POOL_BOSS, ItemData.POOL_SHOP]:
		assert_gt(secret, weights[pool][ItemData.Quality.S_PLUS_PLUS])
