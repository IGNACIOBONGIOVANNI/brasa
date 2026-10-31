extends GutTest
## Hito 7: avisos del HUD. Bordes rojos al recibir daño y latido con la vida baja; cartel y barra
## cuando aparece un jefe.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const CAMPANARIO: EnemyData = preload("res://content/enemies/campanario.tres")

var _game: Game
var _danger: DangerOverlay


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_danger = _game.get_node("Hud/Danger") as DangerOverlay


func test_low_health_starts_the_heartbeat() -> void:
	var health: HealthComponent = _game.player.health
	assert_false(_danger.is_low_health())
	health.take_damage(3.0)
	assert_false(_danger.is_low_health(), "con un corazón y medio todavía no")
	health.grant_invulnerability(0.0)
	await wait_physics_frames(70)
	health.take_damage(1.0)
	assert_true(_danger.is_low_health(), "con un corazón sí")
	health.heal(2.0)
	assert_false(_danger.is_low_health(), "al curarse se apaga")


func test_boss_spawn_shows_its_name() -> void:
	watch_signals(EventBus)
	_game.spawn_enemy(CAMPANARIO, Vector2(0, -40))
	await wait_physics_frames(1)
	assert_signal_emitted(EventBus, "boss_spawned")
	var texts: PackedStringArray = []
	for node: Node in _game.get_node("Hud/Banner").find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	assert_has(texts, CAMPANARIO.display_name)
	assert_has(texts, CAMPANARIO.epithet, "con su apodo")
	await wait_physics_frames(1)
