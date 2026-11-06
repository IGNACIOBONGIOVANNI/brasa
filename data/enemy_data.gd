class_name EnemyData
extends Resource
## Definición de un enemigo: vida, cómo se mueve, cómo ataca y su placeholder visual.
## Todos usan la misma escena (enemy.tscn) y los mismos estados; estos datos eligen el comportamiento.
## Movimiento: CHASE (persigue), KEEP_DISTANCE (mantiene distancia), HOP (a saltos), FLY (vuela en
## círculos alrededor del jugador, por arriba de los fosos), STAY (quieto), BURROW (bajo tierra,
## invulnerable, y asoma para atacar), PHASE (se vuelve fantasma un rato: ni pega ni recibe), BOUNCE
## (rueda derecho y rebota en paredes, rocas y fosos) y PROWL (ronda al jugador en círculos, por el
## piso: los fosos lo frenan).
## Ataque: CHARGE (embestida; con `charge_axis_only`, solo en línea recta cuando el jugador queda
## alineado), SHOOT (patrones de balas), BEAM (rayo que avisa la línea), EXPLODE (explota y muere),
## SUMMON (invoca otros enemigos), LOB (tira bolas que caen donde estabas), SLASH (un tajo corto
## adelante, con un saltito) y GUST (sopla: empuja al jugador para atrás).

enum MoveStyle { CHASE, KEEP_DISTANCE, HOP, FLY, STAY, BURROW, PHASE, BOUNCE, PROWL }
enum AttackKind { CHARGE, SHOOT, BEAM, EXPLODE, SUMMON, LOB, SLASH, GUST }
enum VisualStyle { HORNED, EYE, LANTERN, SPORE, BLOCK, SLIME, BAT, FUSE, NEST, MOLE, WISP, SHIELD, MORTAR,
		YARN, SHEARS, BURR, MOTH, BOULDER, CROW, WOLF, ICE, CLOUD, GALE, DETHRONED, AVALANCHE, GHOST, VETERAN,
		SPIKED_SLIME, TREE, ANVIL, SWORD, AXE, KNIFE, FORGE_HEART }

@export var id: StringName = &""
@export var display_name: String = ""
## Jefes: lo que dice el cartel debajo del nombre al aparecer (vacío = "Jefe").
@export var epithet: String = ""
## Letra (mayúscula) que lo representa en las plantillas de sala. No puede ser la "O".
@export var template_char: String = ""
@export var max_health: float = 10.0
## Daño al tocar al jugador, en medios corazones.
@export var contact_damage: float = 1.0
## Segundos que tarda en aparecer antes de moverse y hacer daño por contacto.
@export var spawn_delay: float = 0.8

@export_group("Movimiento")
@export var move_style: MoveStyle = MoveStyle.CHASE
@export var move_speed: float = 35.0
@export var acceleration: float = 400.0
## Distancia que intenta mantener del jugador (KEEP_DISTANCE).
@export var preferred_distance: float = 90.0
## 0 = recibe todo el empujón de los golpes, 1 = no se mueve.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
## HOP: segundos entre saltos.
@export var hop_interval: float = 0.8
## PHASE: segundos sólido y segundos fantasma.
@export var solid_time: float = 2.2
@export var ghost_time: float = 1.4

@export_group("Ataque")
@export var attack_kind: AttackKind = AttackKind.CHARGE
## Solo ataca si el jugador está a esta distancia o menos.
@export var attack_range: float = 120.0
## Segundos entre ataques (varía un poco al azar con el stream de combate).
@export var attack_cooldown: float = 1.5
## Duración del aviso (parpadeo, "!" y sonido) antes de cada ataque.
@export var telegraph_time: float = 0.5
## Pausa después de atacar.
@export var recover_time: float = 0.6
## CHARGE: px por segundo y cuánto dura. SLASH: el saltito hacia adelante. GUST: con cuánta fuerza
## empuja (px por segundo).
@export var charge_speed: float = 200.0
@export var charge_time: float = 0.4
## CHARGE solo cuando el jugador queda en la misma fila o columna: va derecho por ese eje hasta chocar
## (y rompe las rocas que choca).
@export var charge_axis_only: bool = false
## Patrones que dispara (SHOOT): uno por ataque, en orden. EXPLODE y LOB sueltan el primero (un
## anillo) donde explotan.
@export var patterns: Array[BulletPatternData] = []
## BEAM, EXPLODE, LOB y SLASH: daño del rayo, de la explosión o del tajo, en medios corazones.
@export var attack_damage: float = 1.0
## BEAM y GUST: segundos que dura el rayo o el soplido.
@export var beam_time: float = 0.5
## EXPLODE y LOB: radio de la explosión. SLASH: medio largo del tajo.
@export var blast_radius: float = 24.0
## LOB: segundos que tarda en caer la bola.
@export var lob_time: float = 0.9
## SUMMON: qué invoca, cuántos por vez y cuántos vivos como máximo.
@export var summon: EnemyData
@export var summon_count: int = 2
@export var summon_cap: int = 3
## SUMMON: aparecen en el borde de la sala, como si salieran del escenario (lejos de las puertas y del
## jugador), en vez de al lado.
@export var summon_anywhere: bool = false
## Al morir se lleva a sus invocaciones: desaparecen sin soltar nada (los ojos de los poltergeist).
@export var summons_die_with_me: bool = false

@export_group("Al morir")
## Se divide en `split_count` copias de `split_into` (las babosas). Cada una puede dividirse de nuevo.
@export var split_into: EnemyData
@export var split_count: int = 2
## Balas que suelta al morir (un anillo con `count` balas), como un témpano que se parte.
@export var death_pattern: BulletPatternData
## Lo que suelta seguro al morir (los minijefes: corazones, bombas, llaves, monedas).
@export var drops: Array[PickupData] = []

@export_group("Escudo")
## Ancho del escudo frontal, en grados (0 = sin escudo). Mientras camina o avisa frena las balas y los
## rayos que le llegan de frente; al atacar baja la guardia.
@export_range(0.0, 360.0) var shield_degrees: float = 0.0

@export_group("Cuerpo")
## Círculo que choca con paredes y otros enemigos; también es el radio del daño por contacto.
@export var body_radius: float = 5.0
## Zona donde recibe las balas del jugador.
@export var hurtbox_radius: float = 7.0

@export_group("Jefe")
## Si tiene fases es un jefe: barra de vida propia y comportamiento que cambia según la vida. Los
## campos de Movimiento y Ataque de este recurso se ignoran; se usan los de cada fase.
@export var phases: Array[BossPhase] = []
## Minijefe: pelea como un jefe (barra, cartel, fases y movimientos) pero en una sala propia del piso
## (RoomSlot.Kind.MINIBOSS), con la música del piso; no abre la salida ni cuenta como jefe vencido.
@export var miniboss: bool = false

@export_group("Visual placeholder")
@export var visual_style: VisualStyle = VisualStyle.HORNED
@export var visual_radius: float = 7.0
@export var body_color: Color = Color("c4553f")
