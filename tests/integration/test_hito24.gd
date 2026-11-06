extends GutTest
## Hito 24: armazones con chasis propio (pesado, zancudo y humanoide), minijefes en el capítulo 1
## (carnero veterano, grasa erizada, pehuén y bigornia, con su sala y lo que sueltan), el Altar que se
## lleva el contenedor del corazón y la fase de fuego del Yunque (se le rompe la coraza, junta una
## bola de fuego gigante, hace brotar lava e invoca fueguitos).

const ARENA_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const META: MetaConfig = preload("res://content/meta/meta_config.tres")
const RUN: RunConfig = preload("res://content/run/run_config.tres")
const YUNQUE: EnemyData = preload("res://content/enemies/yunque.tres")
const BIGORNIA: EnemyData = preload("res://content/enemies/bigornia.tres")
const VETERANO: EnemyData = preload("res://content/enemies/carnero_veterano.tres")
const YUNQUE_BOLA: BulletPatternData = preload("res://content/patterns/yunque_bola.tres")
const BOSS_AT: Vector2 = Vector2(40, -40)
const PLAYER_AT: Vector2 = Vector2(40, 40)

var _game: Game
var _player: Player


func _arena() -> void:
	GameRNG.start_run(2468)
	RunState.start_run()
	_game = ARENA_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.global_position = PLAYER_AT
	for rock: Node in get_tree().get_nodes_in_group(Rock.GROUP):
		rock.free()


func _floor_game(run_seed: int) -> FloorController:
	GameRNG.start_run(run_seed)
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.health.always_invulnerable = true
	return _game.floor_controller


func after_each() -> void:
	get_tree().paused = false


## Un jefe que hace solo `attack`, quieto y sin daño por contacto.
func _boss_with(attack: BossAttack) -> Enemy:
	var data := EnemyData.new()
	data.id = &"jefe_prueba"
	data.max_health = 400.0
	data.spawn_delay = 0.05
	data.body_radius = 10.0
	data.hurtbox_radius = 12.0
	data.contact_damage = 0.0
	var behavior := EnemyData.new()
	behavior.move_style = EnemyData.MoveStyle.STAY
	behavior.attack_range = 400.0
	behavior.attack_cooldown = 0.05
	var boss_phase := BossPhase.new()
	boss_phase.behavior = behavior
	boss_phase.attacks.assign([attack])
	data.phases.append(boss_phase)
	return _game.spawn_enemy(data, BOSS_AT)


func _moves_of(boss: EnemyData, kind: BossAttack.Kind) -> Array[BossAttack]:
	var result: Array[BossAttack] = []
	for boss_phase: BossPhase in boss.phases:
		for attack: BossAttack in boss_phase.attacks:
			if attack.kind == kind and not result.has(attack):
				result.append(attack)
	return result


func _strikes(look: BossAttack.Look) -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(BossStrike.GROUP):
		if (node as BossStrike).look == look:
			count += 1
	return count


# --- Armazones ---------------------------------------------------------------------------


func test_each_mech_has_its_own_frame() -> void:
	var frames: Dictionary[MechData.Frame, bool] = {}
	for mech: MechData in RUN.mechs:
		assert_false(frames.has(mech.frame), "%s: chasis propio, no otro color del mismo" % mech.id)
		frames[mech.frame] = true
	assert_eq(frames.size(), MechData.Frame.size(), "los tres chasis están en uso")
	var tops: Dictionary[Vector2, bool] = {}
	for mech: MechData in RUN.mechs:
		tops[MechDrawing.beacon(mech, false)] = true
	assert_eq(tops.size(), RUN.mechs.size(), "cada silueta tiene su punta en otro lado")


# --- Altar ---------------------------------------------------------------------------------


func test_the_altar_takes_the_whole_container() -> void:
	RunState.start_run()
	var max_health: float = RunState.stats.max_health
	assert_true(RunState.sacrifice_health(2.0))
	assert_eq(RunState.stats.max_health, max_health - 2.0, "un contenedor menos")
	assert_eq(RunState.sacrificed_health, 2.0)
	assert_false(RunState.sacrifice_health(RunState.stats.max_health - 1.0), "nunca deja sin un corazón")
	assert_true(RunState.can_sacrifice(RunState.stats.max_health - RunState.MIN_MAX_HEALTH), "hasta un corazón sí")


