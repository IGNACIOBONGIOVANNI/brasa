class_name Rock
extends StaticBody2D
## Roca de una sala: bloquea el paso y las balas, y se rompe con una explosión.

const GROUP: StringName = &"rocks"
## Mitad del lado (una roca ocupa un tile de 16 px).
const HALF_SIZE: float = 8.0
const DEBRIS_SCENE: PackedScene = preload("res://fx/burst.tscn")


func _ready() -> void:
	add_to_group(GROUP)


## Se puede llamar antes de agregarla al árbol.
func set_colors(fill: Color, outline: Color) -> void:
	var visual := $Visual as PlaceholderShape
	visual.color = fill
	visual.outline_color = outline


## Cómo se ve según el piso (cajón, tonel, fardo...) y una variante para que no sean todas iguales.
func set_scenery(scenery: FloorTheme.Scenery, variant: int) -> void:
	var visual := $Visual as SceneryShape
	visual.scenery = scenery
	visual.variant = variant


func destroy() -> void:
	if is_queued_for_deletion():
		return
	var debris := Fx.spawn(get_tree(), DEBRIS_SCENE, global_position) as CPUParticles2D
	debris.color = ($Visual as PlaceholderShape).color
	debris.amount = 10
	AudioManager.play_sfx(&"rock_break", 0.1)
	queue_free()
