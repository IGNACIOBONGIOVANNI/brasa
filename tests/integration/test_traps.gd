extends GutTest
## Hito 17: trampas. En la arena: lastiman al jugador y a los enemigos una vez por activación, se
## esquivan rodando, aplican su estado, la vaina espera a que alguien se acerque y el chorro pega solo
## hacia adelante. En un piso real: cada "^" tiene la trampa del piso y solo anda la sala actual.

const ARENA_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const TRAP_SCENE: PackedScene = preload("res://entities/traps/trap.tscn")
const CARNERO: EnemyData = preload("res://content/enemies/carnero.tres")
const VAPOR: TrapData = preload("res://content/traps/vapor.tres")
const PINCHOS_ROOM: RoomTemplate = preload("res://content/rooms/floor_1/sotano_pinchos.tres")
const SEED: int = 1234

var _game: Game
var _player: Player


func before_each() -> void:
	GameRNG.start_run(SEED)
	RunState.start_run()


func _arena() -> void:
	_game = ARENA_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player


## Una trampa rápida: casi sin espera, aviso corto y activa un buen rato.
func _quick(look: TrapData.Look, trigger: TrapData.Trigger = TrapData.Trigger.TIMED) -> TrapData:
	var data := TrapData.new()
	data.look = look
	data.trigger = trigger
	data.rest_time = 0.1
	data.warn_time = 0.1
	data.active_time = 0.5
	data.radius = 8.0
	data.player_damage = 1.0
	data.enemy_damage = 5.0
	return data


func _place(data: TrapData, at: Vector2, direction: Vector2 = Vector2.RIGHT) -> Trap:
	var trap := TRAP_SCENE.instantiate() as Trap
	trap.setup(data, 0.0, direction)
	trap.position = at
	_game.world.add_child(trap)
	return trap


## Un enemigo quieto (no se mueve ni ataca) en `at`.
func _dummy(at: Vector2) -> Enemy:
	var data := CARNERO.duplicate() as EnemyData
	data.move_speed = 0.0
	data.attack_range = 0.0
	data.max_health = 100.0
	return _game.spawn_enemy(data, at)


func _wait_until_active(trap: Trap) -> void:
	for _i: int in 120:
		if trap.stage == Trap.Stage.ACTIVE:
			return
		await wait_physics_frames(1)


func test_spikes_hurt_player_and_enemy_once_per_activation() -> void:
	_arena()
	var enemy: Enemy = _dummy(Vector2(-60, -30))
	await wait_physics_frames(2)
	var on_player: Trap = _place(_quick(TrapData.Look.SPIKES), _player.global_position + Vector2(0, -2))
	_place(_quick(TrapData.Look.SPIKES), enemy.global_position + Vector2(0, -2))
	await _wait_until_active(on_player)
	await wait_physics_frames(3)
	assert_eq(_player.health.current, _player.health.max_health - 1.0, "medio corazón al jugador")
	assert_eq(enemy.health.current, enemy.health.max_health - 5.0, "y su daño al enemigo")
	_player.health.always_invulnerable = true
	await wait_physics_frames(20)
	assert_eq(enemy.health.current, enemy.health.max_health - 5.0, "una vez por activación")
	await wait_physics_frames(2)


func test_rolling_over_the_spikes_is_safe() -> void:
	_arena()
	var trap: Trap = _place(_quick(TrapData.Look.SPIKES), _player.global_position + Vector2(0, -2))
	for _i: int in 120:
		if trap.stage == Trap.Stage.WARN:
			break
		await wait_physics_frames(1)
	_player.health.grant_invulnerability(2.0)
	await _wait_until_active(trap)
	await wait_physics_frames(5)
	assert_eq(_player.health.current, _player.health.max_health, "rodando (invulnerable) no lastima")


func test_vapor_poisons_the_enemies() -> void:
	_arena()
	_player.health.always_invulnerable = true
	var enemy: Enemy = _dummy(Vector2(-60, -30))
	await wait_physics_frames(2)
	var data := VAPOR.duplicate() as TrapData
	data.rest_time = 0.1
	data.warn_time = 0.1
	var trap: Trap = _place(data, enemy.global_position + Vector2(8, 0))
	await _wait_until_active(trap)
	await wait_physics_frames(3)
	assert_true(enemy.status.has(StatusComponent.Kind.POISON), "el gas envenena")
	assert_lt(enemy.health.current, enemy.health.max_health)


func test_pod_waits_for_someone_to_come_close() -> void:
	_arena()
	var data: TrapData = _quick(TrapData.Look.POD, TrapData.Trigger.PROXIMITY)
	data.trigger_radius = 20.0
	data.radius = 26.0
	var trap: Trap = _place(data, _player.global_position + Vector2(80, 0))
	await wait_physics_frames(90)
	assert_eq(trap.stage, Trap.Stage.REST, "sin nadie cerca no se dispara")
	_player.global_position = trap.global_position + Vector2(-12, 0)
	await _wait_until_active(trap)
	await wait_physics_frames(3)
	assert_eq(_player.health.current, _player.health.max_health - 1.0, "al acercarse revienta")
	await wait_physics_frames(2)


func test_jet_only_burns_ahead() -> void:
	_arena()
	_player.health.always_invulnerable = true
	var data: TrapData = _quick(TrapData.Look.NOZZLE)
	data.radius = 5.0
	data.length = 48.0
	var trap: Trap = _place(data, Vector2(-40, -40), Vector2.RIGHT)
	var ahead: Enemy = _dummy(trap.global_position + Vector2(30, 0))
	var behind: Enemy = _dummy(trap.global_position + Vector2(-30, 0))
	await wait_physics_frames(2)
	await _wait_until_active(trap)
	await wait_physics_frames(3)
	assert_lt(ahead.health.current, ahead.health.max_health, "el de adelante se quema")
	assert_eq(behind.health.current, behind.health.max_health, "el de atrás no")
	await wait_physics_frames(2)


func test_rooms_get_the_floor_trap_and_only_the_current_one_runs() -> void:
	GameRNG.start_run(SEED)
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.health.always_invulnerable = true
	var floor_controller: FloorController = _game.floor_controller
	var trap_cell: Vector2i = FloorLayout.NO_CELL
	for cell: Vector2i in floor_controller.layout.slots:
		var slot: RoomSlot = floor_controller.layout.get_slot(cell)
		if slot.kind == RoomSlot.Kind.NORMAL and trap_cell == FloorLayout.NO_CELL:
			slot.template = PINCHOS_ROOM
			trap_cell = cell
	await floor_controller.move_to(trap_cell)
	await wait_physics_frames(2)
	var room: Room = floor_controller.current_room()
	var expected: int = RoomTemplateParser.parse(PINCHOS_ROOM.layout).traps.size()
	assert_eq(room.trap_count(), expected, "una trampa por cada ^")
	var traps: Array[Node] = room.get_node(^"Traps").get_children()
	assert_eq((traps[0] as Trap).data, floor_controller.theme.trap, "la del piso")
	assert_eq(room.get_node(^"Traps").process_mode, Node.PROCESS_MODE_INHERIT, "la sala actual anda")
	await floor_controller.move_to(floor_controller.layout.start)
	await wait_physics_frames(2)
	assert_eq(room.get_node(^"Traps").process_mode, Node.PROCESS_MODE_DISABLED, "las otras quedan quietas")