func test_the_sacrifice_is_saved_with_the_run() -> void:
	RunState.start_run()
	RunState.sacrifice_health(2.0)
	var snapshot := RunSnapshot.new()
	RunState.capture(snapshot)
	var copy: RunSnapshot = RunSnapshot.from_dict(snapshot.to_dict())
	assert_not_null(copy)
	assert_eq(copy.sacrificed_health, 2.0)
	var max_health: float = RunState.stats.max_health
	RunState.start_run()
	assert_gt(RunState.stats.max_health, max_health, "una run nueva arranca entera")
	assert_true(RunState.restore(copy, null))
	assert_eq(RunState.stats.max_health, max_health, "al seguir la run falta el contenedor")
	var old: Dictionary = snapshot.to_dict()
	old["format"] = 1
	assert_null(RunSnapshot.from_dict(old), "una foto de antes de los minijefes no se sigue (cambió el layout)")


# --- Minijefes -----------------------------------------------------------------------------


func test_chapter_one_floors_have_a_miniboss_and_chapter_two_not() -> void:
	var seen: Dictionary[EnemyData, bool] = {}
	for theme: FloorTheme in META.chapters[0].floors:
		assert_true(theme.has_miniboss(), "%s: tiene minijefe" % theme.id)
		var rooms: int = 0
		for template: RoomTemplate in theme.templates:
			if template.kind != RoomSlot.Kind.MINIBOSS:
				continue
			rooms += 1
			var grid: RoomGrid = RoomTemplateParser.parse(template.layout)
			var miniboss: EnemyData = theme.enemy_for_symbol(grid.enemies[0].symbol)
			assert_true(miniboss.miniboss, "%s: es un minijefe" % miniboss.id)
			assert_false(seen.has(miniboss), "%s: un minijefe distinto por piso" % miniboss.id)
			seen[miniboss] = true
			assert_gt(miniboss.drops.size(), 0, "%s: suelta consumibles" % miniboss.id)
			assert_gte(miniboss.phases.size(), 2, "%s: tiene dos fases" % miniboss.id)
			var boss: EnemyData = null
			for enemy: EnemyData in theme.enemies:
				if not enemy.phases.is_empty() and not enemy.miniboss:
					boss = enemy
			assert_lt(miniboss.max_health, boss.max_health, "%s: aguanta menos que el jefe del piso" % miniboss.id)
		assert_eq(rooms, 1, "%s: una sola sala de minijefe (sale siempre la misma)" % theme.id)
	for theme: FloorTheme in META.chapters[1].floors:
		assert_false(theme.has_miniboss(), "%s: el capítulo 2 no tiene minijefes" % theme.id)


func test_the_generated_floor_has_its_miniboss_room() -> void:
	var floor_controller: FloorController = _floor_game(1234)
	var cells: Array[Vector2i] = floor_controller.layout.cells_of_kind(RoomSlot.Kind.MINIBOSS)
	assert_eq(cells.size(), 1, "una sala de minijefe")
	var slot: RoomSlot = floor_controller.layout.get_slot(cells[0])
	assert_eq(slot.template.kind, RoomSlot.Kind.MINIBOSS)
	assert_eq(floor_controller.layout.neighbors(cells[0], false).size(), 1, "en un callejón")
	assert_true(Door.FRAME_COLORS.has(RoomSlot.Kind.MINIBOSS), "la puerta se ve distinta")
	assert_true(Minimap.ICON_COLORS.has(RoomSlot.Kind.MINIBOSS), "y el minimapa la marca")


