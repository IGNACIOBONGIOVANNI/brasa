class_name FloorTheme
extends Resource
## Todo lo que define un piso: cómo se genera, qué plantillas y enemigos usa, qué premios da y sus
## colores.

@export var id: StringName = &""
@export var display_name: String = ""

@export_group("Generación")
## Salas sin contar la secreta (incluye inicio, jefe, tesoro y tienda).
@export var room_count_min: int = 8
@export var room_count_max: int = 10
@export var min_boss_distance: int = 3
@export var templates: Array[RoomTemplate] = []
## Enemigos que pueden aparecer; la plantilla los nombra por su template_char.
@export var enemies: Array[EnemyData] = []

@export_group("Recompensas")
## Probabilidad de que limpiar una sala dé un pickup.
@export_range(0.0, 1.0) var room_reward_chance: float = 0.6
## Probabilidad de que un enemigo suelte una moneda al morir.
@export_range(0.0, 1.0) var enemy_coin_chance: float = 0.15
@export var pickups: Array[PickupData] = []

@export_group("Paleta")
@export var floor_color: Color = Color(0.169, 0.137, 0.2)
@export var floor_checker_color: Color = Color(0.188, 0.157, 0.227)
@export var wall_color: Color = Color(0.29, 0.247, 0.333)
@export var outline_color: Color = Color(0.106, 0.078, 0.125)
@export var rock_color: Color = Color(0.42, 0.38, 0.46)
@export var pit_color: Color = Color(0.04, 0.03, 0.06)


func enemy_for_symbol(symbol: String) -> EnemyData:
	for enemy: EnemyData in enemies:
		if enemy.template_char == symbol:
			return enemy
	return null


func pickup_of_kind(kind: PickupData.Kind) -> PickupData:
	for pickup: PickupData in pickups:
		if pickup.kind == kind:
			return pickup
	return null


func pickup_for_symbol(symbol: String) -> PickupData:
	for pickup: PickupData in pickups:
		if pickup.template_symbol == symbol:
			return pickup
	return null
