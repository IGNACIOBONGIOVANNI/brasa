class_name BossAttack
extends Resource
## Un movimiento de jefe. Cada fase (BossPhase) tiene varios y el jefe los alterna al azar (stream de
## combate), sin repetir el mismo dos veces seguidas. Todos arrancan con `windup` segundos de aviso
## (se frena, parpadea, "!" y sonido) y terminan con `recover` segundos de pausa: la ventana para
## pegarle. Lo que hace en el medio depende de `kind`:
## - VOLLEY: dispara `pattern` `count` veces, una cada `interval` s.
## - DEBRIS: tiembla el techo y caen `count` cascotes cerca del jugador (el primero justo donde está,
##   los demás a `spread` px como mucho), uno cada `interval` s. Cada uno avisa con su sombra
##   `warn_time` s y pega en `radius`; con `pattern`, al romperse suelta esas balas.
## - FRAG_BOMBS: tira `count` bombas en arco cerca del jugador; cada una espera `warn_time` s en el
##   piso, explota en `radius` y suelta `pattern` (la metralla). El Pulso las apaga.
## - DARK_CLAWS: apaga la luz (`darkness`), se esconde y tira `count` zarpazos donde está el jugador,
##   uno cada `interval` s; cada uno avisa `warn_time` s. Después vuelve la luz y aparece en otro lado.
## - SNIPE: salta a una punta de la sala lejos del jugador y le apunta con una mira láser `warn_time`
##   s; la mira queda fija `lock_time` s (muy poco para salirse de costado: hay que rodar) y dispara un
##   rayo. `count` disparos seguidos.
## - LEAP: salta, su sombra sigue al jugador `warn_time` s, queda fija `lock_time` s y cae: pega en
##   `radius` y suelta `pattern`. `count` saltos seguidos.
## - CHARGES: `count` embestidas seguidas a `speed` px/s; cada una muestra `warn_time` s la línea por
##   donde va a pasar. Si un foso o una roca tapan el camino, corta y vuelve a caminar (rodeándolo).
## - SUMMON: invoca `count` de `summon`, sin pasar de `cap` vivos.
## - GROUND_LINES: golpes que avanzan por el piso (`look`: raíces o grietas de fuego) en `count`
##   líneas: un abanico de `spread` grados hacia el jugador o, si `aim_at_player` es false,
##   repartidas en 360°. Un golpe cada `interval` s por línea; cada uno avisa `warn_time` s.
## - SWEEP: un rayo que barre `spread` grados a `speed` grados por segundo; antes muestra `warn_time` s
##   por dónde empieza.
## - MOLTEN: `count` charcos de metal fundido cerca del jugador (el primero donde está); avisan
##   `warn_time` s, queman en `radius` y quedan `linger` s lastimando a quien los pise.

enum Kind { VOLLEY, DEBRIS, FRAG_BOMBS, DARK_CLAWS, SNIPE, LEAP, CHARGES, SUMMON, GROUND_LINES, SWEEP, MOLTEN }
## Cómo se ve un golpe avisado (BossStrike).
enum Look { STONE, ROOT, CLAW, EMBER }

@export var id: StringName = &""
## Nombre del movimiento (para la documentación y el menú de debug).
@export var display_name: String = ""
@export var kind: Kind = Kind.VOLLEY
## Aviso antes de empezar.
@export var windup: float = 0.7
## Pausa al terminar.
@export var recover: float = 0.7

@export_group("Golpes")
## Cuántas veces (balas, cascotes, bombas, zarpazos, disparos, saltos, embestidas, líneas, charcos).
@export_range(1, 32) var count: int = 1
## Segundos entre una y otra.
@export var interval: float = 0.3
## Aviso de cada golpe: la sombra, la mecha, la mira, la marca en el piso.
@export var warn_time: float = 0.8
## SNIPE y LEAP: cuánto queda fija la mira o la sombra antes de pegar.
@export var lock_time: float = 0.25
## En medios corazones.
@export var damage: float = 1.0
@export var radius: float = 14.0
## Px alrededor del jugador (cascotes, bombas, charcos) o grados (abanico de líneas, barrido).
@export var spread: float = 40.0
## Embestida: px por segundo. Barrido: grados por segundo.
@export var speed: float = 200.0
## GROUND_LINES: hacia el jugador (abanico) o en 360°.
@export var aim_at_player: bool = true
@export var look: Look = Look.STONE
## MOLTEN: segundos que queda el charco.
@export var linger: float = 0.0
## DARK_CLAWS: cuánto se oscurece la sala (0 = nada, 1 = negro: solo se ve la luz del jugador).
@export_range(0.0, 1.0) var darkness: float = 0.85
## Balas que suelta (la ráfaga, la metralla, la onda al caer).
@export var pattern: BulletPatternData

@export_group("Invocación")
@export var summon: EnemyData
@export var cap: int = 3
