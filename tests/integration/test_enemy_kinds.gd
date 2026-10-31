extends GutTest
## Hito 12: las mecánicas de los enemigos nuevos en la arena de pruebas. Babosas que se dividen (y la
## sala que espera a los hijos), nido con tope de crías, rayo del murciélago, explosión de la mecha,
## topo bajo tierra, hollín fantasma, escudo del escudero, bolas del fogonero y vuelo sobre fosos.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const ROOM_SCENE: PackedScene = preload("res://world/room.tscn")
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")
const FLOOR_1: FloorTheme = preload("res://content/floors/floor_1.tres")
## Sala con una sola Grasa en el medio.
const SLIME_ROOM: String = """
...............
...............
...............
...............
.......G.......
...............
...............
...............
...............
"""

var _game: Game
var _player: Player


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player


func _data(id: String) -> EnemyData:
	return load("res://content/enemies/%s.tres" % id) as EnemyData


## Una copia rápida: aparece y ataca enseguida.
func _quick(id: String) -> EnemyData:
	var data := _data(id).duplicate() as EnemyData
	data.spawn_delay = 0.05
	data.attack_cooldown = 0.1
	data.telegraph_time = 0.1
	data.recover_time = 0.1
	return data


func _enemies_with(id: StringName) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy.data.id == id and not enemy.is_queued_for_deletion():
			result.append(enemy)
	return result


func test_slime_splits_twice_and_then_is_gone() -> void:
	_player.health.always_invulnerable = true
	var grasa: Enemy = _game.spawn_enemy(_data("grasa"), Vector2(0, -40))
	await wait_physics_frames(2)
	grasa.health.kill()
	await wait_physics_frames(2)
	var medium: Array[Enemy] = _enemies_with(&"grasita")
	assert_eq(medium.size(), 2, "la grande se parte en dos")
	medium[0].health.kill()
	await wait_physics_frames(2)
	assert_eq(_enemies_with(&"gotita").size(), 2, "cada mediana en dos chicas")
	for small: Enemy in _enemies_with(&"gotita"):
		small.health.kill()
	await wait_physics_frames(2)
	assert_eq(_enemies_with(&"gotita").size(), 0, "las chicas no se dividen más")
	await wait_physics_frames(2)


func test_room_waits_for_the_split_children() -> void:
	_player.health.always_invulnerable = true
	var template := RoomTemplate.new()
	template.layout = SLIME_ROOM
	var slot := RoomSlot.new(Vector2i.ZERO)
	slot.template = template
	var room := ROOM_SCENE.instantiate() as Room
	room.position = Vector2(0, 1000)
	var no_neighbors: Dictionary[Vector2i, RoomSlot.Kind] = {}
	var no_barriers: Dictionary[Vector2i, Door.Mode] = {}
	room.setup(slot, FLOOR_1, no_neighbors, no_barriers, _game.world.get_node("Entities") as Node2D)
	_game.world.add_child(room)
	room.enter()
	await wait_physics_frames(2)
	_enemies_with(&"grasa")[0].health.kill()
	await wait_seconds(Room.CLEAR_DELAY + 0.2)
	assert_eq(room.phase, Room.Phase.FIGHTING, "con hijos vivos la sala sigue cerrada")
	# Mata a todas las generaciones hasta que no quede ninguna.
	for _round: int in 3:
		for enemy: Enemy in _enemies_with(&"grasita") + _enemies_with(&"gotita"):
			enemy.health.kill()
		await wait_physics_frames(2)
	await wait_seconds(Room.CLEAR_DELAY + 0.2)
	assert_eq(room.phase, Room.Phase.CLEARED, "sin enemigos, la sala se limpia")
	await wait_physics_frames(2)


func test_nest_summons_up_to_its_cap() -> void:
	_player.health.always_invulnerable = true
	var nest_data: EnemyData = _quick("nido")
	var cria := _data("cria").duplicate() as EnemyData
	cria.move_speed = 0.0
	nest_data.summon = cria
	_game.spawn_enemy(nest_data, Vector2(0, -40))
	await wait_seconds(2.0)
	assert_eq(_enemies_with(&"cria").size(), nest_data.summon_cap, "no pasa del tope")
	for cria_enemy: Enemy in _enemies_with(&"cria"):
		cria_enemy.health.kill()
	await wait_physics_frames(2)
	assert_eq(_enemies_with(&"cria").size(), 0)
	await wait_seconds(1.0)
	assert_gt(_enemies_with(&"cria").size(), 0, "si se mueren, vuelve a parir")
	await wait_physics_frames(2)


func test_bat_beam_hurts_the_player_in_line() -> void:
	var bat: EnemyData = _quick("murcielago")
	bat.move_speed = 0.0
	_player.global_position = Vector2(0, 32)
	_game.spawn_enemy(bat, Vector2(60, 32))
	await wait_seconds(1.0)
	assert_lt(_player.health.current, _player.health.max_health, "el rayo le pegó")
	await wait_physics_frames(2)


