extends Node
## Señales globales que cruzan sistemas. Lo local se conecta directo entre nodos.
## Las señales se emiten desde otros scripts, por eso se ignora "unused_signal" acá.

@warning_ignore_start("unused_signal")

## Pide sacudir la cámara. trauma en [0, 1]; se acumula y decae solo.
signal shake_requested(trauma: float)

@warning_ignore_restore("unused_signal")
