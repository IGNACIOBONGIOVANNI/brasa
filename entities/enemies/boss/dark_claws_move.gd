class_name DarkClawsMove
extends BossMove
## DARK_CLAWS: durante el aviso apaga la luz de la sala (solo queda la del jugador) y se desvanece;
## escondido (no recibe ni hace daño) tira `count` zarpazos donde está el jugador, uno cada `interval`
## s, cada uno con su aviso de tres tajos. Al terminar vuelve la luz y aparece en otro lado, lejos del
## jugador. Si lo cortan (cambio de fase, muerte), la luz vuelve igual.

## Largo de cada tajo (de punta a punta).
const SLASH_LENGTH: float = 44.0
## Qué tan lejos del jugador cae cada zarpazo (para que no sea siempre en el mismo punto).
const CLAW_JITTER: float = 6.0
## Al volver aparece al menos a esta distancia del jugador.
const RETURN_DISTANCE: float = 80.0
const LIGHT_BACK_TIME: float = 0.4
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")

var _left: int = 0
var _next: float = 0.0
var _wait: float = 0.0
var _back: bool = false


func _on_windup() -> void:
	EventBus.darkness_requested.emit(attack.darkness, attack.windup)
	AudioManager.play_sfx(&"darkness", 0.05)


func _windup_tick(delta: float) -> void:
	hold(delta)
	enemy.visual.self_modulate.a = clampf(_windup_left / attack.windup, 0.0, 1.0) if attack.windup > 0.0 else 0.0


func _begin() -> void:
	enemy.set_airborne(true)
	enemy.visual.self_modulate.a = 0.0
	_left = attack.count


func _tick(delta: float) -> bool:
	if _left > 0:
		_next -= delta
		if _next <= 0.0:
			_claw()
			_left -= 1
			_next = attack.interval
		return false
	_wait += delta
	if _wait < attack.warn_time + 0.15:
		return false
	_return_elsewhere()
	return true


func _end() -> void:
	if not _back:
		_come_back()


func _claw() -> void:
	var at: Vector2 = target_position() + Vector2.from_angle(rng().randf() * TAU) * rng().randf() * CLAW_JITTER
	var strike: BossStrike = spawn_strike(clamp_to_room(at, 4.0), BossAttack.Look.CLAW)
	strike.slash = Vector2.from_angle(rng().randf() * TAU) * SLASH_LENGTH * 0.5
	AudioManager.play_sfx(&"trap_warn", 0.1)


## Aparece en un lugar de la sala lejos del jugador (prueba unos cuantos al azar).
func _return_elsewhere() -> void:
	var area: Rect2 = enemy.room_rect().grow(-(enemy.data.body_radius + 8.0))
	var best: Vector2 = enemy.global_position
	var best_distance: float = -1.0
	for _try: int in 8:
		var spot := Vector2(rng().randf_range(area.position.x, area.end.x), rng().randf_range(area.position.y, area.end.y))
		var distance: float = spot.distance_to(target_position())
		if distance > best_distance:
			best = spot
			best_distance = distance
		if distance >= RETURN_DISTANCE:
			break
	enemy.global_position = enemy.landing_spot(best)
	var burst := Fx.spawn(enemy.get_tree(), BURST_SCENE, enemy.global_position) as CPUParticles2D
	burst.color = enemy.data.body_color
	_come_back()


func _come_back() -> void:
	_back = true
	enemy.visual.self_modulate.a = 1.0
	enemy.set_airborne(false)
	EventBus.darkness_requested.emit(0.0, LIGHT_BACK_TIME)
