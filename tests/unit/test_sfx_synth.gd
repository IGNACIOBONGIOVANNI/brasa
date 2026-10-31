extends GutTest
## SfxSynth: los sonidos placeholder salen con el largo pedido, sin saturar y siempre iguales.


func _sfx(wave: SfxData.Wave) -> SfxData:
	var sfx := SfxData.new()
	sfx.id = &"test"
	sfx.wave = wave
	sfx.freq_start = 800.0
	sfx.freq_end = 200.0
	sfx.duration = 0.1
	sfx.volume = 0.5
	return sfx


func test_length_matches_duration() -> void:
	var samples: PackedFloat32Array = SfxSynth.render_samples(_sfx(SfxData.Wave.SQUARE))
	assert_eq(samples.size(), roundi(0.1 * SfxSynth.MIX_RATE))


func test_every_wave_stays_within_volume_and_ends_silent() -> void:
	for wave: int in SfxData.Wave.size():
		var samples: PackedFloat32Array = SfxSynth.render_samples(_sfx(wave as SfxData.Wave))
		var peak: float = 0.0
		for sample: float in samples:
			assert_false(is_nan(sample), "sin NaN")
			peak = maxf(peak, absf(sample))
		assert_lte(peak, 0.5 + 0.0001, "onda %d no pasa el volumen" % wave)
		assert_gt(peak, 0.05, "onda %d se escucha" % wave)
		assert_almost_eq(samples[samples.size() - 1], 0.0, 0.01, "onda %d termina en silencio" % wave)


func test_noise_is_deterministic() -> void:
	var first: PackedFloat32Array = SfxSynth.render_samples(_sfx(SfxData.Wave.NOISE))
	var second: PackedFloat32Array = SfxSynth.render_samples(_sfx(SfxData.Wave.NOISE))
	assert_eq(first, second)


func test_render_builds_16_bit_mono_wav() -> void:
	var stream: AudioStreamWAV = SfxSynth.render(_sfx(SfxData.Wave.TRIANGLE))
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_false(stream.stereo)
	assert_eq(stream.mix_rate, SfxSynth.MIX_RATE)
	assert_eq(stream.data.size(), roundi(0.1 * SfxSynth.MIX_RATE) * 2)
