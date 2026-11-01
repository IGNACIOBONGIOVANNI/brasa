class_name ChipTune
extends RefCounted
## Música chiptune escrita como texto (estilo MML, un texto por canal) y su sintetizador: pulsos con
## cuatro anchos, triángulo de 16 escalones y batería de ruido, como las consolas de 8 bits. La usa
## tools/compose_music.gd para generar los temas de content/music/ (el juego solo carga los .wav).
## El audio que sale da la vuelta sin cortes: lo que suena después del final (ecos, notas largas) se
## suma al principio.
##
## Canal melódico (pulso o triángulo):
##   c d e f g a b   nota; + o # sube medio tono, - lo baja; duración opcional 1 2 4 8 16 32 (y
##                   puntos: 8. = corchea con puntillo). Sin número usa la de `l`.
##   r               silencio (con duración, como una nota)
##   ^               liga: alarga la nota anterior (c4^16)
##   {ceg}           acorde arpegiado (alterna sus notas muy rápido); adentro valen < y >
##   o4  > <         octava (la 4 tiene el La de 440 Hz), una arriba, una abajo
##   l8              duración por defecto
##   v12             volumen 0-15
##   @1              ancho del pulso: 0 = 12,5 %, 1 = 25 %, 2 = 50 %, 3 = 75 %
##   q6              cuánto suena cada nota, en octavos de su duración (q8 = ligado)
##   s3              caída: el volumen baja 1 (de 15) cada 3 cuadros de 1/60 s (s0 = sin caída)
##   ~2              vibrato, en décimas de semitono (~0 lo apaga)
##   [ ... ]3        repetir 3 veces
##   |               barra de compás: si no cae justo en un compás es un error (así los canales
##                   no se desfasan sin que se note)
## Canal de batería (ruido): k bombo, s caja, h hi-hat, o hi-hat abierto, c platillo, t tom grave,
## m tom medio, a yunque; r, l, v, [ ] y | igual que arriba.

enum Voice { PULSE, TRIANGLE, NOISE }

const MIX_RATE: int = 22050
## Una redonda; la negra son 48 y la semicorchea 12.
const WHOLE_TICKS: int = 192
const BAR_TICKS: int = WHOLE_TICKS
const QUARTER_TICKS: int = 48
const DUTIES: Array[float] = [0.125, 0.25, 0.5, 0.75]
const DRUMS: String = "kshoctma"
## Cuadros por segundo para la envolvente, el vibrato y los arpegios (como un chip de consola).
const FRAME_RATE: float = 60.0
const ARP_RATE: float = 50.0
const VIBRATO_RATE: float = 5.5
const VIBRATO_DELAY: float = 0.15
## Suaviza los cambios de volumen (sin esto cada nota hace clic).
const SMOOTHING: float = 0.04
const RELEASE_SAMPLES: int = 240
const ATTACK_SAMPLES: int = 16
## Lo que puede sonar después del final (ecos, platillos): se suma al principio del tema.
const TAIL_SECONDS: float = 3.0
## Volumen parejo entre temas: todos al mismo nivel promedio (RMS); los picos que pasan de LIMIT
## se redondean (limitador suave) y nunca llegan a 1.
const TARGET_RMS: float = 0.2
const LIMIT: float = 0.8
const LOWPASS_HZ: float = 9000.0
const DC_BLOCK_HZ: float = 20.0
const DEFAULT_VOLUME: int = 12
const DEFAULT_GATE: int = 7


class Channel:
	var voice: Voice = Voice.PULSE
	var mml: String
	## Nivel del canal en la mezcla.
	var gain: float = 1.0
	## Ancho del pulso al empezar (índice de DUTIES).
	var duty: int = 2
	var echo_ticks: int = 0
	var echo_feedback: float = 0.0
	var echo_mix: float = 0.0

	func _init(p_voice: Voice, p_mml: String, p_gain: float) -> void:
		voice = p_voice
		mml = p_mml
		gain = p_gain

	## Eco: se repite `ticks` después, cada vez `feedback` más bajo, mezclado a `mix`.
	func echo(ticks: int, feedback: float, mix: float) -> Channel:
		echo_ticks = ticks
		echo_feedback = feedback
		echo_mix = mix
		return self


