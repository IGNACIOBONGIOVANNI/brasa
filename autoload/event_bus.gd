extends Node
## Señales globales que cruzan sistemas. Lo local se conecta directo entre nodos.
## Las señales se emiten desde otros scripts, por eso se ignora "unused_signal" acá.

@warning_ignore_start("unused_signal")

## Pide sacudir la cámara. trauma en [0, 1]; se acumula y decae solo.
signal shake_requested(trauma: float)
## Pide congelar el juego `duration` segundos (lo maneja HitStop). Si llegan dos, gana el más largo.
signal hitstop_requested(duration: float)
signal enemy_killed(enemy: Node2D)
## Un golpe le hizo daño a un enemigo.
signal enemy_hit(enemy: Node2D, info: HitInfo)
## El jugador agarró un pickup del piso (moneda, corazón, bomba, llave).
signal pickup_collected(pickup: PickupData)
## El jugador agarró un item de un pedestal.
signal item_picked(item: ItemData)
## El jugador perdió vida (en medios corazones).
signal player_damaged(amount: float)
signal player_died
## El jugador entró a la sala de esa celda del piso.
signal room_entered(cell: Vector2i)
## Murió el último enemigo de la sala y se abrieron las puertas.
signal room_cleared(cell: Vector2i)
## Explotó una bomba (FloorController la usa para destapar puertas secretas).
signal exploded(at: Vector2, radius: float)

@warning_ignore_restore("unused_signal")
