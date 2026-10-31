class_name RoomSlot
extends RefCounted
## Una sala del layout de un piso: dónde está, de qué tipo es y qué plantilla usa.

enum Kind { NORMAL, START, BOSS, TREASURE, SHOP, SECRET }

var cell: Vector2i
var kind: Kind = Kind.NORMAL
## Pasos desde la sala inicial (la secreta cuenta desde su vecina más cercana).
var distance: int = 0
## La asigna TemplatePicker después de generar el layout.
var template: RoomTemplate


func _init(slot_cell: Vector2i = Vector2i.ZERO, slot_kind: Kind = Kind.NORMAL) -> void:
	cell = slot_cell
	kind = slot_kind
