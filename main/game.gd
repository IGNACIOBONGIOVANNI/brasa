class_name Game
extends Node2D
## Una run. Por ahora es la sala de prueba con tres enemigos: conecta el HUD con el jugador y
## registra los comandos del menú de debug (F3).

const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")

var _spawn_data: Array[EnemyData] = []
var _spawn_positions: Array[Vector2] = []

@onready var player: Player = $Entities/Player
@onready var _entities: Node2D = $Entities
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_hud.bind_player(player)
	# Se recuerdan los enemigos de la escena para poder reaparecerlos desde el menú de debug.
	for child: Node in _entities.get_children():
		var enemy := child as Enemy
		if enemy != null:
			_spawn_data.append(enemy.data)
			_spawn_positions.append(enemy.position)
	Debug.add_command(self, "Reaparecer enemigos", respawn_enemies)
	Debug.add_command(self, "Curar al jugador", _heal_player)
	Debug.add_command(self, "Invulnerable si/no", _toggle_invulnerable)
	Debug.add_command(self, "Recargar Pulsos", _refill_pulses)
	Debug.add_command(self, "Matar al jugador", player.health.kill)


func spawn_enemy(data: EnemyData, at: Vector2) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = data
	enemy.position = at
	_entities.add_child(enemy)
	return enemy


func respawn_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		node.queue_free()
	for i: int in _spawn_data.size():
		spawn_enemy(_spawn_data[i], _spawn_positions[i])


func _heal_player() -> void:
	player.health.heal(player.health.max_health)


func _toggle_invulnerable() -> void:
	player.health.always_invulnerable = not player.health.always_invulnerable


func _refill_pulses() -> void:
	RunState.set_blanks(RunState.START_BLANKS)
