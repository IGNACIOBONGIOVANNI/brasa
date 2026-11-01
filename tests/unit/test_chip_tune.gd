extends GutTest
## ChipTune: la notación de los temas (duraciones, octavas, ligaduras, repeticiones, arpegios, barras
## de compás, batería), el audio que sale y que cada tema de la banda sonora esté bien escrito y
## generado (si se cambia una partitura sin volver a correr tools/compose_music.gd, falla).

const SOUNDTRACK_PATH: String = "res://tools/music/soundtrack.gd"
const MUSIC_DIR: String = "res://content/music/"


func _songs() -> Dictionary:
	return (load(SOUNDTRACK_PATH) as GDScript).call(&"songs")


func _pitches(part: ChipTune.Part) -> Array[float]:
	var pitches: Array[float] = []
	for note: ChipTune.Note in part.notes:
		pitches.append(note.pitches[0])
	return pitches


func test_lengths_dots_and_default_length() -> void:
	var part: ChipTune.Part = ChipTune.parse("c4 d8 e8. l16 f g")
	assert_eq(part.error, "")
	var ticks: Array[int] = []
	for note: ChipTune.Note in part.notes:
		ticks.append(note.ticks)
	assert_eq(ticks, [48, 24, 36, 12, 12] as Array[int])
	assert_eq(part.ticks, 132)


func test_octaves_and_accidentals() -> void:
	assert_eq(_pitches(ChipTune.parse("c d e f g a b")), [60.0, 62.0, 64.0, 65.0, 67.0, 69.0, 71.0] as Array[float], "la octava 4 tiene el do central")
	assert_eq(_pitches(ChipTune.parse("o5 a >a << a")), [81.0, 93.0, 69.0] as Array[float])
	assert_eq(_pitches(ChipTune.parse("c+ c# d- b-")), [61.0, 61.0, 61.0, 70.0] as Array[float])


func test_rests_ties_and_gate() -> void:
	var part: ChipTune.Part = ChipTune.parse("r2 q4 c4^8")
	assert_eq(part.notes.size(), 1, "la liga no es otra nota")
	assert_eq(part.notes[0].start, 96, "después del silencio")
	assert_eq(part.notes[0].ticks, 72)
	assert_eq(part.notes[0].gate, 36, "suena la mitad (q4)")


func test_repeats_nest() -> void:
	var part: ChipTune.Part = ChipTune.parse("[[c16]2 d8]2")
	assert_eq(part.error, "")
	assert_eq(_pitches(part), [60.0, 60.0, 62.0, 60.0, 60.0, 62.0] as Array[float])
	assert_eq(part.ticks, 96)


func test_arpeggio_has_all_its_notes_and_keeps_the_octave() -> void:
	var part: ChipTune.Part = ChipTune.parse("{ce-g>c}4 c")
	assert_eq(part.notes.size(), 2)
	assert_eq(part.notes[0].pitches, PackedFloat32Array([60.0, 63.0, 67.0, 72.0]))
	assert_eq(part.notes[1].pitches[0], 60.0, "la octava de adentro no queda")


func test_bar_lines_catch_a_wrong_count() -> void:
	assert_eq(ChipTune.parse("c1 | c2 c2 |").error, "")
	assert_ne(ChipTune.parse("c2 c4 | c1").error, "", "un compás corto")


func test_errors_are_reported() -> void:
	for bad: String in ["c4 x", "[c4", "c4]", "{ceg", "c5"]:
		assert_ne(ChipTune.parse(bad).error, "", "'%s' es un error" % bad)
	assert_ne(ChipTune.parse("k8 d8", true).error, "", "en la batería no hay notas")


func test_drums() -> void:
	var part: ChipTune.Part = ChipTune.parse("v9 k8 s8 r4 [h16]2 o8 c4 t8 m8 a4", true)
	assert_eq(part.error, "")
	var hits: PackedStringArray = []
	for note: ChipTune.Note in part.notes:
		hits.append(note.drum)
	assert_eq("".join(hits), "kshhoctma")
	assert_eq(part.notes[0].volume, 9)
	assert_eq(part.ticks, ChipTune.BAR_TICKS + 96)


