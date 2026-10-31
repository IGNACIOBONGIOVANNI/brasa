class_name Bullet
extends Area2D
## Proyectil: avanza en línea recta y muere al llegar a su alcance, al chocar una pared o al golpear
## un HurtboxComponent. Si el hurtbox está invulnerable (rodando, i-frames) la bala sigue.
## Según su ShotSpec además rebota en las paredes (bounces), atraviesa enemigos (pierce) y dobla
## hacia el enemigo más cercano (homing); las tres cosas se combinan solas.
## Las capas de colisión las define quien dispara (bala del jugador o de un enemigo).
## Tiene que quedar monitorable: en Godot 4.7 un Area2D con monitorable = false no detecta cuerpos
## estáticos, y las balas atravesarían paredes y rocas.

const GROUP: StringName = &"bullets"
const PROJECTILES_GROUP: StringName = &"projectiles"
const IMPACT_SCENE: PackedScene = preload("res://fx/bullet_impact.tscn")
## Distancia a la que una bala teledirigida "ve" enemigos.
const HOMING_RANGE: float = 110.0
## Radianes por segundo que dobla una bala con homing 1.
const HOMING_TURN_RATE: float = 9.0
## Estela: cuántas posiciones guarda, su ancho (en radios de la bala) y su opacidad.
const TRAIL_LENGTH: int = 4
const TRAIL_WIDTH: float = 1.2
const TRAIL_ALPHA: float = 0.45

var spec: ShotSpec
var _velocity: Vector2 = Vector2.ZERO
var _traveled: float = 0.0
var _dead: bool = false
var _bounces_left: int = 0
var _pierce_left: int = 0
## Hurtboxes que ya golpeó (por id), para que al atravesar no pegue dos veces al mismo.
var _hit_targets: Dictionary[int, bool] = {}
## Últimas posiciones (globales) para la estela.
var _trail_points: PackedVector2Array = []

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: PlaceholderShape = $Visual
@onready var _trail: Line2D = $Trail


## Crea una bala y la agrega al nodo del grupo "projectiles" (así no se mueve con el tirador).
static func spawn(tree: SceneTree, scene: PackedScene, shot: ShotSpec, at: Vector2, direction: Vector2,
		layer: int, mask: int) -> Bullet:
	var bullet := scene.instantiate() as Bullet
	bullet.setup(shot, direction, layer, mask)
	var container: Node = tree.get_first_node_in_group(PROJECTILES_GROUP)
	if container == null:
		container = tree.current_scene if tree.current_scene != null else tree.root
	container.add_child(bullet)
	bullet.global_position = at
	return bullet


## Llamar antes de agregar la bala al árbol.
func setup(shot: ShotSpec, direction: Vector2, layer: int, mask: int) -> void:
	spec = shot
	_velocity = direction.normalized() * shot.speed
	_bounces_left = shot.bounces
	_pierce_left = shot.pierce
	collision_layer = layer
	collision_mask = mask
	rotation = direction.angle()


func _ready() -> void:
	assert(spec != null, "Bullet: llamar a setup() antes de agregarla al árbol")
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var circle := CircleShape2D.new()
	circle.radius = spec.radius
	_shape.shape = circle
	_visual.size = Vector2.ONE * spec.radius * 2.0
	_visual.color = spec.color
	_visual.outline_color = spec.color.darkened(0.6)
	_trail.width = spec.radius * TRAIL_WIDTH
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(spec.color, 0.0), Color(spec.color, TRAIL_ALPHA)])
	_trail.gradient = fade


func _physics_process(delta: float) -> void:
	if spec.homing > 0.0:
		_steer(delta)
	var step: Vector2 = _velocity * delta
	if not (_bounces_left > 0 and _try_bounce(step)):
		position += step
	_traveled += step.length()
	_trail_points.append(global_position)
	if _trail_points.size() > TRAIL_LENGTH:
		_trail_points.remove_at(0)
	_trail.points = _trail_points
	if _traveled >= spec.max_range:
		destroy()


func is_hostile_to_player() -> bool:
	return collision_layer & PhysicsLayers.ENEMY_BULLET != 0


## Saca la bala dejando chispas (al chocar o cuando un Pulso la borra).
func destroy() -> void:
	if _dead:
		return
	_dead = true
	var impact := Fx.spawn(get_tree(), IMPACT_SCENE, global_position) as CPUParticles2D
	impact.color = spec.color
	queue_free()


## Si en este paso choca una pared, rebota: refleja la velocidad con la normal de la pared.
func _try_bounce(step: Vector2) -> bool:
	var from: Vector2 = global_position
	var to: Vector2 = from + step + step.normalized() * spec.radius
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(from, to, PhysicsLayers.WALL))
	if hit.is_empty():
		return false
	var normal: Vector2 = hit.normal
	var point: Vector2 = hit.position
	_velocity = _velocity.bounce(normal)
	global_position = point + normal * (spec.radius + 0.5)
	rotation = _velocity.angle()
	_bounces_left -= 1
	if spec.impact_sfx_id != &"":
		AudioManager.play_sfx(spec.impact_sfx_id, 0.15)
	return true


## Dobla un poco hacia el enemigo vivo más cercano (que todavía no atravesó).
func _steer(delta: float) -> void:
	var target: HurtboxComponent = null
	var best_distance: float = HOMING_RANGE
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy.health.is_dead() or _hit_targets.has(enemy.hurtbox.get_instance_id()):
			continue
		var distance: float = enemy.hurtbox.global_position.distance_to(global_position)
		if distance < best_distance:
			best_distance = distance
			target = enemy.hurtbox
	if target == null:
		return
	var wanted: float = (target.global_position - global_position).angle()
	var max_turn: float = HOMING_TURN_RATE * spec.homing * delta
	_velocity = _velocity.rotated(clampf(angle_difference(_velocity.angle(), wanted), -max_turn, max_turn))
	rotation = _velocity.angle()


func _on_body_entered(_body: Node2D) -> void:
	# Las que rebotan se manejan con el rayo de _try_bounce.
	if _bounces_left > 0:
		return
	if not _dead and spec.impact_sfx_id != &"":
		AudioManager.play_sfx(spec.impact_sfx_id, 0.15)
	destroy()


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if _dead or hurtbox == null or _hit_targets.has(hurtbox.get_instance_id()):
		return
	if hurtbox.receive_hit(HitInfo.create(spec.damage, _velocity, spec.knockback)):
		_hit_targets[hurtbox.get_instance_id()] = true
		if _pierce_left > 0:
			_pierce_left -= 1
		else:
			destroy()
