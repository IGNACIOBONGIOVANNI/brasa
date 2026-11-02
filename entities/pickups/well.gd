class_name Well
extends Area2D
## Pozo de brasas (sala especial WELL): agua tibia de la fragua. Al tocarlo, si al jugador le falta
## vida o algún Pulso, lo cura del todo y le devuelve los Pulsos; después queda seco. Si no le falta
## nada, espera a que vuelva.

signal used

const SPARKLE_SCENE: PackedScene = preload("res://fx/burst.tscn")
const LIGHT_FLASH_SCENE: PackedScene = preload("res://fx/light_flash.tscn")
const GLOW_COLOR: Color = Color("ffb35c")

var dry: bool = false

@onready var _visual: WellVisual = $Visual


func _ready() -> void:
	_visual.dry = dry


## Seco sin usarlo (al seguir una run guardada). Se puede llamar antes de agregarlo al árbol.
func set_dry() -> void:
	dry = true
	if is_node_ready():
		_visual.dry = true


func _physics_process(_delta: float) -> void:
	if dry:
		return
	for body: Node2D in get_overlapping_bodies():
		var player := body as Player
		if player != null and not player.is_dead() and _needs_it(player):
			_use(player)
			return


func _needs_it(player: Player) -> bool:
	return player.health.current < player.health.max_health or RunState.blanks < RunState.START_BLANKS


func _use(player: Player) -> void:
	dry = true
	player.health.heal(player.health.max_health)
	RunState.set_blanks(maxi(RunState.blanks, RunState.START_BLANKS))
	_visual.dry = true
	AudioManager.play_sfx(&"well")
	var sparkle := Fx.spawn(get_tree(), SPARKLE_SCENE, global_position + Vector2(0, -4)) as CPUParticles2D
	sparkle.color = GLOW_COLOR
	var glow := Fx.spawn(get_tree(), LIGHT_FLASH_SCENE, global_position) as LightFlash
	glow.color = GLOW_COLOR
	used.emit()
