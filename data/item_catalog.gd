class_name ItemCatalog
extends Resource
## Todos los items que pueden salir en una run, más el de relleno (sale cuando un pool se vacía y es
## el único que se puede repetir).

@export var items: Array[ItemData] = []
@export var filler: ItemData
