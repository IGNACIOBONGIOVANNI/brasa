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
## Empezó (o terminó, con null) el combate de una sala con regla.
signal room_rule_changed(rule: RoomRule)
## Un jefe apaga (o vuelve a prender, con 0) la luz de la sala: `amount` de 0 a 1, en `fade` s.
signal darkness_requested(amount: float, fade: float)
## Explotó una bomba (FloorController la usa para destapar puertas secretas).
signal exploded(at: Vector2, radius: float)
## Empezó (true) o terminó (false) una cinemática: el jugador no se mueve y el HUD pone franjas.
signal cinematic_changed(active: bool)
## Un jefe empezó su entrada (Game pone su música).
signal boss_intro_started(boss: Node2D)
## Apareció un jefe (el HUD muestra su barra de vida). Con entrada, al terminarla.
signal boss_spawned(boss: Node2D)
## Un cartel con un aviso del mundo (el brasero que se enciende, la boca tapiada): lo muestra el HUD.
signal message_requested(title: String, subtitle: String)
signal boss_defeated(boss: Node2D)
## Empezó un piso (índice desde 0).
signal floor_changed(index: int)
## Terminó la run: victoria (salida del último piso) o no.
signal run_ended(victory: bool)

@warning_ignore_restore("unused_signal")
