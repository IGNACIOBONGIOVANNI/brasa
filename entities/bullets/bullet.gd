class_name Bullet
extends Area2D
## Proyectil simple: avanza en línea recta y muere al llegar a su alcance, al chocar una pared o al
## golpear un HurtboxComponent. Si el hurtbox está invulnerable (rodando, i-frames) la bala sigue.
## Las capas de colisión las define quien dispara (bala del jugador o de un enemigo).
## Tiene que quedar monitorable: en Godot 4.7 un Area2D con monitorable = false no detecta cuerpos
## estáticos, y las balas atravesarían paredes y rocas.

const GROUP: StringName = &"bullets"
const PROJECTILES_GROUP: StringName = &"projectiles"
const IMPACT_SCENE: PackedScene = preload("res://fx/bullet_impact.tscn")

var spec: ShotSpec
var _velocity: Vector2 = Vector2.ZERO
var _traveled: float = 0.0
var _dead: bool = false

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: PlaceholderShape = $Visual


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


func _physics_process(delta: float) -> void:
	var step: Vector2 = _velocity * delta
	position += step
	_traveled += step.length()
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


func _on_body_entered(_body: Node2D) -> void:
	if not _dead and spec.impact_sfx_id != &"":
		AudioManager.play_sfx(spec.impact_sfx_id, 0.15)
	destroy()


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if _dead or hurtbox == null:
		return
	if hurtbox.receive_hit(HitInfo.create(spec.damage, _velocity, spec.knockback)):
		destroy()
