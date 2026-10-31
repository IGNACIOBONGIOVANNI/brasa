extends Node
## Señales globales que cruzan sistemas. Lo local se conecta directo entre nodos.
## Las señales se emiten desde otros scripts, por eso se ignora "unused_signal" acá.

@warning_ignore_start("unused_signal")

## Pide sacudir la cámara. trauma en [0, 1]; se acumula y decae solo.
signal shake_requested(trauma: float)
## Pide congelar el juego `duration` segundos (lo maneja HitStop). Si llegan dos, gana el más largo.
signal hitstop_requested(duration: float)
signal enemy_killed(enemy: Node2D)
## El jugador perdió vida (en medios corazones).
signal player_damaged(amount: float)
signal player_died

@warning_ignore_restore("unused_signal")