func test_beating_a_miniboss_drops_consumables_without_counting_as_boss() -> void:
	var floor_controller: FloorController = _floor_game(1234)
	var cell: Vector2i = floor_controller.layout.first_of_kind(RoomSlot.Kind.MINIBOSS)
	await floor_controller.move_to(cell)
	await wait_physics_frames(2)
	var room: Room = floor_controller.current_room()
	assert_eq(room.phase, Room.Phase.FIGHTING, "la sala del minijefe se pelea")
	var miniboss: Enemy = null
	for _frame: int in 120:
		for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
			if (node as Enemy).data.miniboss:
				miniboss = node as Enemy
		if miniboss != null:
			break
		await wait_physics_frames(1)
	assert_not_null(miniboss, "aparece el minijefe")
	assert_eq(AudioManager.current_music(), floor_controller.theme.music, "sigue la música del piso")
	var drops: int = miniboss.data.drops.size()
	var pickups_before: int = _pickups_in(room)
	miniboss.health.kill()
	await wait_physics_frames(80)
	assert_eq(room.phase, Room.Phase.CLEARED)
	assert_gte(_pickups_in(room) - pickups_before, drops, "suelta lo suyo")
	assert_eq(RunState.bosses_defeated.size(), 0, "no cuenta como jefe vencido")
	assert_eq(floor_controller.get_room(cell).get_node(^"Pickups").get_children().filter(
			func(n: Node) -> bool: return n is Trapdoor).size(), 0, "no abre la salida")


func _pickups_in(room: Room) -> int:
	var count: int = 0
	for child: Node in room.get_node(^"Pickups").get_children():
		if child is Pickup and not child.is_queued_for_deletion():
			count += 1
	return count


func test_the_bigornia_forges_flying_weapons_that_fall_with_it() -> void:
	_arena()
	_player.health.grant_invulnerability(30.0)
	var data := BIGORNIA.duplicate() as EnemyData
	data.spawn_delay = 0.05
	var bigornia: Enemy = _game.spawn_enemy(data, BOSS_AT)
	await wait_physics_frames(5)
	bigornia.force_attack(_moves_of(BIGORNIA, BossAttack.Kind.SUMMON)[0])
	var weapons: Array[Enemy] = []
	for _frame: int in 200:
		weapons.clear()
		for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
			var enemy := node as Enemy
			if enemy != bigornia and not enemy.dismissed:
				weapons.append(enemy)
		if not weapons.is_empty():
			break
		await wait_physics_frames(1)
	assert_gt(weapons.size(), 0, "forja armas que vuelan")
	for weapon: Enemy in weapons:
		assert_has([EnemyData.VisualStyle.SWORD, EnemyData.VisualStyle.AXE, EnemyData.VisualStyle.KNIFE],
				weapon.data.visual_style, "%s: es un arma" % weapon.data.id)
	bigornia.health.kill()
	await wait_physics_frames(3)
	var left: int = 0
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		if not node.is_queued_for_deletion():
			left += 1
	assert_eq(left, 0, "las armas caen con la bigornia")


func test_the_veteran_and_the_pehuen_have_their_moves() -> void:
	assert_gt(_moves_of(VETERANO, BossAttack.Kind.CHARGES).size(), 0, "el veterano embiste")
	var pehuen := load("res://content/enemies/pehuen.tres") as EnemyData
	assert_gt(_moves_of(pehuen, BossAttack.Kind.GROUND_LINES).size(), 0, "el pehuén ataca con raíces")
	assert_gt(_moves_of(pehuen, BossAttack.Kind.VOLLEY).size(), 0, "y con hojas cortantes")
	var cones: Array[BossAttack] = _moves_of(pehuen, BossAttack.Kind.DEBRIS)
	assert_gt(cones.size(), 0, "y tira piñas")
	for attack: BossAttack in cones:
		assert_eq(attack.look, BossAttack.Look.PINECONE)
	var spiky := load("res://content/enemies/grasa_erizada.tres") as EnemyData
	assert_gt(_moves_of(spiky, BossAttack.Kind.FRAG_BOMBS).size(), 0, "la grasa carga bolas de pinchos")


func test_pinecones_fall_where_the_player_is() -> void:
	_arena()
	_player.health.grant_invulnerability(30.0)
	var attack := BossAttack.new()
	attack.id = &"pinas"
	attack.kind = BossAttack.Kind.DEBRIS
	attack.look = BossAttack.Look.PINECONE
	attack.windup = 0.1
	attack.recover = 5.0
	attack.warn_time = 0.5
	attack.count = 2
	_boss_with(attack)
	for _frame: int in 120:
		if _strikes(BossAttack.Look.PINECONE) > 0:
			break
		await wait_physics_frames(1)
	assert_gt(_strikes(BossAttack.Look.PINECONE), 0, "caen piñas")


# --- Yunque: la fase de fuego -------------------------------------------------------------


