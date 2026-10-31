class_name SaveStore
extends RefCounted
## Guarda un diccionario como JSON en un archivo sin dejarlo nunca a medio escribir: escribe un
## temporal y lo renombra encima. Al leer migra las versiones viejas (SaveSchema). Si el archivo está
## roto lo aparta (".corrupt") y arranca de cero; si es de una versión más nueva que el juego no lo
## toca. Si un corte dejó solo el temporal (ya completo), lo usa.

enum Status {
	## Se leyó el guardado.
	OK,
	## No había guardado.
	MISSING,
	## El guardado no estaba pero sí el temporal completo de la última escritura.
	RECOVERED,
	## El guardado estaba roto: quedó aparte y se arranca de cero.
	CORRUPT,
	## Es de una versión más nueva del juego: no se puede leer ni hay que pisarlo.
	TOO_NEW,
}

const TEMP_SUFFIX: String = ".tmp"
const CORRUPT_SUFFIX: String = ".corrupt"

var path: String
## Cómo salió la última lectura.
var status: Status = Status.MISSING
## Migraciones a aplicar al leer (los tests ponen otras).
var steps: Array[Callable] = SaveSchema.migrations()


func _init(save_path: String) -> void:
	path = save_path


## Lee el guardado ya migrado a la última versión, o un diccionario vacío si no hay nada que leer
## (ver `status`).
func read() -> Dictionary:
	var broken: bool = false
	if FileAccess.file_exists(path):
		var data: Dictionary = _read_json(path)
		if SaveSchema.version_of(data) > SaveSchema.latest(steps):
			status = Status.TOO_NEW
			return {}
		if SaveSchema.can_upgrade(data, steps):
			status = Status.OK
			return SaveSchema.upgrade(data, steps)
		broken = true
	var temp: String = path + TEMP_SUFFIX
	if FileAccess.file_exists(temp):
		var data: Dictionary = _read_json(temp)
		if SaveSchema.can_upgrade(data, steps):
			if broken:
				_set_aside()
			status = Status.RECOVERED
			return SaveSchema.upgrade(data, steps)
	if broken:
		_set_aside()
		status = Status.CORRUPT
	else:
		status = Status.MISSING
	return {}


## Escribe `data` como JSON: primero en el temporal y después lo renombra encima del guardado, así
## un corte deja el archivo anterior o el nuevo, nunca uno a medias.
func write(data: Dictionary) -> Error:
	var error: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return error
	var temp: String = path + TEMP_SUFFIX
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var written: bool = file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if not written:
		return ERR_FILE_CANT_WRITE
	return DirAccess.rename_absolute(temp, path)


## Borra el guardado y lo que haya quedado al lado (temporal, apartado).
func delete() -> void:
	for file: String in [path, path + TEMP_SUFFIX, path + CORRUPT_SUFFIX]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


## Contenido de un archivo JSON si es un objeto; si no (o no se puede leer), vacío.
static func _read_json(file_path: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return {}
	var data: Variant = json.data
	if data is Dictionary:
		return data
	return {}


func _set_aside() -> void:
	DirAccess.rename_absolute(path, path + CORRUPT_SUFFIX)