class Song:
	var bpm: float
	var channels: Array[Channel] = []

	func _init(p_bpm: float) -> void:
		bpm = p_bpm

	func pulse(mml: String, gain: float = 1.0, duty: int = 2) -> Channel:
		var channel := Channel.new(Voice.PULSE, mml, gain)
		channel.duty = duty
		channels.append(channel)
		return channel

	func triangle(mml: String, gain: float = 1.0) -> Channel:
		var channel := Channel.new(Voice.TRIANGLE, mml, gain)
		channels.append(channel)
		return channel

	func noise(mml: String, gain: float = 1.0) -> Channel:
		var channel := Channel.new(Voice.NOISE, mml, gain)
		channels.append(channel)
		return channel

	func samples_per_tick() -> float:
		return MIX_RATE * 60.0 / bpm / QUARTER_TICKS


class Note:
	var start: int = 0
	var ticks: int = 0
	## Cuánto suena (en ticks); el resto de la duración es silencio.
	var gate: int = 0
	var gate_eighths: int = DEFAULT_GATE
	## Notas MIDI (más de una = arpegio). Vacío en la batería.
	var pitches: PackedFloat32Array = PackedFloat32Array()
	var drum: String = ""
	var volume: int = DEFAULT_VOLUME
	var duty: int = 2
	var decay: int = 0
	var vibrato: int = 0


## Un canal ya leído: sus notas, cuánto dura y el primer error que encontró (vacío si ninguno).
class Part:
	var notes: Array[Note] = []
	var ticks: int = 0
	var error: String = ""


## Lee el texto de un canal. Para la batería, `drums` = true.
static func parse(mml: String, drums: bool = false, start_duty: int = 2) -> Part:
	var part := Part.new()
	var reader := _Reader.new(mml)
	var octave: int = 4
	var length: int = QUARTER_TICKS
	var volume: int = DEFAULT_VOLUME
	var duty: int = start_duty
	var gate: int = DEFAULT_GATE
	var decay: int = 0
	var vibrato: int = 0
	var last: Note = null
	# Cada repetición abierta: [posición de su comienzo, vueltas que faltan (-1 = sin leer)].
	var repeats: Array[PackedInt32Array] = []
	while reader.error.is_empty() and not reader.done():
		var at: int = reader.position
		var c: String = reader.next()
		if c in " \t\r\n":
			continue
		if c == "|":
			if part.ticks % BAR_TICKS != 0:
				reader.fail("la barra del carácter %d no cae en un compás (sobran %d ticks)" % [at, part.ticks % BAR_TICKS])
		elif c == "[":
			repeats.append(PackedInt32Array([reader.position, -1]))
		elif c == "]":
			if repeats.is_empty():
				reader.fail("']' sin '[' en el carácter %d" % at)
				break
			var times: int = reader.number(2)
			var top: PackedInt32Array = repeats[repeats.size() - 1]
			if top[1] == -1:
				top[1] = times - 1
			if top[1] > 0:
				top[1] -= 1
				repeats[repeats.size() - 1] = top
				reader.position = top[0]
			else:
				repeats.pop_back()
		elif c == "l":
			length = reader.length(length)
		elif c == "v":
			volume = clampi(reader.number(volume), 0, 15)
		elif c == "r":
			part.ticks += reader.length(length)
			last = null
		elif drums:
			if DRUMS.contains(c):
				var hit := Note.new()
				hit.start = part.ticks
				hit.drum = c
				hit.volume = volume
				hit.ticks = reader.length(length)
				part.ticks += hit.ticks
				part.notes.append(hit)
			else:
				reader.fail("'%s' no es un golpe de batería (carácter %d)" % [c, at])
		elif c == "o":
			octave = reader.number(octave)
		elif c == ">":
			octave += 1
		elif c == "<":
			octave -= 1
		elif c == "@":
			duty = clampi(reader.number(duty), 0, DUTIES.size() - 1)
		elif c == "q":
			gate = clampi(reader.number(gate), 1, 8)
		elif c == "s":
			decay = maxi(0, reader.number(decay))
		elif c == "~":
			vibrato = maxi(0, reader.number(vibrato))
		elif c == "^":
			var extra: int = reader.length(length)
			part.ticks += extra
			if last != null:
				last.ticks += extra
				last.gate = _gate_ticks(last.ticks, last.gate_eighths)
		elif c == "{" or "abcdefg".contains(c):
			var pitches := PackedFloat32Array()
			if c == "{":
				var inner: int = octave
				while reader.error.is_empty() and not reader.done() and reader.peek() != "}":
					var inside: String = reader.next()
					if inside == ">":
						inner += 1
					elif inside == "<":
						inner -= 1
					elif "abcdefg".contains(inside):
						pitches.append(_midi(inside, inner, reader.accidental()))
					elif not (inside in " \t\r\n"):
						reader.fail("'%s' no va adentro de un arpegio (carácter %d)" % [inside, reader.position - 1])
				if reader.done():
					reader.fail("arpegio sin cerrar (carácter %d)" % at)
					break
				reader.next()
				if pitches.is_empty():
					reader.fail("arpegio vacío (carácter %d)" % at)
					break
			else:
				pitches.append(_midi(c, octave, reader.accidental()))
			var note := Note.new()
			note.start = part.ticks
			note.ticks = reader.length(length)
			note.gate_eighths = gate
			note.gate = _gate_ticks(note.ticks, gate)
			note.pitches = pitches
			note.volume = volume
			note.duty = duty
			note.decay = decay
			note.vibrato = vibrato
			part.ticks += note.ticks
			part.notes.append(note)
			last = note
		else:
			reader.fail("no entiendo '%s' (carácter %d)" % [c, at])
	if reader.error.is_empty() and not repeats.is_empty():
		reader.fail("'[' sin cerrar")
	part.error = reader.error
	return part


