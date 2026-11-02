extends Node
## Medidor de balance (herramienta de desarrollo). Un bot invulnerable juega una run entera: en cada
## piso suma algunos items típicos, limpia todas las salas de combate y al jefe, y anota cuánto tarda
## con el mismo reloj de la run (RunState.run_time). Al final imprime una estimación de lo que dura
## una run para una persona: el bot no esquiva ni explora, así que su tiempo de combate se multiplica
## por HUMAN_FACTOR y se suma ROOM_OVERHEAD por sala (caminar, transiciones, agarrar cosas).
## Uso: <godot_console> --headless --fixed-fps 60 --path . res://debug/balance_probe.tscn -- --seed=N
## (--fixed-fps hace que corra sin esperar al reloj real: una run entera tarda un par de minutos).
## --weapon=ID equipa esa arma (de content/weapons/) y le llena la munición cada vez que se vacía,
## para comparar cuánto pega cada una; --floors=N juega solo los primeros N pisos; --chapter=N juega ese
## capítulo con su primer personaje.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
## Items que suma el bot al empezar cada piso (uno más por piso): simulan lo que se junta en una run.
const TYPICAL_ITEMS: Array[String] = ["polvora_negra", "gatillo_flojo", "aguja", "lupa"]
const HUMAN_FACTOR: float = 2.0
const ROOM_OVERHEAD: float = 8.0
## Una sala que el bot no limpia en este tiempo se cuenta así y se sigue (queda marcada).
const ROOM_TIMEOUT: float = 90.0
const NEAR: float = 45.0
const FAR: float = 110.0
const STRAFE: float = 0.6
const AUDIO_DRAIN_MSEC: int = 600
const WEAPON_ARG: String = "--weapon="
const FLOORS_ARG: String = "--floors="

var _main: Main
## Arma a probar (--weapon=ID); null = la pistola de siempre.
var _weapon: WeaponData = null
var _floors: int = -1


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(WEAPON_ARG):
			_weapon = load("res://content/weapons/%s.tres" % arg.trim_prefix(WEAPON_ARG)) as WeaponData
		elif arg.begins_with(FLOORS_ARG) and arg.trim_prefix(FLOORS_ARG).is_valid_int():
			_floors = arg.trim_prefix(FLOORS_ARG).to_int()
	_main = MAIN_SCENE.instantiate() as Main
	_main.save_dir = ""
	add_child(_main)
	_run.call_deferred()


func _run() -> void:
	var chapter: RunConfig = Main.chapter_from_args(OS.get_cmdline_user_args())
	_main.start_run(SaveManager.config.characters_of(chapter)[0] if chapter != null else null)
	await get_tree().physics_frame
	var game: Game = _main.game
	var floor_controller: FloorController = game.floor_controller
	game.player.health.always_invulnerable = true
	if _weapon != null:
		RunState.add_weapon(_weapon)
	var total_combat: float = 0.0
	var total_rooms: int = 0
	var floor_count: int = floor_controller.run.floors.size()
	if _floors > 0:
		floor_count = mini(_floors, floor_count)
	for index: int in floor_count:
		if index > 0:
			floor_controller.load_floor(index)
		RunState.add_item(load("res://content/items/%s.tres" % TYPICAL_ITEMS[mini(index, TYPICAL_ITEMS.size() - 1)]) as ItemData)
		var layout: FloorLayout = floor_controller.layout
		var cells: Array[Vector2i] = layout.cells_of_kind(RoomSlot.Kind.NORMAL)
		cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return layout.get_slot(a).distance < layout.get_slot(b).distance)
		var rooms_time: float = 0.0
		var slow: PackedStringArray = []
		for cell: Vector2i in cells:
			var seconds: float = await _clear(floor_controller, cell)
			rooms_time += seconds
			if seconds >= ROOM_TIMEOUT:
				slow.append("%s (quedaban: %s)" % [layout.get_slot(cell).template.id, _alive()])
		var boss_time: float = await _clear(floor_controller, layout.first_of_kind(RoomSlot.Kind.BOSS))
		total_combat += rooms_time + boss_time
		total_rooms += layout.slots.size()
		print("piso %d (%s): %d salas de combate en %.0f s (%.1f s por sala), jefe en %.0f s%s" % [
			index + 1, RunState.floor_name, cells.size(), rooms_time, rooms_time / maxf(1.0, cells.size()),
			boss_time, (" · sin terminar: " + ", ".join(slow)) if not slow.is_empty() else ""])
	var estimate: float = total_combat * HUMAN_FACTOR + total_rooms * ROOM_OVERHEAD
	print("bot (%s): %s de combate en %d salas · estimado para una persona: %s" % [
		_weapon.display_name if _weapon != null else "Pistola", RunSummary.format_time(total_combat),
		total_rooms, RunSummary.format_time(estimate)])
	_release_all()
	# Con --fixed-fps el tiempo de juego no espera al real: se deja terminar el audio antes de salir.
	AudioManager.stop_all()
	OS.delay_msec(AUDIO_DRAIN_MSEC)
	_main.quit_game()


## Los enemigos vivos y dónde están (relativo al centro de la sala), para ver qué trabó al bot.
func _alive() -> String:
	var names: PackedStringArray = []
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		names.append("%s en %s, %s, vida %.0f" % [enemy.data.id, (enemy.global_position - enemy.nav_origin).round(),
				enemy.machine.get_state_name(), enemy.health.current])
	return "; ".join(names)


## Entra a la sala y pelea hasta limpiarla. Devuelve los segundos de juego que tardó.
func _clear(floor_controller: FloorController, cell: Vector2i) -> float:
	await floor_controller.move_to(cell)
	while floor_controller.is_transitioning():
		await get_tree().physics_frame
	var start: float = RunState.run_time
	var room: Room = floor_controller.current_room()
	while room.phase != Room.Phase.CLEARED and RunState.run_time - start < ROOM_TIMEOUT:
		if _weapon != null and RunState.current_weapon_slot().is_empty():
			RunState.add_weapon(_weapon)
		_drive(_main.game.player)
		await get_tree().physics_frame
	_release_all()
	return minf(RunState.run_time - start, ROOM_TIMEOUT)


## Apunta y dispara al enemigo vivo más cercano; se acerca si está lejos, se aleja si está cerca y
## si no, se mueve de costado.
func _drive(player: Player) -> void:
	var target: Enemy = null
	var best: float = INF
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy == null or enemy.health.is_dead():
			continue
		var distance: float = player.global_position.distance_to(enemy.global_position)
		if distance < best:
			best = distance
			target = enemy
	if target == null:
		_release_all()
		return
	var aim: Vector2 = (target.global_position - player.global_position).normalized()
	_set_axis(&"aim_left", &"aim_right", aim.x)
	_set_axis(&"aim_up", &"aim_down", aim.y)
	Input.action_press(&"shoot")
	var move: Vector2 = aim.orthogonal() * STRAFE
	if best > FAR:
		move = aim
	elif best < NEAR:
		move = -aim
	_set_axis(&"move_left", &"move_right", move.x)
	_set_axis(&"move_up", &"move_down", move.y)


func _set_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value > 0.0:
		Input.action_press(positive, value)
		Input.action_release(negative)
	elif value < 0.0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _release_all() -> void:
	for action: StringName in [&"shoot", &"aim_left", &"aim_right", &"aim_up", &"aim_down",
			&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)
