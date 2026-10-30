class_name OneShotParticles
extends CPUParticles2D
## Partículas de una sola emisión que se liberan solas al terminar.


func _ready() -> void:
	finished.connect(queue_free)
	restart()
