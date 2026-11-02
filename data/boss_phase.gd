class_name BossPhase
extends Resource
## Una fase de un jefe: desde qué fracción de vida arranca, cómo se mueve (movimiento, cooldown y
## alcance de su EnemyData; la vida, el cuerpo y el dibujo salen del EnemyData del jefe) y sus
## movimientos propios (`attacks`). Sin movimientos ataca con el ataque común de `behavior`.

## Arranca cuando vida / vida máxima baja de esto (la primera fase usa 1.0).
@export_range(0.0, 1.0) var health_fraction: float = 1.0
@export var behavior: EnemyData
@export var attacks: Array[BossAttack] = []