## Errores de la canción: de lectura, canales de distinto largo o que no terminan en un compás.
static func check(song: Song) -> PackedStringArray:
	var errors := PackedStringArray()
	var ticks: int = -1
	for index: int in song.channels.size():
		var channel: Channel = song.channels[index]
		var part: Part = parse(channel.mml, channel.voice == Voice.NOISE, channel.duty)
		if not part.error.is_empty():
			errors.append("canal %d: %s" % [index, part.error])
			continue
		if part.ticks % BAR_TICKS != 0:
			errors.append("canal %d: no termina en un compás" % index)
		if ticks == -1:
			ticks = part.ticks
		elif part.ticks != ticks:
			errors.append("canal %d: dura %d compases y el primero %d" % [index, floori(part.ticks / float(BAR_TICKS)), floori(ticks / float(BAR_TICKS))])
	if ticks <= 0 and errors.is_empty():
		errors.append("la canción está vacía")
	return errors


## Compases que dura la canción (lo que dura su primer canal).
static func bars(song: Song) -> int:
	if song.channels.is_empty():
		return 0
	var first: Channel = song.channels[0]
	return floori(parse(first.mml, first.voice == Voice.NOISE, first.duty).ticks / float(BAR_TICKS))


## Muestras de una vuelta del tema.
static func loop_samples(song: Song) -> int:
	return roundi(bars(song) * BAR_TICKS * song.samples_per_tick())


## Una vuelta del tema en [-1, 1], lista para repetirse sin cortes. Siempre da lo mismo.
static func render_samples(song: Song) -> PackedFloat32Array:
	var loop: int = loop_samples(song)
	var total: int = loop + roundi(TAIL_SECONDS * MIX_RATE)
	var mix := PackedFloat32Array()
	mix.resize(total)
	var spt: float = song.samples_per_tick()
	for channel: Channel in song.channels:
		var part: Part = parse(channel.mml, channel.voice == Voice.NOISE, channel.duty)
		var buffer := PackedFloat32Array()
		buffer.resize(total)
		for note: Note in part.notes:
			if channel.voice == Voice.NOISE:
				_render_drum(buffer, roundi(note.start * spt), note.drum, note.volume / 15.0 * channel.gain)
			else:
				_render_tone(buffer, note, channel.voice, spt, channel.gain)
		if channel.echo_ticks > 0 and channel.echo_mix > 0.0:
			_apply_echo(buffer, roundi(channel.echo_ticks * spt), channel.echo_feedback, channel.echo_mix)
		for i: int in total:
			mix[i] += buffer[i]
	# Lo que sonó después del final cae sobre el principio de la vuelta siguiente.
	var samples: PackedFloat32Array = mix.slice(0, loop)
	for i: int in mini(total - loop, loop):
		samples[i] += mix[loop + i]
	_master(samples)
	return samples


