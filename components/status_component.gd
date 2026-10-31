class_name StatusComponent
extends Node2D
## Estados alterados de un enemigo. Los aplican las balas, el láser, los orbes, el riel y las
## explosiones del jugador según las chances de su ShotSpec (apply_hit). El daño de cada estado sale
## del golpe que lo aplicó.
## FUEGO: quema cada BURN_INTERVAL s durante BURN_TIME (BURN_FRACTION del golpe por vez); un golpe
## nuevo lo renueva.
## VENENO: se acumula hasta POISON_MAX_STACKS capas; cada capa saca POISON_FRACTION del golpe por
## segundo durante POISON_TIME (cada golpe nuevo renueva el tiempo).
## CORRUPCIÓN: CORRUPT_TIME s recibiendo más daño (CORRUPT_DAMAGE_TAKEN); si muere corrupto revienta
## en un anillo de balas del jugador.
## APAGADO (las brasas se apagan): DOUSE_TIME s a DOUSE_SPEED de su velocidad, al moverse y al atacar.
## Dibuja encima del enemigo las marcas de cada estado (llamitas, burbujas, chispas violetas, humo) y
## tiñe su dibujo.

enum Kind { BURN, POISON, CORRUPT, DOUSE }

const BURN_INTERVAL: float = 0.5
const BURN_TIME: float = 3.0
const BURN_FRACTION: float = 0.25
const POISON_INTERVAL: float = 0.5
const POISON_TIME: float = 5.0
const POISON_FRACTION: float = 0.15
const POISON_MAX_STACKS: int = 4
const CORRUPT_TIME: float = 4.0
const CORRUPT_DAMAGE_TAKEN: float = 1.35
const CORRUPT_BURST: int = 6
const CORRUPT_BURST_FRACTION: float = 0.6
const DOUSE_TIME: float = 2.5
const DOUSE_SPEED: float = 0.5
const COLORS: Dictionary[Kind, Color] = {
	Kind.BURN: Color("ff8a3d"),
	Kind.POISON: Color("7fd65a"),
	Kind.CORRUPT: Color("b05ce8"),
	Kind.DOUSE: Color("9fc4e0"),
}
## Tinte del dibujo del enemigo (el del estado más importante).
const TINTS: Dictionary[Kind, Color] = {
	Kind.BURN: Color(1.0, 0.82, 0.68),
	Kind.POISON: Color(0.78, 1.0, 0.72),
	Kind.CORRUPT: Color(0.86, 0.68, 1.0),
	Kind.DOUSE: Color(0.66, 0.76, 0.95),
}
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")

@export var health: HealthComponent
@export var hurtbox: HurtboxComponent
## El dibujo que se tiñe.
@export var visual: CanvasItem

## Radio del dibujo del enemigo (para ubicar las marcas).
var radius: float = 7.0
var _left: Dictionary[Kind, float] = {}
var _tick: Dictionary[Kind, float] = {}
var _damage: Dictionary[Kind, float] = {}
var _poison_stacks: int = 0
var _time: float = 0.0


func _ready() -> void:
	health.died.connect(_on_died)


## Tira las chances de `spec` y le aplica a quien tenga `target` los estados que salgan. Lo llaman
## las balas, el láser, los orbes, el riel y las explosiones después de pegar.
static func apply_hit(target: HurtboxComponent, spec: ShotSpec) -> void:
	if not spec.has_status():
		return
	var enemy := target.owner as Enemy
	if enemy == null or enemy.health.is_dead():
		return
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.COMBAT)
	var chances: Dictionary[Kind, float] = {
		Kind.BURN: spec.burn_chance, Kind.POISON: spec.poison_chance,
		Kind.CORRUPT: spec.corrupt_chance, Kind.DOUSE: spec.douse_chance,
	}
	for kind: Kind in chances:
		if chances[kind] > 0.0 and rng.randf() < chances[kind]:
			enemy.status.apply(kind, spec.damage)


func has(kind: Kind) -> bool:
	return _left.get(kind, 0.0) > 0.0


func poison_stacks() -> int:
	return _poison_stacks if has(Kind.POISON) else 0


## Multiplica la velocidad del enemigo (moverse y atacar).
func speed_factor() -> float:
	return DOUSE_SPEED if has(Kind.DOUSE) else 1.0


