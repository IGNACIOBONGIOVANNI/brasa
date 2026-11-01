class_name RoomRule
extends Resource
## Regla de una sala: cambia cómo se pelea ahí mientras dura el combate y da premio extra al
## limpiarla. La sortea RulePicker en algunas salas normales (FloorTheme.rule_chance) y siempre en
## la Prueba. Se anuncia con un cartel al cerrarse las puertas y queda escrita arriba en el HUD.

@export var id: StringName = &""
@export var display_name: String = ""
## Lo que dice el cartel debajo del nombre.
@export var description: String = ""
@export var color: Color = Color("f2c14e")

@export_group("Enemigos")
## Multiplica la vida de los enemigos de la sala (además del multiplicador del piso).
@export var enemy_health_mult: float = 1.0
## Multiplica la velocidad de los enemigos: moverse, avisar y atacar.
@export var enemy_pace: float = 1.0

@export_group("Jugador")
## Multiplica el daño que recibe el jugador.
@export var damage_taken_mult: float = 1.0
## El Pulso no funciona.
@export var no_pulse: bool = false
## Cuánto más oscura queda la sala (0 = igual, 1 = negra).
@export_range(0.0, 1.0) var darkness: float = 0.0

@export_group("Premio")
## Pickups seguros que suelta además del premio común al limpiarla.
@export var bonus_rewards: int = 1
## Segundos para limpiarla y ganarse el premio extra (0 = sin límite).
@export var time_limit: float = 0.0


## Si limpiar la sala en `seconds` gana el premio extra.
func earns_bonus(seconds: float) -> bool:
	return time_limit <= 0.0 or seconds <= time_limit