func test_check_finds_channels_out_of_step() -> void:
	var song := ChipTune.Song.new(120.0)
	song.pulse("c1 | c1 |")
	song.triangle("c1 |")
	assert_eq(ChipTune.check(song).size(), 1, "un canal dura menos")
	assert_false(ChipTune.check(ChipTune.Song.new(120.0)).is_empty(), "una canción vacía no vale")


## Un compás de cada voz.
func _short_song() -> ChipTune.Song:
	var song := ChipTune.Song.new(140.0)
	song.pulse("o5 ~2 e8 g8 {ceg}4 a4 r4 |").echo(36, 0.3, 0.3)
	song.pulse("@0 s1 [c16 e16]8 |", 0.8, 0)
	song.triangle("o2 c4 g4 c4 g4 |")
	song.noise("k8 h8 s8 h8 k8 o8 c4 |")
	song.noise("a4 t4 m4 r4 |")
	return song


func test_render_is_steady_loud_enough_and_never_clips() -> void:
	var song: ChipTune.Song = _short_song()
	assert_eq(ChipTune.check(song).size(), 0)
	var samples: PackedFloat32Array = ChipTune.render_samples(song)
	assert_eq(samples.size(), ChipTune.loop_samples(song), "una vuelta exacta")
	assert_eq(samples.size(), roundi(60.0 / 140.0 * 4.0 * ChipTune.MIX_RATE), "un compás a 140")
	var power: float = 0.0
	var peak: float = 0.0
	for sample: float in samples:
		power += sample * sample
		peak = maxf(peak, absf(sample))
	assert_false(is_nan(power), "sin NaN")
	assert_lt(peak, 1.0, "no satura")
	assert_almost_eq(sqrt(power / samples.size()), ChipTune.TARGET_RMS, 0.01, "volumen parejo")
	assert_eq(ChipTune.render_samples(song), samples, "siempre da lo mismo")


func test_rendered_stream_and_wav_file_loop() -> void:
	var song: ChipTune.Song = _short_song()
	var stream: AudioStreamWAV = ChipTune.render(song)
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(stream.loop_end, ChipTune.loop_samples(song))
	var bytes: PackedByteArray = ChipTune.wav_bytes(ChipTune.render_samples(song))
	assert_eq(bytes.slice(0, 4).get_string_from_ascii(), "RIFF")
	assert_eq(bytes.slice(8, 12).get_string_from_ascii(), "WAVE")
	assert_eq(bytes.decode_u32(4), bytes.size() - 8, "largo del RIFF")
	assert_eq(bytes.slice(36, 40).get_string_from_ascii(), "smpl", "marca de repetición")
	assert_eq(bytes.decode_u32(36 + 8 + 36 + 12), ChipTune.loop_samples(song), "la vuelta termina al final")


func test_every_song_is_well_written() -> void:
	var songs: Dictionary = _songs()
	assert_gte(songs.size(), 6, "menú, cuatro pisos y jefe")
	for id: StringName in songs:
		var song: ChipTune.Song = songs[id]
		assert_eq(ChipTune.check(song), PackedStringArray(), "%s: bien escrito" % id)
		assert_gte(ChipTune.bars(song), 16, "%s: por lo menos 16 compases" % id)


func test_every_song_is_rendered_and_loops() -> void:
	var songs: Dictionary = _songs()
	for id: StringName in songs:
		var path: String = MUSIC_DIR + String(id) + ".wav"
		assert_true(ResourceLoader.exists(path), "%s: falta generarlo (tools/compose_music.gd)" % path)
		var stream := load(path) as AudioStreamWAV
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s: da la vuelta" % id)
		var seconds: float = ChipTune.loop_samples(songs[id]) / float(ChipTune.MIX_RATE)
		assert_almost_eq(stream.get_length(), seconds, 0.01, "%s: generado con la partitura actual" % id)