func apply(kind: Kind, hit_damage: float) -> void:
	match kind:
		Kind.BURN:
			if not has(kind):
				_tick[kind] = BURN_INTERVAL
			_left[kind] = BURN_TIME
			_damage[kind] = maxf(_damage.get(kind, 0.0) if has(kind) else 0.0, hit_damage * BURN_FRACTION)
		Kind.POISON:
			if not has(kind):
				_poison_stacks = 0
				_tick[kind] = POISON_INTERVAL
			_poison_stacks = mini(_poison_stacks + 1, POISON_MAX_STACKS)
			_left[kind] = POISON_TIME
			_damage[kind] = maxf(_damage.get(kind, 0.0) if has(kind) else 0.0, hit_damage * POISON_FRACTION)
		Kind.CORRUPT:
			_left[kind] = CORRUPT_TIME
			_damage[kind] = maxf(_damage.get(kind, 0.0), hit_damage)
			hurtbox.damage_multiplier = CORRUPT_DAMAGE_TAKEN
		Kind.DOUSE:
			_left[kind] = DOUSE_TIME
	_update_tint()


func _physics_process(delta: float) -> void:
	if health.is_dead() or _left.is_empty():
		return
	for kind: Kind in _left.keys():
		_left[kind] -= delta
		if kind == Kind.BURN or kind == Kind.POISON:
			_tick[kind] -= delta
			if _tick[kind] <= 0.0:
				_tick[kind] += BURN_INTERVAL if kind == Kind.BURN else POISON_INTERVAL
				_hurt(kind)
				if health.is_dead():
					return
		if _left[kind] <= 0.0:
			_left.erase(kind)
			if kind == Kind.CORRUPT:
				hurtbox.damage_multiplier = 1.0
			_update_tint()


func _process(delta: float) -> void:
	_time += delta
	if not _left.is_empty():
		queue_redraw()


func _hurt(kind: Kind) -> void:
	var amount: float = _damage[kind]
	if kind == Kind.POISON:
		amount *= _poison_stacks * POISON_INTERVAL
	health.take_damage(amount)


func _update_tint() -> void:
	var tint: Color = Color.WHITE
	# El más importante manda: apagado, corrupción, veneno y fuego.
	for kind: Kind in [Kind.BURN, Kind.POISON, Kind.CORRUPT, Kind.DOUSE]:
		if has(kind):
			tint = TINTS[kind]
	if visual != null:
		visual.self_modulate = tint
	queue_redraw()


## Si muere corrupto revienta en balas del jugador. Puede llegar desde un callback de física (el
## golpe que lo mató): las balas salen diferidas.
func _on_died() -> void:
	if has(Kind.CORRUPT):
		_burst.call_deferred(get_tree(), global_position, _damage[Kind.CORRUPT] * CORRUPT_BURST_FRACTION)


static func _burst(tree: SceneTree, at: Vector2, damage: float) -> void:
	var spec := ShotSpec.new()
	spec.damage = damage
	spec.speed = 160.0
	spec.max_range = 110.0
	spec.knockback = 60.0
	spec.radius = 2.5
	spec.color = COLORS[Kind.CORRUPT]
	for direction: Vector2 in PatternMath.ring(CORRUPT_BURST, 0.0):
		Bullet.spawn(tree, BULLET_SCENE, spec, at + direction * 6.0, direction, PhysicsLayers.PLAYER_BULLET,
				PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX)


func _draw() -> void:
	var top: float = -radius - 4.0
	if has(Kind.BURN):
		var color: Color = COLORS[Kind.BURN]
		for i: int in 3:
			var rise: float = fmod(_time * 10.0 + i * 3.0, 6.0)
			var at := Vector2(roundf((i - 1) * radius * 0.6), roundf(-rise))
			draw_rect(Rect2(at, Vector2(1, 2 if rise < 3.0 else 1)), color if rise < 4.0 else Color("ffd166"))
	if has(Kind.POISON):
		var color: Color = COLORS[Kind.POISON]
		for i: int in _poison_stacks:
			var rise: float = fmod(_time * 6.0 + i * 2.5, 8.0)
			draw_rect(Rect2(Vector2(roundf((i - 1.5) * 3.0), roundf(top + 4.0 - rise)), Vector2.ONE), Color(color, 1.0 - rise / 8.0))
	if has(Kind.CORRUPT):
		var color: Color = COLORS[Kind.CORRUPT]
		for i: int in 4:
			var angle: float = _time * 3.0 + TAU * i / 4.0
			draw_rect(Rect2((Vector2.from_angle(angle) * (radius + 2.0) + Vector2(0, -2)).round(), Vector2.ONE), color)
	if has(Kind.DOUSE):
		var color: Color = COLORS[Kind.DOUSE]
		for i: int in 2:
			var drift: float = fmod(_time * 4.0 + i * 4.0, 8.0)
			draw_circle(Vector2(roundf((i - 0.5) * radius), roundf(top - drift)), 1.5, Color(color, 0.6 * (1.0 - drift / 8.0)))
