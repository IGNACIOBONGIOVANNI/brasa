class_name AmbientMotes
extends CPUParticles2D
## Partículas que flotan en el aire de cada piso (polvo, gotas, esporas, brasas), alrededor de la
## cámara. Las configura el FloorTheme del piso (Game las ajusta al empezar cada uno). Solo visual.

## Medio ancho y medio alto de la zona donde aparecen (un poco más que la pantalla).
const AREA: Vector2 = Vector2(170, 100)
const LIFETIME: float = 7.0


func _ready() -> void:
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = AREA
	lifetime = LIFETIME
	preprocess = LIFETIME
	local_coords = false
	gravity = Vector2.ZERO
	spread = 12.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	color_ramp = ramp


func configure(theme: FloorTheme) -> void:
	emitting = false
	amount = maxi(1, theme.mote_amount)
	color = theme.mote_color
	direction = theme.mote_velocity.normalized() if theme.mote_velocity != Vector2.ZERO else Vector2.UP
	initial_velocity_min = theme.mote_velocity.length() * 0.6
	initial_velocity_max = theme.mote_velocity.length() * 1.2
	restart()
