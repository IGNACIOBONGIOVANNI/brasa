class_name RunConfig
extends Resource
## Un capítulo: cómo es una run (los pisos en orden y las reglas de sala que pueden tocar), su nombre
## y su historia. Ganar el jefe del último piso termina la run. Cada personaje es de un capítulo
## (CharacterData.chapter) y MetaConfig.chapters los tiene en orden.

## Número del capítulo (1, 2...): el de CharacterData.chapter.
@export var number: int = 1
@export var id: StringName = &""
@export var display_name: String = ""
## Una línea; se muestra al elegir el capítulo.
@export var description: String = ""
## Lo que se cuenta la primera vez que se juega (vacío = la intro de siempre, IntroScreen.LINES).
@export var intro: PackedStringArray = []
## Debajo del título del resumen, al ganar y al perder.
@export var victory_text: String = ""
@export var defeat_text: String = ""

@export var floors: Array[FloorTheme] = []
## Reglas que puede sortear cualquier piso (RulePicker).
@export var room_rules: Array[RoomRule] = []
## Armazones que pueden aparecer en los Galpones.
@export var mechs: Array[MechData] = []
@export_group("Camino secreto")
## El piso secreto del capítulo (null = no tiene). Se llega encendiendo el brasero frío de un piso
## (con una bomba: da el Ascua) y abriendo con el Ascua la boca tapiada de la sala del jefe de otro;
## su trampilla lleva al piso que sigue a ese.
@export var secret_floor: FloorTheme
## El piso (índice en `floors`) donde está el brasero frío.
@export var secret_brazier_floor: int = 0
## El piso en cuya sala del jefe está la boca que baja al secreto.
@export var secret_gate_floor: int = 1
