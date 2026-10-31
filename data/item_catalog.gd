class_name ItemCatalog
extends Resource
## Todos los items que pueden salir en una run (los bloqueados recién cuando se desbloquean), más el
## de relleno (sale cuando un pool se vacía y es el único que se puede repetir).

@export var items: Array[ItemData] = []
@export var filler: ItemData


## Los que se compran en el Taller, en el orden del catálogo.
func workshop_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item: ItemData in items:
		if item.locked and item.unlock_cost > 0:
			result.append(item)
	return result