func test_the_yunque_breaks_its_shell_at_half_health() -> void:
	_arena()
	_player.health.grant_invulnerability(30.0)
	var data := YUNQUE.duplicate() as EnemyData
	data.spawn_delay = 0.05
	var yunque: Enemy = _game.spawn_enemy(data, BOSS_AT)
	await wait_physics_frames(10)
	assert_eq(yunque.visual.style, EnemyData.VisualStyle.BLOCK, "arranca con la coraza")
	var fire_phase: int = -1
	for i: int in data.phases.size():
		if data.phases[i].new_look:
			fire_phase = i
	assert_gt(fire_phase, 0, "una fase le cambia el aspecto")
	var to_half: float = yunque.health.current - yunque.health.max_health * data.phases[fire_phase].health_fraction + 1.0
	yunque.hurtbox.receive_hit(HitInfo.create(to_half, Vector2.UP, 0.0))
	await wait_physics_frames(2)
	assert_eq(yunque.phase, fire_phase, "pasa a la fase de fuego")
	assert_eq(yunque.visual.style, EnemyData.VisualStyle.FORGE_HEART, "queda el cuerpo de fuego")
	var kinds: Dictionary[BossAttack.Kind, bool] = {}
	for attack: BossAttack in data.phases[fire_phase].attacks:
		kinds[attack.kind] = true
	assert_true(kinds.has(BossAttack.Kind.CHARGED_ORB), "carga la bola de fuego")
	assert_true(kinds.has(BossAttack.Kind.MOLTEN), "hace brotar lava")
	assert_true(kinds.has(BossAttack.Kind.SUMMON), "invoca fueguitos")
	await wait_physics_frames(2)


func test_the_fire_ball_charges_and_takes_a_whole_heart() -> void:
	_arena()
	var attack := BossAttack.new()
	attack.id = &"bola"
	attack.kind = BossAttack.Kind.CHARGED_ORB
	attack.windup = 0.1
	attack.recover = 5.0
	attack.warn_time = 0.5
	attack.radius = 10.0
	attack.damage = 2.0
	attack.speed = 120.0
	attack.pattern = YUNQUE_BOLA
	_player.global_position = BOSS_AT + Vector2(0, 70)
	_boss_with(attack)
	var charged: bool = false
	for _frame: int in 60:
		if not get_tree().get_nodes_in_group(ChargedOrb.GROUP).is_empty():
			charged = true
			break
		await wait_physics_frames(1)
	assert_true(charged, "la junta arriba de la cabeza")
	var ball: Bullet = null
	for _frame: int in 60:
		ball = _ball()
		if ball != null:
			break
		await wait_physics_frames(1)
	assert_not_null(ball, "y la tira")
	assert_eq(ball.spec.damage, 2.0, "pega un corazón entero")
	assert_eq(ball.spec.radius, 10.0, "es enorme")
	var health: float = _player.health.current
	for _frame: int in 90:
		if _player.health.current < health:
			break
		await wait_physics_frames(1)
	assert_eq(_player.health.current, health - 2.0, "le sacó un corazón")
	# El golpe deja chispas diferidas: un par de frames más para que no queden huérfanas.
	await wait_physics_frames(3)


func _ball() -> Bullet:
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		var bullet := node as Bullet
		if bullet.is_hostile_to_player() and bullet.spec.radius >= 10.0:
			return bullet
	return null


func test_lava_comes_out_of_the_floor_with_a_warning() -> void:
	_arena()
	_player.health.grant_invulnerability(30.0)
	var attack := BossAttack.new()
	attack.id = &"lava"
	attack.kind = BossAttack.Kind.MOLTEN
	attack.look = BossAttack.Look.LAVA
	attack.windup = 0.1
	attack.recover = 5.0
	attack.warn_time = 0.8
	attack.count = 3
	attack.linger = 1.0
	_boss_with(attack)
	var strike: BossStrike = null
	for _frame: int in 90:
		for node: Node in get_tree().get_nodes_in_group(BossStrike.GROUP):
			if (node as BossStrike).look == BossAttack.Look.LAVA:
				strike = node as BossStrike
		if strike != null:
			break
		await wait_physics_frames(1)
	assert_not_null(strike, "brota lava")
	assert_false(strike.has_struck(), "primero avisa")
	assert_eq(strike.linger, 1.0, "y queda el charco")
