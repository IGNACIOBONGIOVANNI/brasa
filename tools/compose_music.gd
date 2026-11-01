extends SceneTree
## Genera la banda sonora: renderiza cada tema de tools/music/soundtrack.gd (ChipTune) a
## content/music/<id>.wav, con la marca de repetición para que Godot lo importe en loop.
## Uso: "$G" --headless --path . -s res://tools/compose_music.gd [-- id ...]
## Sin ids genera todos. Después correr --import. Si algún tema tiene errores no escribe nada.

const SOUNDTRACK_PATH: String = "res://tools/music/soundtrack.gd"
const OUTPUT_DIR: String = "res://content/music/"


func _init() -> void:
	var soundtrack: GDScript = load(SOUNDTRACK_PATH)
	var songs: Dictionary = soundtrack.call(&"songs")
	var wanted: PackedStringArray = OS.get_cmdline_user_args()
	var failed: bool = false
	for id: StringName in songs:
		var errors: PackedStringArray = ChipTune.check(songs[id])
		for error: String in errors:
			printerr("%s: %s" % [id, error])
		failed = failed or not errors.is_empty()
	if failed:
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for id: StringName in songs:
		if not wanted.is_empty() and not String(id) in wanted:
			continue
		var song: ChipTune.Song = songs[id]
		var started: int = Time.get_ticks_msec()
		var samples: PackedFloat32Array = ChipTune.render_samples(song)
		var file := FileAccess.open(OUTPUT_DIR + String(id) + ".wav", FileAccess.WRITE)
		file.store_buffer(ChipTune.wav_bytes(samples))
		file.close()
		print("%s: %d compases, %.1f s de música (%.1f s para generarla)" % [id, ChipTune.bars(song),
				samples.size() / float(ChipTune.MIX_RATE), (Time.get_ticks_msec() - started) / 1000.0])
	quit(0)
