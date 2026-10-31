extends GutTest
## Hito 2: combate del jugador (i-frames, empujón, rodar, buffer, Pulso, muerte) y de los enemigos
## (daño por contacto, muerte, telegraph antes de cada ataque, embestida), más el hit-stop.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")
const CARNERO: EnemyData = preload("res://content/enemies/carnero.tres")
const VIGIA: EnemyData = preload("res://content/enemies/vigia.tres")
const USED_ACTIONS: Array[StringName] = [&"dodge", &"blank", &"move_right", &"shoot", &"aim_right"]

var _game: Game
var _player: Player
var _states: Array[StringName] = []


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_states.clear()


func after_each() -> void:
	for action: StringName in USED_ACTIONS:
		Input.action_release(action)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_physics_frames(1)
	Input.action_release(action)


func _enemy_bullet(at: Vector2, direction: Vector2) -> Bullet:
	return Bullet.spawn(get_tree(), BULLET_SCENE, ShotSpec.from_pattern(BulletPatternData.new()), at,
			direction, PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)


func _hit(damage: float) -> bool:
	return _player.hurtbox.receive_hit(HitInfo.create(damage, Vector2.RIGHT, 140.0))


func _record_states(machine: StateMachine) -> void:
	machine.state_changed.connect(func(_previous: StringName, current: StringName) -> void:
		_states.append(current))


func _live_hostile_bullets() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		var bullet := node as Bullet
		if bullet.is_hostile_to_player() and not bullet.is_queued_for_deletion():
			count += 1
	return count


# --- Jugador ---------------------------------------------------------------------------------

func test_hit_grants_iframes_and_updates_hud() -> void:
	assert_true(_hit(1.0), "el primer golpe entra")
	assert_false(_hit(1.0), "durante los i-frames no entra otro")
	assert_eq(_player.health.current, 5.0)
	var hearts := _game.get_node("Hud/Hearts") as HeartsDisplay
	assert_eq(hearts.half_hearts, 5, "el HUD muestra 2 corazones y medio")
	await wait_physics_frames(65)
	assert_true(_hit(1.0), "pasado 1 s vuelve a recibir daño")
	# Las partículas del golpe se agregan diferidas: un frame más para que no cuenten como huérfanas.
	await wait_physics_frames(1)


func test_hit_knocks_player_back() -> void:
	var start_x: float = _player.global_position.x
	_hit(1.0)
	await wait_physics_frames(15)
	assert_gt(_player.global_position.x, start_x + 5.0, "el golpe lo empujó")


func test_roll_moves_fast_and_is_invulnerable() -> void:
	var start_x: float = _player.global_position.x
	Input.action_press(&"move_right")
	await _tap(&"dodge")
	await wait_physics_frames(2)
	assert_eq(_player.machine.get_state_name(), &"Roll", "empezó a rodar")
	assert_false(_hit(1.0), "rodando no recibe daño")
	await wait_physics_frames(20)
	assert_eq(_player.machine.get_state_name(), &"Move", "terminó de rodar")
	assert_gt(_player.global_position.x, start_x + 45.0, "rodando avanza más que caminando")


func test_roll_cooldown_drops_early_presses_and_buffers_late_ones() -> void:
	_record_states(_player.machine)
	await _tap(&"dodge")
	await wait_physics_frames(25)
	assert_eq(_player.machine.get_state_name(), &"Move", "terminó el primer rol")
	_states.clear()
	# Recién terminó el rol (cooldown de 18 ticks): este toque vence en el buffer antes de poder usarse.
	await _tap(&"dodge")
	await wait_physics_frames(20)
	assert_eq(_states.size(), 0, "no rodó: el toque fue demasiado temprano")
	# Con el cooldown ya libre, rodar de nuevo funciona al toque.
	await _tap(&"dodge")
	await wait_physics_frames(2)
	assert_eq(_player.machine.get_state_name(), &"Roll")


func test_dodge_pressed_just_before_cooldown_ends_is_buffered() -> void:
	await _tap(&"dodge")
	await wait_physics_frames(19)
	# El rol dura 0.32 s (~20 ticks): faltan unos ticks de rol y 18 de cooldown.
	await wait_physics_frames(14)
	await _tap(&"dodge")
	assert_eq(_player.machine.get_state_name(), &"Move", "todavía en cooldown")
	await wait_physics_frames(6)
	assert_eq(_player.machine.get_state_name(), &"Roll", "el toque quedó en el buffer y rodó al liberarse")


