extends GutTest
## Hito 13: armas nuevas (lanzagranadas, bazuca, franco tirador, caño de riel) y estados (fuego, veneno,
## corrupción, apagado) en la arena de pruebas.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")
const FAROL: EnemyData = preload("res://content/enemies/farol.tres")
const USED_ACTIONS: Array[StringName] = [&"shoot", &"aim_right", &"dodge"]

var _game: Game
var _player: Player


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.health.always_invulnerable = true


func after_each() -> void:
	for action: StringName in USED_ACTIONS:
		Input.action_release(action)


func _weapon(id: String) -> WeaponData:
	return load("res://content/weapons/%s.tres" % id) as WeaponData


## Un muñeco quieto con mucha vida.
func _dummy(at: Vector2) -> Enemy:
	var data := FAROL.duplicate() as EnemyData
	data.spawn_delay = 30.0
	data.max_health = 100.0
	return _game.spawn_enemy(data, at)


## Una bala del jugador con estos estados seguros, contra `target` desde la izquierda.
func _status_shot(target: Enemy, burn: float, poison: float, corrupt: float, douse: float) -> void:
	var spec := ShotSpec.from_pattern(BulletPatternData.new())
	spec.damage = 2.0
	spec.burn_chance = burn
	spec.poison_chance = poison
	spec.corrupt_chance = corrupt
	spec.douse_chance = douse
	Bullet.spawn(get_tree(), BULLET_SCENE, spec, target.global_position + Vector2(-14, 0), Vector2.RIGHT,
			PhysicsLayers.PLAYER_BULLET, PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX)


func test_fire_keeps_burning_after_the_hit() -> void:
	var dummy: Enemy = _dummy(Vector2(0, -50))
	await wait_physics_frames(1)
	_status_shot(dummy, 1.0, 0.0, 0.0, 0.0)
	await wait_physics_frames(10)
	assert_true(dummy.status.has(StatusComponent.Kind.BURN), "se prendió fuego")
	var after_hit: float = dummy.health.current
	await wait_seconds(1.2)
	assert_lt(dummy.health.current, after_hit, "sigue quemándose")
	await wait_physics_frames(2)


func test_poison_stacks_up_to_its_max() -> void:
	var dummy: Enemy = _dummy(Vector2(0, -50))
	await wait_physics_frames(1)
	for _i: int in StatusComponent.POISON_MAX_STACKS + 2:
		dummy.status.apply(StatusComponent.Kind.POISON, 2.0)
	assert_eq(dummy.status.poison_stacks(), StatusComponent.POISON_MAX_STACKS)
	var before: float = dummy.health.current
	await wait_seconds(1.1)
	assert_lt(dummy.health.current, before, "el veneno lastima")


func test_corruption_raises_damage_and_bursts_on_death() -> void:
	var dummy: Enemy = _dummy(Vector2(0, -50))
	await wait_physics_frames(1)
	dummy.status.apply(StatusComponent.Kind.CORRUPT, 4.0)
	var before: float = dummy.health.current
	dummy.hurtbox.receive_hit(HitInfo.create(10.0, Vector2.RIGHT, 0.0))
	assert_almost_eq(before - dummy.health.current, 10.0 * StatusComponent.CORRUPT_DAMAGE_TAKEN, 0.01, "recibe más daño")
	dummy.health.kill()
	await wait_physics_frames(2)
	var shards: int = 0
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		if not (node as Bullet).is_hostile_to_player():
			shards += 1
	assert_eq(shards, StatusComponent.CORRUPT_BURST, "revienta en balas del jugador")
	await wait_physics_frames(2)


func test_doused_enemies_go_slower() -> void:
	var dummy: Enemy = _dummy(Vector2(0, -50))
	await wait_physics_frames(1)
	assert_eq(dummy.status.speed_factor(), 1.0)
	_status_shot(dummy, 0.0, 0.0, 0.0, 1.0)
	await wait_physics_frames(10)
	assert_eq(dummy.status.speed_factor(), StatusComponent.DOUSE_SPEED, "apagado va más lento")
	await wait_seconds(StatusComponent.DOUSE_TIME)
	assert_eq(dummy.status.speed_factor(), 1.0, "y se le pasa")


