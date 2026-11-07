class_name Brazier
extends StaticBody2D
## El brasero frío del camino secreto (docs/LORE.md): con él despedían a los que bajaban, y está apagado
## desde que la fragua se apagó. Está en una sala del piso del brasero (FloorController.brazier_cell),
## tapa el paso como una roca pero no se rompe. Una bomba que explota cerca lo enciende: da el Ascua
## (RunState.give_ember) con un cartel, y queda prendido el resto de la run (también al seguirla).

const UNSHADED: Material = preload("res://fx/unshaded.tres")
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const LIGHT_FLASH_SCENE: PackedScene = preload("res://fx/light_flash.tscn")
const RADIUS: float = 5.0
## Margen (además del radio de la explosión) para que una bomba lo encienda.
const REACH: float = 12.0
const TITLE: String = "Ascua"
const SUBTITLE: String = "Una brasa que no se apaga. Más abajo, algo la está esperando."
const OUTLINE_COLOR: Color = Color("120c16")
const IRON_COLOR: Color = Color("4a4552")
const ASH_COLOR: Color = Color("8a8490")
const SMOKE_COLOR: Color = Color(0.75, 0.72, 0.78, 0.35)
const FLAME_COLOR: Color = Color("ff8a3d")
const FLAME_CORE: Color = Color("ffd166")

var lit: bool = false
var _time: float = 0.0


func _ready() -> void:
	material = UNSHADED
	collision_layer = PhysicsLayers.WALL
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	lit = RunState.secret != RunState.Secret.NONE
	EventBus.exploded.connect(_on_exploded)


func _on_exploded(at: Vector2, radius: float) -> void:
	if not lit and at.distance_to(global_position) <= radius + REACH:
		light()


## Lo enciende (y da el Ascua si todavía no la tenía).
func light() -> void:
	if lit:
		return
	lit = true
	if RunState.give_ember():
		EventBus.message_requested.emit(TITLE, SUBTITLE)
	AudioManager.play_sfx(&"secret_found")
	AudioManager.play_sfx(&"molten", 0.05)
	var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position + Vector2(0, -6)) as CPUParticles2D
	burst.color = FLAME_COLOR
	var glow := Fx.spawn(get_tree(), LIGHT_FLASH_SCENE, global_position) as LightFlash
	glow.color = FLAME_COLOR
	glow.texture_scale = 2.5


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# Tres patas de hierro y el cuenco.
	for leg: Vector2 in [Vector2(-5, 7), Vector2(5, 7), Vector2(0, 8)]:
		draw_line(Vector2(leg.x * 0.5, 1), leg, OUTLINE_COLOR, 3.0)
		draw_line(Vector2(leg.x * 0.5, 1), leg, IRON_COLOR, 1.0)
	var bowl := PackedVector2Array([Vector2(-7, -3), Vector2(7, -3), Vector2(5, 2), Vector2(-5, 2)])
	var rim := PackedVector2Array([Vector2(-8, -4), Vector2(8, -4), Vector2(6, 3), Vector2(-6, 3)])
	draw_colored_polygon(rim, OUTLINE_COLOR)
	draw_colored_polygon(bowl, IRON_COLOR)
	draw_line(Vector2(-6, -2), Vector2(6, -2), IRON_COLOR.lightened(0.25), 1.0)
	if not lit:
		# Ceniza fría y un hilo de humo que apenas sube.
		draw_rect(Rect2(-5, -5, 10, 2), ASH_COLOR)
		draw_rect(Rect2(-3, -6, 5, 1), ASH_COLOR.lightened(0.15))
		for k: int in 4:
			var rise: float = fmod(_time * 6.0 + k * 4.0, 16.0)
			var sway: float = sin(_time * 1.5 + k) * 1.5
			draw_rect(Rect2(Vector2(sway, -7.0 - rise).round(), Vector2.ONE), Color(SMOKE_COLOR, SMOKE_COLOR.a * (1.0 - rise / 16.0)))
		return
	# Prendido: brasas, llamas que titilan y un halo.
	var flicker: float = 0.5 + 0.5 * sin(_time * 11.0) * sin(_time * 6.3)
	draw_circle(Vector2(0, -6), 11.0, Color(FLAME_COLOR, 0.12 + 0.06 * flicker))
	draw_rect(Rect2(-5, -5, 10, 2), FLAME_COLOR.darkened(0.3))
	for k: int in 3:
		var x: float = -4.0 + k * 4.0
		var height: float = 4.0 + 3.0 * absf(sin(_time * (7.0 + k) + k * 1.7))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 2, -4), Vector2(x + 2, -4), Vector2(x, -4 - height)]), FLAME_COLOR)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 1, -4), Vector2(x + 1, -4), Vector2(x, -4 - height * 0.6)]), FLAME_CORE)
	for k: int in 3:
		var rise: float = fmod(_time * 14.0 + k * 6.0, 18.0)
		draw_rect(Rect2(Vector2(sin(_time * 3.0 + k * 2.0) * 3.0, -8.0 - rise).round(), Vector2.ONE),
				Color(FLAME_CORE, 1.0 - rise / 18.0))
