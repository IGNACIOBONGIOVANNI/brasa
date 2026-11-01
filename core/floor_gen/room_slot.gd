class_name RoomSlot
extends RefCounted
## Una sala del layout de un piso: dónde está, de qué tipo es, qué plantilla usa y su regla.

## Las especiales nuevas van al final para no cambiar los números guardados en las plantillas.
## CHALLENGE (Prueba): pelea opcional con regla y un item de premio. ALTAR: dos items que se pagan
## con vida (se lleva uno). WELL (Pozo): cura y devuelve los Pulsos una vez.
enum Kind { NORMAL, START, BOSS, TREASURE, SHOP, SECRET, CHALLENGE, ALTAR, WELL }

var cell: Vector2i
var kind: Kind = Kind.NORMAL
## Pasos desde la sala inicial (la secreta cuenta desde su vecina más cercana).
var distance: int = 0
## La asigna TemplatePicker después de generar el layout.
var template: RoomTemplate
## Regla de la sala (null = ninguna). La asigna RulePicker.
var rule: RoomRule
## Items de los pedestales (tesoro, tienda, secreta, jefe, prueba y altar), sorteados al generar el piso.
var offers: Array[ItemData] = []


func _init(slot_cell: Vector2i = Vector2i.ZERO, slot_kind: Kind = Kind.NORMAL) -> void:
	cell = slot_cell
	kind = slot_kind