func test_rocket_explodes_on_the_first_enemy_and_hurts_the_next() -> void:
	RunState.add_weapon(_weapon("bazuca"))
	_player.global_position = Vector2(-60, 56)
	var first: Enemy = _dummy(Vector2(0, 56))
	var second: Enemy = _dummy(Vector2(16, 66))
	await wait_physics_frames(1)
	Input.action_press(&"aim_right")
	Input.action_press(&"shoot")
	await wait_physics_frames(2)
	Input.action_release(&"shoot")
	await wait_seconds(0.6)
	assert_lt(first.health.current, 100.0, "le pega al que choca")
	assert_lt(second.health.current, 100.0, "y al de al lado (explosión)")


func test_grenade_with_the_stick_lands_on_the_nearest_enemy_ahead() -> void:
	RunState.add_weapon(_weapon("lanzagranadas"))
	_player.global_position = Vector2(-60, 56)
	var near: Enemy = _dummy(Vector2(-20, 56))
	var far: Enemy = _dummy(Vector2(60, 56))
	await wait_physics_frames(1)
	Input.action_press(&"aim_right")
	Input.action_press(&"shoot")
	await wait_physics_frames(2)
	Input.action_release(&"shoot")
	await wait_seconds(1.0)
	assert_lt(near.health.current, 100.0, "cae en el más cercano hacia donde apunta")
	assert_eq(far.health.current, 100.0, "no se pasa hasta su alcance")


func test_grenade_flies_over_enemies_and_explodes_where_it_lands() -> void:
	var near: Enemy = _dummy(Vector2(-20, 56))
	var landing: Enemy = _dummy(Vector2(40, 56))
	await wait_physics_frames(1)
	var spec := ShotSpec.build(StatBlock.new(), _weapon("lanzagranadas"))
	Grenade.throw(get_tree(), load("res://entities/bullets/grenade.tscn") as PackedScene, spec, Vector2(-60, 56), Vector2(40, 56))
	await wait_seconds(1.0)
	assert_eq(near.health.current, 100.0, "pasa por arriba del de cerca")
	assert_lt(landing.health.current, 100.0, "explota donde cae")
	await wait_physics_frames(2)


func test_sniper_shows_its_sight_and_pierces_two() -> void:
	RunState.add_weapon(_weapon("franco_tirador"))
	_player.global_position = Vector2(-100, 56)
	var dummies: Array[Enemy] = [_dummy(Vector2(-40, 56)), _dummy(Vector2(0, 56)), _dummy(Vector2(40, 56))]
	await wait_physics_frames(2)
	Input.action_press(&"aim_right")
	await wait_physics_frames(2)
	assert_true((_player.weapon.get_node("AimSight") as AimSight).is_shown(), "mira láser")
	Input.action_press(&"shoot")
	await wait_physics_frames(2)
	Input.action_release(&"shoot")
	await wait_seconds(0.4)
	for dummy: Enemy in dummies:
		assert_lt(dummy.health.current, 100.0, "atraviesa dos y le pega al tercero")


func test_rail_fires_only_when_charged_and_rolling_cancels() -> void:
	RunState.add_weapon(_weapon("cano_de_riel"))
	var slot: WeaponSlot = RunState.current_weapon_slot()
	var ammo: int = slot.reserve
	_player.global_position = Vector2(-100, 56)
	var dummies: Array[Enemy] = [_dummy(Vector2(-20, 56)), _dummy(Vector2(40, 56))]
	await wait_physics_frames(2)
	Input.action_press(&"aim_right")
	Input.action_press(&"shoot")
	await wait_seconds(0.3)
	Input.action_release(&"shoot")
	await wait_physics_frames(3)
	assert_eq(slot.reserve, ammo, "soltado antes de cargar no dispara")
	assert_eq(dummies[0].health.current, 100.0)
	Input.action_press(&"shoot")
	await wait_seconds(0.5)
	Input.action_press(&"dodge")
	await wait_physics_frames(2)
	Input.action_release(&"dodge")
	assert_lt(_player.weapon.rail_charge(), 0.0, "rodar lo descarga")
	await wait_seconds(0.5)
	Input.action_release(&"shoot")
	await wait_physics_frames(2)
	assert_eq(slot.reserve, ammo, "y no gastó")
	Input.action_press(&"shoot")
	await wait_seconds(_weapon("cano_de_riel").charge_time + 0.1)
	Input.action_release(&"shoot")
	await wait_physics_frames(3)
	assert_eq(slot.reserve, ammo - 1, "cargado, al soltar dispara")
	for dummy: Enemy in dummies:
		assert_lt(dummy.health.current, 100.0, "el rayo atraviesa a todos")
	await wait_physics_frames(2)
