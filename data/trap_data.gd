class_name TrapData
extends Resource
## Trampa de un piso (FloorTheme.trap): las plantillas marcan dónde va con "^" y cada piso pone la suya,
## así una misma sala tiene pinchos en el Sótano y chorros de fuego en la Forja. Lastima al jugador y
## a los enemigos (no a los que están bajo tierra o en fantasma), una vez por cada vez que se activa.
## TIMED: se arma sola en ciclos (quieta → aviso → activa). PROXIMITY: cuando alguien se acerca avisa
## y se activa; después tarda `rest_time` en volver a armarse.

enum Trigger { TIMED, PROXIMITY }
## Cómo se dibuja. NOZZLE además es un chorro en línea (largo `length`); las otras, un círculo.
enum Look { SPIKES, VENT, POD, NOZZLE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var look: Look = Look.SPIKES
@export var trigger: Trigger = Trigger.TIMED

@export_group("Tiempos")
## Quieta entre activaciones (en PROXIMITY, lo que tarda en volver a armarse).
@export var rest_time: float = 1.6
@export var warn_time: float = 0.5
@export var active_time: float = 0.5
## PROXIMITY: a qué distancia se dispara.
@export var trigger_radius: float = 18.0

@export_group("Daño")
## Radio del daño (en NOZZLE, medio ancho del chorro).
@export var radius: float = 7.0
## NOZZLE: largo del chorro en píxeles.
@export var length: float = 0.0
## Medios corazones al jugador.
@export var player_damage: float = 1.0
@export var enemy_damage: float = 8.0
@export var knockback: float = 90.0
## Si además les aplica un estado a los enemigos (siempre, con el daño de la trampa).
@export var applies_status: bool = false
@export var status: StatusComponent.Kind = StatusComponent.Kind.BURN

@export_group("Aspecto")
## Color de lo que lastima (púas, gas, esporas, llama).
@export var color: Color = Color("c8c2d4")
## Sonido al activarse.
@export var sfx_id: StringName = &""


## Largo de un ciclo completo de una TIMED.
func cycle_time() -> float:
	return rest_time + warn_time + active_time
