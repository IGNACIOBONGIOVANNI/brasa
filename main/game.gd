class_name Game
extends Node2D
## Una run: conecta el HUD con el jugador (y con el piso, si hay FloorController) y registra los
## comandos generales del menú de debug (F3). La escena de tests `tests/fixtures/arena.tscn` usa
## este mismo script con una sala fija y sin piso.

const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
## Cuánto da el comando de debug de recursos.
const DEV_RESOURCES: int = 5

@onready var player: Player = $Entities/Player
@onready var floor_controller: FloorController = get_node_or_null(^"FloorController") as FloorController
@onready var _entities: Node2D = $Entities
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_hud.bind_player(player)
	if floor_controller != null:
		_hud.bind_floor(floor_controller)
	Debug.add_command(self, "Curar al jugador", _heal_player)
	Debug.add_command(self, "Invulnerable si/no", _toggle_invulnerable)
	Debug.add_command(self, "Recargar Pulsos", _refill_pulses)
	Debug.add_command(self, "+5 monedas, bombas y llaves", _give_resources)
	Debug.add_command(self, "Matar al jugador", player.health.kill)


func spawn_enemy(data: EnemyData, at: Vector2) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = data
	enemy.position = at
	_entities.add_child(enemy)
	return enemy


func _heal_player() -> void:
	player.health.heal(player.health.max_health)


func _toggle_invulnerable() -> void:
	player.health.always_invulnerable = not player.health.always_invulnerable


func _refill_pulses() -> void:
	RunState.set_blanks(RunState.START_BLANKS)


func _give_resources() -> void:
	RunState.add_coins(DEV_RESOURCES)
	RunState.add_bombs(DEV_RESOURCES)
	RunState.add_keys(DEV_RESOURCES)
