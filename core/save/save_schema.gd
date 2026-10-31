class_name SaveSchema
extends RefCounted
## Versión del archivo de guardado y sus migraciones. Cada migración pasa el diccionario de la
## versión N a la N + 1; `upgrade` las encadena hasta la última. Un guardado sin versión válida no
## se puede leer, y uno de una versión más nueva que la del juego tampoco.

## Versión que escribe este build. Al cambiar el formato: subirla y agregar la migración en
## `migrations()` (tiene que haber exactamente VERSION - 1).
const VERSION: int = 1


## Migraciones del juego, en orden: la i-ésima pasa de la versión i + 1 a la i + 2. Cada una recibe
## el diccionario y devuelve el nuevo (no hace falta que toque "version").
static func migrations() -> Array[Callable]:
	return []


## Versión de un guardado leído; 0 si no tiene una válida.
static func version_of(data: Dictionary) -> int:
	var value: Variant = data.get("version")
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return 0
	return maxi(0, int(value))


## Última versión que se alcanza con `steps`.
static func latest(steps: Array[Callable]) -> int:
	return steps.size() + 1


## true si `data` tiene una versión que `steps` sabe llevar a la última.
static func can_upgrade(data: Dictionary, steps: Array[Callable]) -> bool:
	var version: int = version_of(data)
	return version >= 1 and version <= latest(steps)


## Aplica en orden las migraciones que le falten a `data` (que tiene que pasar `can_upgrade`).
## No modifica el original.
static func upgrade(data: Dictionary, steps: Array[Callable]) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var version: int = version_of(result)
	while version < latest(steps):
		result = steps[version - 1].call(result)
		version += 1
		result["version"] = version
	return result
