class_name Bomb
extends Node2D
## Bomba que pone el jugador: la mecha dura FUSE_TIME (la chispa parpadea cada vez más rápido) y
## explota. La explosión lastima a todo lo que esté cerca (enemigos y jugador), rompe rocas y avisa
## por EventBus.exploded, que FloorController usa para destapar puertas secretas.

const FUSE_TIME: float = 1.6
const RADIUS: float = 34.0
const ENEMY_DAMAGE: float = 10.0
## Medio corazón: castiga quedarse al lado sin ser tan duro.
const PLAYER_DAMAGE: float = 1.0
const KNOCKBACK: float = 220.0
const TRAUMA: float = 0.7
const HITSTOP: float = 0.06
const BLINK_SLOW: float = 0.3
const BLINK_FAST: float = 0.06
const FIRE_COLOR: Color = Color("ff9a3c")
const BODY_COLOR: Color = Color("3b3445")
const OUTLINE_COLOR: Color = Color("120c16")
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const WAVE_SCENE: PackedScene = preload("res://fx/pulse_wave.tscn")
const STAIN_SCENE: PackedScene = preload("res://fx/floor_stain.tscn")

var _fuse_left: float = FUSE_TIME
var _blink_time: float = 0.0


func _physics_process(delta: float) -> void:
	_fuse_left -= delta
	if _fuse_left <= 0.0:
		explode()


func _process(delta: float) -> void:
	_blink_time += delta
	queue_redraw()


func explode() -> void:
	if is_queued_for_deletion():
		return
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		_hit((node as Enemy).hurtbox, ENEMY_DAMAGE)
	for node: Node in get_tree().get_nodes_in_group(Player.GROUP):
		_hit((node as Player).hurtbox, PLAYER_DAMAGE)
	for node: Node in get_tree().get_nodes_in_group(Rock.GROUP):
		var rock := node as Rock
		if rock.global_position.distance_to(global_position) <= RADIUS + Rock.HALF_SIZE:
			rock.destroy()
	EventBus.exploded.emit(global_position, RADIUS)
	var wave := Fx.spawn(get_tree(), WAVE_SCENE, global_position) as PulseWave
	wave.color = FIRE_COLOR
	wave.duration = 0.2
	wave.max_radius = RADIUS + 6.0
	var burst := Fx.spawn(get_tree(), BURST_SCENE, global_position) as CPUParticles2D
	burst.color = FIRE_COLOR
	burst.amount = 24
	var stain := Fx.spawn(get_tree(), STAIN_SCENE, global_position, Fx.DECALS_GROUP) as FloorStain
	stain.color = Color(0.05, 0.04, 0.06)
	stain.radius = 12.0
	EventBus.shake_requested.emit(TRAUMA)
	EventBus.hitstop_requested.emit(HITSTOP)
	AudioManager.play_sfx(&"explosion", 0.05)
	queue_free()


func _hit(hurtbox: HurtboxComponent, damage: float) -> void:
	var offset: Vector2 = hurtbox.global_position - global_position
	if offset.length() <= RADIUS:
		hurtbox.receive_hit(HitInfo.create(damage, offset, KNOCKBACK))


func _draw() -> void:
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	var progress: float = 1.0 - clampf(_fuse_left / FUSE_TIME, 0.0, 1.0)
	var period: float = lerpf(BLINK_SLOW, BLINK_FAST, progress)
	var lit: bool = fmod(_blink_time, period) < period * 0.5
	draw_circle(Vector2(0, -1), 5.0, OUTLINE_COLOR)
	draw_circle(Vector2(0, -1), 4.0, BODY_COLOR.lerp(FIRE_COLOR, 0.5) if lit else BODY_COLOR)
	draw_rect(Rect2(-2, -4, 1, 1), Color(1, 1, 1, 0.7))
	draw_line(Vector2(1, -5), Vector2(3, -8), OUTLINE_COLOR, 1.0)
	if lit:
		draw_circle(Vector2(3, -9), 1.5, FIRE_COLOR)
