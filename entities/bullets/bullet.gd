class_name Bullet
extends Area2D
## Proyectil simple: avanza en línea recta y muere al llegar a su alcance o al chocar una pared.
## Las capas de colisión las define quien dispara (bala del jugador o de un enemigo).

const GROUP: StringName = &"bullets"
const IMPACT_SCENE: PackedScene = preload("res://fx/bullet_impact.tscn")

var spec: ShotSpec
var _velocity: Vector2 = Vector2.ZERO
var _traveled: float = 0.0
var _dead: bool = false

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: PlaceholderShape = $Visual


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
	var circle := CircleShape2D.new()
	circle.radius = spec.radius
	_shape.shape = circle
	_visual.size = Vector2.ONE * spec.radius * 2.0
	_visual.color = spec.color


func _physics_process(delta: float) -> void:
	var step: Vector2 = _velocity * delta
	position += step
	_traveled += step.length()
	if _traveled >= spec.max_range:
		_die()


func _on_body_entered(_body: Node2D) -> void:
	_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	var impact := IMPACT_SCENE.instantiate() as CPUParticles2D
	impact.position = position
	impact.color = spec.color
	get_parent().add_child.call_deferred(impact)
	queue_free()
