class_name PickupData
extends Resource
## Un tipo de pickup: qué da al agarrarlo, cómo aparece en las plantillas y cuánto sale de premio.

enum Kind { COIN, HEART, BOMB, KEY }

@export var id: StringName = &""
@export var kind: Kind = Kind.COIN
## Cuánto da: monedas, bombas o llaves, o medios corazones que cura.
@export var amount: int = 1
## Símbolo en las plantillas de sala ("$", "+", "%", "&").
@export var template_symbol: String = "$"
## Peso en el sorteo de la recompensa por limpiar una sala (0 = nunca sale de premio).
@export var reward_weight: float = 1.0
@export var sfx_id: StringName = &"pickup"
