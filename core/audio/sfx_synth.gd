class_name SfxSynth
extends RefCounted
## Sintetizador mínimo para los sonidos placeholder (estilo sfxr): una onda con barrido de tono
## exponencial y una envolvente de volumen. Devuelve un AudioStreamWAV de 16 bits mono.

const MIX_RATE: int = 22050
## Fundido final para que el sonido no termine con un clic.
const END_FADE: float = 0.004
## El ruido cambia de valor varias veces por ciclo, así su "tono" sigue a la frecuencia.
const NOISE_STEPS_PER_CYCLE: int = 8
const MIN_FREQ: float = 1.0


static func render(sfx: SfxData) -> AudioStreamWAV:
	var samples: PackedFloat32Array = render_samples(sfx)
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		data.encode_s16(i * 2, clampi(roundi(samples[i] * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


## Muestras en [-1, 1]. Siempre da lo mismo para el mismo SfxData.
static func render_samples(sfx: SfxData) -> PackedFloat32Array:
	var count: int = maxi(1, roundi(sfx.duration * MIX_RATE))
	var samples := PackedFloat32Array()
	samples.resize(count)
	# RNG local con seed fija: no es aleatoriedad de juego, solo le da forma al ruido.
	var noise := RandomNumberGenerator.new()
	noise.seed = hash(String(sfx.id))
	var noise_value: float = noise.randf_range(-1.0, 1.0)
	var noise_step: int = 0
	var phase: float = 0.0
	var freq_start: float = maxf(MIN_FREQ, sfx.freq_start)
	var freq_ratio: float = maxf(MIN_FREQ, sfx.freq_end) / freq_start
	for i: int in count:
		var progress: float = float(i) / count
		phase += freq_start * pow(freq_ratio, progress) / MIX_RATE
		phase -= floorf(phase)
		var step: int = floori(phase * NOISE_STEPS_PER_CYCLE)
		if step != noise_step:
			noise_step = step
			noise_value = noise.randf_range(-1.0, 1.0)
		samples[i] = _wave(sfx, phase, noise_value) * _envelope(sfx, i, count, progress) * sfx.volume
	return samples


static func _wave(sfx: SfxData, phase: float, noise_value: float) -> float:
	match sfx.wave:
		SfxData.Wave.SQUARE:
			return 1.0 if phase < sfx.square_duty else -1.0
		SfxData.Wave.TRIANGLE:
			return 1.0 - 4.0 * absf(phase - 0.5)
		SfxData.Wave.SINE:
			return sin(TAU * phase)
		SfxData.Wave.SAW:
			return 2.0 * phase - 1.0
	return noise_value


static func _envelope(sfx: SfxData, index: int, count: int, progress: float) -> float:
	var level: float = pow(1.0 - progress, maxf(0.0, sfx.decay_power))
	var time: float = float(index) / MIX_RATE
	if sfx.attack > 0.0 and time < sfx.attack:
		level *= time / sfx.attack
	var time_left: float = float(count - index) / MIX_RATE
	if time_left < END_FADE:
		level *= time_left / END_FADE
	return level