func test_pulse_clears_enemy_bullets_and_uses_a_charge() -> void:
	for i: int in 3:
		_enemy_bullet(Vector2(-100, -60 + i * 20), Vector2.DOWN)
	await wait_physics_frames(1)
	assert_eq(_live_hostile_bullets(), 3)
	await _tap(&"blank")
	await wait_physics_frames(1)
	assert_eq(_live_hostile_bullets(), 0, "el Pulso borró las balas enemigas")
	assert_eq(RunState.blanks, RunState.START_BLANKS - 1, "gastó una carga")


func test_pulse_without_charges_does_nothing() -> void:
	RunState.set_blanks(0)
	_enemy_bullet(Vector2(-100, -60), Vector2.DOWN)
	await _tap(&"blank")
	await wait_physics_frames(1)
	assert_eq(_live_hostile_bullets(), 1, "sin cargas la bala sigue")
	assert_eq(RunState.blanks, 0)


func test_player_death_switches_state_and_announces_it() -> void:
	watch_signals(EventBus)
	_hit(6.0)
	await wait_physics_frames(1)
	assert_true(_player.is_dead())
	assert_eq(_player.machine.get_state_name(), &"Dead")
	assert_signal_emitted(EventBus, "player_died")
	assert_false(_hit(1.0), "muerto no recibe más golpes")


func test_hitstop_freezes_time_and_restores_it() -> void:
	EventBus.hitstop_requested.emit(0.05)
	assert_eq(Engine.time_scale, 0.0, "congelado")
	await wait_physics_frames(5)
	assert_eq(Engine.time_scale, 1.0, "volvió a la normalidad")


# --- Enemigos --------------------------------------------------------------------------------

func test_enemy_contact_damage_waits_for_spawn() -> void:
	_game.spawn_enemy(CARNERO, _player.position)
	await wait_physics_frames(20)
	assert_eq(_player.health.current, _player.health.max_health, "mientras aparece no hace daño")
	await wait_physics_frames(45)
	assert_lt(_player.health.current, _player.health.max_health, "después lastima por contacto")


func test_enemy_dies_leaves_stain_and_is_announced() -> void:
	var enemy := _game.spawn_enemy(VIGIA, Vector2(-60, -40))
	await wait_physics_frames(1)
	watch_signals(EventBus)
	enemy.hurtbox.receive_hit(HitInfo.create(100.0, Vector2.RIGHT, 0.0))
	await wait_physics_frames(2)
	assert_false(is_instance_valid(enemy), "el enemigo desapareció")
	assert_signal_emitted(EventBus, "enemy_killed")
	var decals: Node = _game.world.get_node("Decals")
	assert_eq(decals.get_child_count(), 1, "dejó una mancha en el piso")


func test_enemy_telegraphs_before_every_attack() -> void:
	_player.health.always_invulnerable = true
	var enemy := _game.spawn_enemy(VIGIA, Vector2(-60, 0))
	_record_states(enemy.machine)
	var fired: int = 0
	for _i: int in 300:
		await wait_physics_frames(1)
		fired = maxi(fired, _live_hostile_bullets())
	var attacks: int = 0
	for i: int in _states.size():
		if _states[i] == &"Attack":
			attacks += 1
			assert_eq(_states[i - 1], &"Telegraph", "antes del ataque %d hubo aviso" % attacks)
	assert_gte(attacks, 2, "atacó varias veces en 5 s")
	assert_gt(fired, 0, "disparó balas")


func test_charger_charges_toward_player() -> void:
	_player.health.always_invulnerable = true
	var enemy := _game.spawn_enemy(CARNERO, _player.position + Vector2(0, -50))
	_record_states(enemy.machine)
	for _i: int in 180:
		await wait_physics_frames(1)
		if enemy.machine.get_state_name() == &"Attack":
			break
	assert_eq(enemy.machine.get_state_name(), &"Attack", "llegó a embestir")
	await wait_physics_frames(2)
	assert_gt(enemy.move_velocity.y, 100.0, "embiste hacia el jugador (abajo) y rápido")
	assert_true(_states.has(&"Telegraph"), "avisó antes")
