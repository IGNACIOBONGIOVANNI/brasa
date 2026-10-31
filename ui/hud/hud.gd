class_name Hud
extends CanvasLayer
## HUD de la run: corazones del jugador y cargas de Pulso. Va arriba a la izquierda, sobre la pared.

@onready var _hearts: HeartsDisplay = $Hearts
@onready var _pulses: PulseDisplay = $Pulses


func bind_player(player: Player) -> void:
	player.health.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health.current, player.health.max_health)
	RunState.blanks_changed.connect(_pulses.set_count)
	_pulses.set_count(RunState.blanks)


func _on_health_changed(current: float, max_value: float) -> void:
	_hearts.set_health(roundi(current), roundi(max_value))
