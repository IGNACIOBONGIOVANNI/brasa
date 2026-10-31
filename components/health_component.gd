class_name HealthComponent
extends Node
## Vida de una entidad. Las cuentas están en HealthMath; este nodo guarda el estado, maneja la
## invulnerabilidad (i-frames) y avisa por señales.

signal health_changed(current: float, max_value: float)
signal died

@export var max_health: float = 6.0
## Segundos de invulnerabilidad después de recibir daño. 0 = ninguno.
@export var invulnerability_after_hit: float = 0.0

var current: float
## Modo dios (menú de debug): ignora todo el daño.
var always_invulnerable: bool = false
var _invulnerable_left: float = 0.0


func _ready() -> void:
	current = max_health


func _physics_process(delta: float) -> void:
	_invulnerable_left = maxf(0.0, _invulnerable_left - delta)


## Cambia el máximo y llena la vida (los enemigos se configuran así desde su EnemyData).
func setup(new_max: float) -> void:
	max_health = new_max
	current = new_max
	health_changed.emit(current, max_health)


func is_dead() -> bool:
	return HealthMath.is_dead(current)


func is_invulnerable() -> bool:
	return always_invulnerable or _invulnerable_left > 0.0


func can_take_damage() -> bool:
	return not is_dead() and not is_invulnerable()


## Aplica el daño si no está muerto ni invulnerable. Devuelve true si lo aplicó.
func take_damage(amount: float) -> bool:
	if not can_take_damage():
		return false
	current = HealthMath.damaged(current, amount)
	health_changed.emit(current, max_health)
	if is_dead():
		died.emit()
	elif invulnerability_after_hit > 0.0:
		grant_invulnerability(invulnerability_after_hit)
	return true


func heal(amount: float) -> void:
	if is_dead():
		return
	current = HealthMath.healed(current, amount, max_health)
	health_changed.emit(current, max_health)


## Cambia el máximo. Si sube, la vida actual sube lo mismo (un contenedor nuevo llega lleno).
func set_max(new_max: float) -> void:
	var gained: float = maxf(0.0, new_max - max_health)
	max_health = new_max
	if not is_dead():
		current = HealthMath.healed(current, gained, max_health)
	health_changed.emit(current, max_health)


## Invulnerable durante `seconds` (si ya lo era por más tiempo, queda el mayor).
func grant_invulnerability(seconds: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left, seconds)


## Vuelve a la vida con `amount` (un item que salva de la muerte).
func revive(amount: float) -> void:
	current = HealthMath.healed(0.0, amount, max_health)
	health_changed.emit(current, max_health)


## Muerte inmediata, aunque sea invulnerable (menú de debug).
func kill() -> void:
	if is_dead():
		return
	current = 0.0
	health_changed.emit(current, max_health)
	died.emit()
