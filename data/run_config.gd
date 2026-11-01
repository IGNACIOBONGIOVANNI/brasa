class_name RunConfig
extends Resource
## Cómo es una run: los pisos en orden y las reglas de sala que pueden tocar. Ganar el jefe del
## último piso termina la run.

@export var floors: Array[FloorTheme] = []
## Reglas que puede sortear cualquier piso (RulePicker).
@export var room_rules: Array[RoomRule] = []
## Armazones que pueden aparecer en los Galpones.
@export var mechs: Array[MechData] = []
