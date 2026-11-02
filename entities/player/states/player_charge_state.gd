class_name PlayerChargeState
extends State
## Embestir (Testa, CharacterData.Dodge.CHARGE): en vez de rodar, baja la cabeza y sale disparado en
## la dirección del movimiento (o de la mira si está quieto). Es invulnerable lo mismo que una rodada
## (así se esquiva todo lo que se esquiva rodando), lastima una vez a cada enemigo que atropella
## (los escudos no lo frenan: cabeza dura) y lo empuja lejos. Si choca de frente contra una roca la
## rompe; contra una pared o un foso, rebota y se termina. No dispara mientras dura.

## Px por segundo: más rápido y más lejos que rodar.
const SPEED: float = 250.0
## Velocidad del final respecto de la del principio.
const END_SPEED_FACTOR: float = 0.7
## Daño a cada enemigo atropellado, en veces el daño del jugador.
const DAMAGE_FACTOR: float = 3.0
const KNOCKBACK: float = 230.0
## Alcance del golpe: un círculo un poco adelante del cuerpo.
const REACH: float = 9.0
const AHEAD: float = 3.0
## Más que el de rodar: embestir es fuerte.
const COOLDOWN: float = 0.45
const HIT_TRAUMA: float = 0.3
const HIT_HITSTOP: float = 0.04
const BUMP_TRAUMA: float = 0.35
## Rebote al chocar de frente (px por segundo hacia atrás).
const BUMP_SPEED: float = 70.0
## Cuánto de frente tiene que ser el choque para cortarla (coseno): de costado se desliza.
const HEAD_ON: float = 0.5
const DUST_SCENE: PackedScene = preload("res://fx/dust_puff.tscn")
const AFTERIMAGE_SCENE: PackedScene = preload("res://fx/afterimage.tscn")
const AFTERIMAGE_INTERVAL: float = 0.05

var _direction: Vector2 = Vector2.RIGHT
var _time_left: float = 0.0
var _afterimage_left: float = 0.0
## Enemigos que ya atropelló en esta embestida (por id).
var _hit: Dictionary[int, bool] = {}

@onready var player: Player = owner as Player


func enter(_previous: StringName) -> void:
	var move_input: Vector2 = player.read_move_input()
	_direction = (move_input if move_input != Vector2.ZERO else player.aim_direction).normalized()
	_time_left = player.roll_time
	_hit.clear()
	player.health.grant_invulnerability(player.roll_time)
	player.weapon.release()
	player.cancel_bomb()
	player.visual.set_charging(true, _direction)
	AudioManager.play_sfx(&"ram", 0.08)
	Fx.spawn(get_tree(), DUST_SCENE, player.global_position + Vector2(0, 4))


func exit() -> void:
	player.visual.set_charging(false, _direction)
	player.start_roll_cooldown(COOLDOWN)
	player.move_velocity = _direction * minf(player.move_velocity.length(), RunState.stats.move_speed)


func physics_update(delta: float) -> void:
	_time_left -= delta
	_afterimage_left -= delta
	if _afterimage_left <= 0.0:
		_afterimage_left = AFTERIMAGE_INTERVAL
		var ghost := Fx.spawn(get_tree(), AFTERIMAGE_SCENE, player.global_position, Fx.DECALS_GROUP) as Afterimage
		ghost.color = player.visual.body_color
	var progress: float = 1.0 - clampf(_time_left / player.roll_time, 0.0, 1.0)
	player.move_velocity = _direction * SPEED * lerpf(1.0, END_SPEED_FACTOR, progress)
	player.apply_velocity()
	player.update_aim()
	_ram_enemies()
	if _crashed():
		machine.transition_to(&"Move")
	elif _time_left <= 0.0:
		machine.transition_to(&"Move")


## Lastima a cada enemigo que toca (una vez por embestida).
func _ram_enemies() -> void:
	var center: Vector2 = player.global_position + _direction * AHEAD
	var damage: float = RunState.stats.damage * DAMAGE_FACTOR
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy == null or enemy.is_hidden() or _hit.has(enemy.get_instance_id()):
			continue
		if center.distance_to(enemy.global_position) > REACH + enemy.data.hurtbox_radius:
			continue
		_hit[enemy.get_instance_id()] = true
		var push: Vector2 = (enemy.global_position - player.global_position).normalized()
		if push == Vector2.ZERO:
			push = _direction
		if enemy.hurtbox.receive_hit(HitInfo.create(damage, (push + _direction).normalized(), KNOCKBACK)):
			AudioManager.play_sfx(&"ram_hit", 0.1)
			EventBus.shake_requested.emit(HIT_TRAUMA)
			EventBus.hitstop_requested.emit(HIT_HITSTOP)


## Si chocó de frente: rompe la roca (o rebota en la pared o el foso) y se termina.
func _crashed() -> bool:
	for i: int in player.get_slide_collision_count():
		var collision: KinematicCollision2D = player.get_slide_collision(i)
		if -collision.get_normal().dot(_direction) < HEAD_ON:
			continue
		var rock := collision.get_collider() as Rock
		if rock != null:
			rock.destroy()
		player.move_velocity = collision.get_normal() * BUMP_SPEED
		_direction = collision.get_normal()
		EventBus.shake_requested.emit(BUMP_TRAUMA)
		AudioManager.play_sfx(&"ram_hit", 0.1)
		return true
	return false