func test_fuse_explodes_hurts_and_leaves_embers() -> void:
	var fuse: EnemyData = _quick("mecha")
	_player.global_position = Vector2(0, 32)
	var mecha: Enemy = _game.spawn_enemy(fuse, Vector2(16, 32))
	await wait_seconds(0.5)
	assert_false(is_instance_valid(mecha), "explotó y murió")
	assert_lt(_player.health.current, _player.health.max_health, "lastimó al jugador")
	var embers: int = 0
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		if (node as Bullet).is_hostile_to_player():
			embers += 1
	assert_gt(embers, 0, "y soltó brasas")
	await wait_physics_frames(2)


func test_mole_is_untouchable_underground_and_surfaces_to_attack() -> void:
	_player.health.always_invulnerable = true
	var mole_data: EnemyData = _quick("topo")
	mole_data.attack_cooldown = 1.0
	var mole: Enemy = _game.spawn_enemy(mole_data, Vector2(40, -20))
	await wait_physics_frames(10)
	assert_true(mole.is_hidden(), "bajo tierra")
	var health: float = mole.health.current
	Bullet.spawn(get_tree(), BULLET_SCENE, ShotSpec.from_pattern(BulletPatternData.new()), mole.global_position + Vector2(-10, 0),
			Vector2.RIGHT, PhysicsLayers.PLAYER_BULLET, PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX)
	await wait_physics_frames(10)
	assert_eq(mole.health.current, health, "las balas no le pegan")
	var surfaced: bool = false
	for _frame: int in 120:
		await wait_physics_frames(1)
		surfaced = surfaced or not mole.is_hidden()
	assert_true(surfaced, "asomó para atacar")
	await wait_physics_frames(2)


func test_wisp_turns_into_a_ghost_and_back() -> void:
	_player.health.always_invulnerable = true
	var wisp_data: EnemyData = _quick("hollin")
	wisp_data.ghost_time = 0.3
	wisp_data.solid_time = 0.3
	wisp_data.attack_range = 0.0
	var wisp: Enemy = _game.spawn_enemy(wisp_data, Vector2(40, -20))
	await wait_physics_frames(5)
	assert_true(wisp.is_hidden(), "arranca fantasma")
	await wait_seconds(0.45)
	assert_false(wisp.is_hidden(), "después sólido")
	await wait_physics_frames(2)


func test_shield_blocks_from_the_front_but_not_from_behind() -> void:
	_player.health.always_invulnerable = true
	var shield_data: EnemyData = _quick("escudero")
	shield_data.attack_range = 0.0
	shield_data.move_speed = 0.0
	_player.global_position = Vector2(-60, 32)
	var guard: Enemy = _game.spawn_enemy(shield_data, Vector2(0, 32))
	await wait_physics_frames(10)
	var health: float = guard.health.current
	var spec := ShotSpec.from_pattern(BulletPatternData.new())
	Bullet.spawn(get_tree(), BULLET_SCENE, spec, Vector2(-20, 32), Vector2.RIGHT, PhysicsLayers.PLAYER_BULLET,
			PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX)
	await wait_physics_frames(10)
	assert_eq(guard.health.current, health, "de frente lo frena el escudo")
	Bullet.spawn(get_tree(), BULLET_SCENE, spec, Vector2(20, 32), Vector2.LEFT, PhysicsLayers.PLAYER_BULLET,
			PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX)
	await wait_physics_frames(10)
	assert_lt(guard.health.current, health, "por la espalda le pega")
	await wait_physics_frames(2)


func test_mortar_shell_lands_where_the_player_was_and_pulse_puts_it_out() -> void:
	var mortar: EnemyData = _quick("fogonero")
	mortar.move_speed = 0.0
	_player.global_position = Vector2(0, 32)
	_game.spawn_enemy(mortar, Vector2(80, -30))
	await wait_seconds(0.4)
	var shells: Array[Node] = get_tree().get_nodes_in_group(LobShell.GROUP)
	assert_gt(shells.size(), 0, "tiró una bola")
	assert_almost_eq((shells[0] as LobShell).global_position, _player.global_position, Vector2(2, 2), "apunta a donde estaba")
	await wait_seconds(mortar.lob_time + 0.1)
	assert_lt(_player.health.current, _player.health.max_health, "al caer lastima")
	var health: float = _player.health.current
	_player.health.grant_invulnerability(0.0)
	await wait_seconds(1.1)
	RunState.set_blanks(1)
	Input.action_press(&"blank")
	await wait_physics_frames(2)
	Input.action_release(&"blank")
	await wait_physics_frames(1)
	assert_eq(get_tree().get_nodes_in_group(LobShell.GROUP).size(), 0, "el Pulso apaga las que estaban en el aire")
	assert_gte(_player.health.current, health - 2.0)
	await wait_physics_frames(2)


func test_bats_fly_over_pits() -> void:
	var bat: Enemy = _game.spawn_enemy(_data("murcielago"), Vector2(40, -20))
	var walker: Enemy = _game.spawn_enemy(_data("vigia"), Vector2(-40, -20))
	await wait_physics_frames(1)
	assert_eq(bat.collision_mask & PhysicsLayers.PIT, 0, "el murciélago no choca con los fosos")
	assert_ne(walker.collision_mask & PhysicsLayers.PIT, 0, "los que caminan sí")
