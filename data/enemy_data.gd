class_name EnemyData
extends Resource
## Definición de un enemigo: vida, cómo se mueve, cómo ataca y su placeholder visual.
## Todos usan la misma escena (enemy.tscn) y los mismos estados; estos datos eligen el comportamiento.

enum MoveStyle { CHASE, KEEP_DISTANCE }
enum AttackKind { CHARGE, SHOOT }
enum VisualStyle { HORNED, EYE, LANTERN, SPORE, BLOCK }

@export var id: StringName = &""
@export var display_name: String = ""
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
@export var charge_speed: float = 200.0
@export var charge_time: float = 0.4
## Patrones que dispara (SHOOT): uno por ataque, en orden.
@export var patterns: Array[BulletPatternData] = []

@export_group("Cuerpo")
## Círculo que choca con paredes y otros enemigos; también es el radio del daño por contacto.
@export var body_radius: float = 5.0
## Zona donde recibe las balas del jugador.
@export var hurtbox_radius: float = 7.0

@export_group("Jefe")
## Si tiene fases es un jefe: barra de vida propia y comportamiento que cambia según la vida. Los
## campos de Movimiento y Ataque de este recurso se ignoran; se usan los de cada fase.
@export var phases: Array[BossPhase] = []

@export_group("Visual placeholder")
@export var visual_style: VisualStyle = VisualStyle.HORNED
@export var visual_radius: float = 7.0
@export var body_color: Color = Color("c4553f")
