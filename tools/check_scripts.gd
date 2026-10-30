extends SceneTree
## Compila todos los .gd del proyecto (salvo addons/) y sale con código 1 si alguno falla.
## Los warnings están promovidos a error en project.godot, así que esto también los detecta.
## Uso: <godot_console> --headless --path . -s res://tools/check_scripts.gd

const SKIP_DIRS: Array[String] = ["res://addons", "res://.godot"]


func _initialize() -> void:
	var paths: PackedStringArray = []
	_collect("res://", paths)
	var failed: PackedStringArray = []
	var self_path: String = (get_script() as Script).resource_path
	for path: String in paths:
		if path == self_path:
			continue
		# load() devuelve el recurso aunque no compile: un script roto no se puede instanciar.
		var script: GDScript = load(path) as GDScript
		if script == null or (not script.can_instantiate() and not script.is_abstract()):
			failed.append(path)
	if failed.is_empty():
		print("check_scripts: OK (%d scripts)" % paths.size())
		quit(0)
	else:
		printerr("check_scripts: FALLARON %d de %d scripts:" % [failed.size(), paths.size()])
		for path: String in failed:
			printerr("  - " + path)
		quit(1)


func _collect(dir_path: String, out: PackedStringArray) -> void:
	for skip: String in SKIP_DIRS:
		if dir_path.begins_with(skip):
			return
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for file: String in dir.get_files():
		if file.get_extension() == "gd":
			out.append(dir_path.path_join(file))
