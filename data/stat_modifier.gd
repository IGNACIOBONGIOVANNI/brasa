class_name StatModifier
extends Resource
## Un cambio de stat que da un item: suma (ADD) o multiplica (MULT). StatCalculator suma todos los
## ADD y después multiplica todos los MULT, así no importa en qué orden se agarraron los items.

enum Op { ADD, MULT }

## Uno de StatBlock.STAT_NAMES.
@export var stat: StringName = &"damage"
@export var op: Op = Op.ADD
@export var value: float = 0.0
