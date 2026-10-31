class_name SfxData
extends Resource
## Un efecto de sonido. Si `stream` está asignado se usa ese archivo; si no, SfxSynth lo sintetiza
## con estos parámetros (los sonidos placeholder se generan por código).

enum Wave { SQUARE, TRIANGLE, SINE, SAW, NOISE }

@export var id: StringName = &""
## Sonido real (opcional). Tiene prioridad sobre la síntesis.
@export var stream: AudioStream

@export_group("Síntesis")
@export var wave: Wave = Wave.SQUARE
## Frecuencia al principio y al final, con barrido exponencial. En NOISE define qué tan grave suena.
@export var freq_start: float = 440.0
@export var freq_end: float = 440.0
@export var duration: float = 0.1
## Segundos de subida al principio.
@export var attack: float = 0.0
## Caída del volumen: 0 = parejo, 1 = baja lineal hasta 0, 2 o más = cae rápido.
@export var decay_power: float = 1.0
## Ancho del pulso (solo SQUARE).
@export_range(0.05, 0.95) var square_duty: float = 0.5
@export_range(0.0, 1.0) var volume: float = 0.3
