class_name RoomTemplate
extends Resource
## Plantilla de sala: el interior escrito como texto, 9 filas de 15 caracteres. La leyenda y las
## reglas están en RoomTemplateParser; los tests de contenido validan todas las plantillas.

@export var id: StringName = &""
@export var kind: RoomSlot.Kind = RoomSlot.Kind.NORMAL
## Solo salas normales: 1 cerca del inicio, 3 cerca de lo más lejano.
@export_range(1, 3) var difficulty: int = 1
@export_multiline var layout: String = ""