static func render(song: Song) -> AudioStreamWAV:
	var samples: PackedFloat32Array = render_samples(song)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = _pcm16(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples.size()
	return stream


## Archivo .wav (16 bits, mono) con la marca de repetición ("smpl") que Godot lee al importar.
static func wav_bytes(samples: PackedFloat32Array) -> PackedByteArray:
	var pcm: PackedByteArray = _pcm16(samples)
	var bytes := PackedByteArray()
	_put_text(bytes, "RIFF")
	_put_u32(bytes, 4 + (8 + 16) + (8 + 60) + (8 + pcm.size()))
	_put_text(bytes, "WAVE")
	_put_text(bytes, "fmt ")
	_put_u32(bytes, 16)
	_put_u16(bytes, 1)
	_put_u16(bytes, 1)
	_put_u32(bytes, MIX_RATE)
	_put_u32(bytes, MIX_RATE * 2)
	_put_u16(bytes, 2)
	_put_u16(bytes, 16)
	_put_text(bytes, "smpl")
	_put_u32(bytes, 60)
	for value: int in [0, 0, roundi(1e9 / MIX_RATE), 60, 0, 0, 0, 1, 0]:
		_put_u32(bytes, value)
	# Una sola vuelta hacia adelante, de la primera muestra a la última.
	for value: int in [0, 0, 0, samples.size(), 0, 0]:
		_put_u32(bytes, value)
	_put_text(bytes, "data")
	_put_u32(bytes, pcm.size())
	bytes.append_array(pcm)
	return bytes


static func _midi(letter: String, octave: int, accidental: int) -> float:
	var semitone: int = [9, 11, 0, 2, 4, 5, 7]["abcdefg".find(letter)]
	return float(12 * (octave + 1) + semitone + accidental)


static func _gate_ticks(ticks: int, eighths: int) -> int:
	return maxi(1, floori(ticks * eighths / 8.0))


static func _frequency(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## Una nota de pulso o triángulo. El tono (arpegio, vibrato) y el volumen (caída) cambian una vez
## por cuadro, como en un chip; el volumen se suaviza muestra a muestra para que no haga clic.
static func _render_tone(buffer: PackedFloat32Array, note: Note, voice: Voice, spt: float, gain: float) -> void:
	var start: int = roundi(note.start * spt)
	var gate_end: int = roundi((note.start + note.gate) * spt)
	var end: int = mini(gate_end + RELEASE_SAMPLES, buffer.size())
	var duty: float = DUTIES[note.duty]
	# Sin componente continua: el pulso angosto no corre el cero de la mezcla.
	var offset: float = 2.0 * duty - 1.0
	var level: float = note.volume / 15.0 * gain
	var frame_samples: float = MIX_RATE / FRAME_RATE
	var amp: float = 0.0
	var phase: float = 0.0
	var inc: float = 0.0
	var target: float = 0.0
	var frame: int = 0
	var next_frame: int = start
	for i: int in range(start, end):
		if i >= next_frame:
			var seconds: float = float(i - start) / MIX_RATE
			var pitch: float = note.pitches[floori(seconds * ARP_RATE) % note.pitches.size()]
			if note.vibrato > 0 and seconds > VIBRATO_DELAY:
				pitch += note.vibrato * 0.1 * sin(TAU * VIBRATO_RATE * (seconds - VIBRATO_DELAY))
			inc = _frequency(pitch) / MIX_RATE
			if i >= gate_end:
				target = 0.0
			elif note.decay > 0:
				target = level * maxf(0.0, note.volume - floorf(float(frame) / note.decay)) / note.volume
			else:
				target = level
			frame += 1
			next_frame = start + roundi(frame * frame_samples)
		amp += (target - amp) * SMOOTHING
		phase += inc
		if phase >= 1.0:
			phase -= 1.0
		var value: float
		if voice == Voice.PULSE:
			value = (1.0 if phase < duty else -1.0) - offset
			# PolyBLEP en los dos saltos del pulso: menos aliasing (suena menos áspero).
			var t: float
			if phase < inc:
				t = phase / inc
				value += t + t - t * t - 1.0
			elif phase > 1.0 - inc:
				t = (phase - 1.0) / inc
				value += t * t + t + t + 1.0
			var fall: float = phase - duty
			if fall < 0.0:
				fall += 1.0
			if fall < inc:
				t = fall / inc
				value -= t + t - t * t - 1.0
			elif fall > 1.0 - inc:
				t = (fall - 1.0) / inc
				value -= t * t + t + t + 1.0
			value *= 0.5
		else:
			# Triángulo de 16 escalones, como el de las consolas viejas.
			value = 4.0 * absf(phase - 0.5) - 1.0
			value = floorf((value + 1.0) * 7.5 + 0.5) / 7.5 - 1.0
		buffer[i] += value * amp


## Un golpe de batería: cada uno suena solo hasta apagarse (la duración escrita no lo corta).
static func _render_drum(buffer: PackedFloat32Array, start: int, drum: String, level: float) -> void:
	match drum:
		"k":
			_thump(buffer, start, level, 160.0, 42.0, 0.12, 0.3)
			_noise(buffer, start, level * 0.35, MIX_RATE, 0.004, 0.01, false)
		"s":
			_noise(buffer, start, level * 0.55, MIX_RATE * 0.5, 0.06, 0.22, false)
			_thump(buffer, start, level * 0.5, 230.0, 160.0, 0.04, 0.1)
		"h":
			_noise(buffer, start, level * 0.5, MIX_RATE, 0.014, 0.06, true)
		"o":
			_noise(buffer, start, level * 0.4, MIX_RATE, 0.09, 0.32, true)
		"c":
			_noise(buffer, start, level * 0.5, MIX_RATE, 0.38, 1.6, true)
		"t":
			_thump(buffer, start, level * 0.85, 150.0, 82.0, 0.15, 0.4)
		"m":
			_thump(buffer, start, level * 0.8, 220.0, 125.0, 0.12, 0.32)
		"a":
			_bell(buffer, start, level * 0.45, 0.13, 0.6)
			_noise(buffer, start, level * 0.3, MIX_RATE, 0.006, 0.02, true)


## Golpe grave: triángulo que cae de tono (bombo y toms).
static func _thump(buffer: PackedFloat32Array, start: int, level: float, from_hz: float, to_hz: float, decay: float, length: float) -> void:
	var end: int = mini(start + roundi(length * MIX_RATE), buffer.size())
	# Arranca en el cruce por cero: sin escalón al empezar.
	var phase: float = 0.25
	for i: int in range(start, end):
		var t: float = float(i - start) / MIX_RATE
		phase += (to_hz + (from_hz - to_hz) * exp(-t / 0.03)) / MIX_RATE
		phase -= floorf(phase)
		var value: float = 4.0 * absf(phase - 0.5) - 1.0
		value = floorf((value + 1.0) * 7.5 + 0.5) / 7.5 - 1.0
		buffer[i] += value * level * exp(-t / decay) * _edges(i, start, end)


## Ruido de registro de desplazamiento (como el de las consolas). `bright` lo pasa por un filtro que
## deja los agudos (platillos).
static func _noise(buffer: PackedFloat32Array, start: int, level: float, clock_hz: float, decay: float, length: float, bright: bool) -> void:
	var end: int = mini(start + roundi(length * MIX_RATE), buffer.size())
	var lfsr: int = 0x4A3B
	var step: float = clock_hz / MIX_RATE
	var clock: float = 0.0
	var value: float = 1.0
	var previous: float = 0.0
	for i: int in range(start, end):
		clock += step
		while clock >= 1.0:
			clock -= 1.0
			var bit: int = (lfsr ^ (lfsr >> 1)) & 1
			lfsr = (lfsr >> 1) | (bit << 14)
			value = 1.0 if lfsr & 1 else -1.0
		var out: float = value
		if bright:
			out = (value - previous) * 0.5
			previous = value
		var t: float = float(i - start) / MIX_RATE
		buffer[i] += out * level * exp(-t / decay) * _edges(i, start, end)


## Golpe metálico (yunque): parciales que no son armónicos entre sí.
static func _bell(buffer: PackedFloat32Array, start: int, level: float, decay: float, length: float) -> void:
	var end: int = mini(start + roundi(length * MIX_RATE), buffer.size())
	for i: int in range(start, end):
		var t: float = float(i - start) / MIX_RATE
		var value: float = sin(TAU * 1180.0 * t) + 0.6 * sin(TAU * 1742.0 * t) * exp(-t / 0.05) \
				+ 0.4 * sin(TAU * 2650.0 * t) * exp(-t / 0.03)
		buffer[i] += value * level * exp(-t / decay) * _edges(i, start, end)


## Rampas cortas al principio y al final de un golpe para que no haga clic.
static func _edges(i: int, start: int, end: int) -> float:
	return minf(1.0, minf((i - start + 1) / float(ATTACK_SAMPLES), (end - i) / 64.0))


static func _apply_echo(buffer: PackedFloat32Array, delay: int, feedback: float, mix: float) -> void:
	if delay <= 0:
		return
	var wet := PackedFloat32Array()
	wet.resize(buffer.size())
	for i: int in range(delay, buffer.size()):
		wet[i] = buffer[i - delay] + feedback * wet[i - delay]
	for i: int in buffer.size():
		buffer[i] += wet[i] * mix


## Saca la componente continua, suaviza los agudos más ásperos y lleva el tema a TARGET_RMS con un
## limitador suave. Los filtros arrancan con el estado del final, así la vuelta no hace clic.
static func _master(samples: PackedFloat32Array) -> void:
	var count: int = samples.size()
	if count == 0:
		return
	var low: float = 1.0 - exp(-TAU * LOWPASS_HZ / MIX_RATE)
	var block: float = exp(-TAU * DC_BLOCK_HZ / MIX_RATE)
	var smooth: float = 0.0
	var last_in: float = 0.0
	var last_out: float = 0.0
	var warmup: int = mini(count, 8192)
	for pass_index: int in 2:
		var from: int = count - warmup if pass_index == 0 else 0
		for i: int in range(from, count):
			smooth += (samples[i] - smooth) * low
			var out: float = smooth - last_in + block * last_out
			last_in = smooth
			last_out = out
			if pass_index == 1:
				samples[i] = out
	var power: float = 0.0
	for i: int in count:
		power += samples[i] * samples[i]
	if power <= 0.0:
		return
	var scale: float = TARGET_RMS / sqrt(power / count)
	var knee: float = 1.0 - LIMIT
	for i: int in count:
		var value: float = samples[i] * scale
		var size: float = absf(value)
		if size > LIMIT:
			value = signf(value) * (LIMIT + knee * tanh((size - LIMIT) / knee))
		samples[i] = value


static func _pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		data.encode_s16(i * 2, clampi(roundi(samples[i] * 32767.0), -32768, 32767))
	return data


static func _put_text(bytes: PackedByteArray, text: String) -> void:
	bytes.append_array(text.to_ascii_buffer())


static func _put_u32(bytes: PackedByteArray, value: int) -> void:
	var at: int = bytes.size()
	bytes.resize(at + 4)
	bytes.encode_u32(at, value)


static func _put_u16(bytes: PackedByteArray, value: int) -> void:
	var at: int = bytes.size()
	bytes.resize(at + 2)
	bytes.encode_u16(at, value)


## Recorre el texto de un canal: números, duraciones y alteraciones.
class _Reader:
	var text: String
	var position: int = 0
	var error: String = ""

	func _init(p_text: String) -> void:
		text = p_text

	func done() -> bool:
		return position >= text.length()

	func peek() -> String:
		return "" if done() else text[position]

	func next() -> String:
		position += 1
		return text[position - 1]

	func fail(message: String) -> void:
		if error.is_empty():
			error = message

	## Un número entero; si no hay, `default`.
	func number(default: int) -> int:
		var start: int = position
		while not done() and text[position].is_valid_int():
			position += 1
		return default if position == start else text.substr(start, position - start).to_int()

	## Una duración (1, 2, 4, 8, 16, 32, con puntos) en ticks; sin número, `default` (con puntos).
	func length(default: int) -> int:
		var divisor: int = number(0)
		var ticks: int = default
		if divisor > 0:
			if WHOLE_TICKS % divisor != 0:
				fail("duración rara: %d (carácter %d)" % [divisor, position])
				return default
			ticks = floori(WHOLE_TICKS / float(divisor))
		var add: int = ticks
		while peek() == ".":
			position += 1
			add = floori(add / 2.0)
			ticks += add
		return ticks

	## +1 (sostenido: + o #), -1 (bemol: -) o 0.
	func accidental() -> int:
		var value: int = 0
		while peek() in ["+", "#", "-"]:
			value += -1 if next() == "-" else 1
		return value
