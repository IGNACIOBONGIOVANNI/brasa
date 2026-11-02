extends GutTest
## Hito 22: el escenario de cada piso (FloorTheme.scenery). Las paredes, las rocas y los fosos toman
## el aspecto del piso, lo que brilla solo se anima en la sala actual y un piso sin escenario sigue con
## los bloques lisos de siempre.

const GAME_SCENE: PackedScene = preload("res://main/game.tscn")


func _start(chapter: RunConfig) -> Game:
	GameRNG.start_run(1234)
	RunState.start_run(SaveManager.config.characters_of(chapter)[0])
	var game := GAME_SCENE.instantiate() as Game
	add_child_autofree(game)
	return game


func _wall_scenery(room: Room) -> RoomScenery:
	return room.get_node(^"WallScenery") as RoomScenery


func test_every_floor_builds_its_own_scenery() -> void:
	for chapter: RunConfig in SaveManager.config.chapters:
		var game: Game = _start(chapter)
		await wait_physics_frames(2)
		for index: int in chapter.floors.size():
			if index > 0:
				game.floor_controller.load_floor(index)
				await wait_physics_frames(2)
			var theme: FloorTheme = chapter.floors[index]
			var room: Room = game.floor_controller.current_room()
			var walls: RoomScenery = _wall_scenery(room)
			assert_eq(walls.scenery, theme.scenery, "%s: paredes con su escenario" % theme.id)
			assert_eq((room.get_node(^"FloorScenery") as RoomScenery).scenery, theme.scenery, "%s: y su piso" % theme.id)
			assert_not_null(walls.get_node_or_null(^"Glow"), "%s: lo que brilla va aparte, sin sombra" % theme.id)
			for body: Node in room.get_node(^"Walls").get_children():
				assert_eq(body.get_child_count(), 1, "%s: el tramo de pared solo choca (lo dibuja el escenario)" % theme.id)
			for child: Node in room.get_node(^"Obstacles").get_children():
				var visual := child.get_node(^"Visual") as SceneryShape
				assert_eq(visual.scenery, theme.scenery, "%s: rocas y fosos del piso" % theme.id)
		game.queue_free()
		await wait_physics_frames(2)


func test_only_the_current_room_animates() -> void:
	var game: Game = _start(SaveManager.config.chapters[0])
	await wait_physics_frames(2)
	var first: Room = game.floor_controller.current_room()
	assert_true(_wall_scenery(first).is_processing(), "la sala actual anima sus velas")
	var next: Vector2i = game.floor_controller.layout.neighbors(game.floor_controller.layout.start)[0]
	game.floor_controller.move_to(next)
	await wait_physics_frames(30)
	var second: Room = game.floor_controller.current_room()
	assert_ne(second, first)
	assert_true(_wall_scenery(second).is_processing(), "la nueva se anima")
	assert_false(_wall_scenery(first).is_processing(), "la que quedó atrás no")


func test_a_rock_with_scenery_still_breaks() -> void:
	var game: Game = _start(SaveManager.config.chapters[0])
	await wait_physics_frames(2)
	var rocks: Array[Rock] = []
	for child: Node in game.floor_controller.current_room().get_node(^"Obstacles").get_children():
		if child is Rock:
			rocks.append(child as Rock)
	assert_false(rocks.is_empty(), "la sala de inicio tiene rocas")
	rocks[0].destroy()
	await wait_physics_frames(3)
	assert_false(is_instance_valid(rocks[0]), "el cajón se rompe como una roca")


func test_a_floor_without_scenery_keeps_plain_walls() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var sides: Array[Vector2i] = [Vector2i.UP]
	RoomBuilder.build_walls(parent, sides, FloorTheme.new())
	for body: Node in parent.get_children():
		assert_eq(body.get_child_count(), 2, "forma de choque y bloque liso")
		assert_true(body.get_child(1) is PlaceholderShape)


func test_scenery_spots_stay_on_the_wall_and_repeat() -> void:
	assert_eq(SceneryDrawing.noise(17, 3), SceneryDrawing.noise(17, 3), "la misma sala se ve igual siempre")
	assert_ne(SceneryDrawing.noise(17, 3), SceneryDrawing.noise(18, 3))
	var sides: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT]
	for rect: Rect2 in RoomBuilder.wall_layout(sides):
		var side: Vector2i = SceneryDrawing.side_of(rect)
		assert_true(rect.has_point(rect.get_center()))
		for spot: Vector2 in SceneryDrawing.spots(rect, 20.0, 5):
			assert_true(rect.grow(0.5).has_point(spot), "%s: las cosas van sobre la pared" % side)
			assert_lt(absf(spot.x) if side.y != 0 else absf(spot.y), (SceneryDrawing.HALF.x if side.y != 0 else SceneryDrawing.HALF.y),
					"lejos de las esquinas")
	for x: int in 100:
		var value: float = SceneryDrawing.noise(x, x * 3)
		assert_between(value, 0.0, 1.0)
