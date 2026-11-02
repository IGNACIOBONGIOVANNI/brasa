class_name ItemHook
extends RefCounted
## Comportamiento especial de un item. Los scripts de items/hooks/ extienden esta clase y
## sobreescriben solo los eventos que usan. ItemHookRunner (en el jugador) los llama; los eventos
## que vienen de la física llegan diferidos, así un hook puede crear balas sin problema.


var item: ItemData


func on_shoot(_context: HookContext) -> void:
	pass


func on_hit(_context: HookContext) -> void:
	pass


func on_kill(_context: HookContext) -> void:
	pass


func on_room_clear(_context: HookContext) -> void:
	pass


func on_damaged(_context: HookContext) -> void:
	pass


func on_pickup(_context: HookContext) -> void:
	pass


## Un golpe que mataría al jugador (llega en el acto, no diferido). Devuelve true si el item lo
## salva: tiene que dejarlo con vida (HealthComponent.revive).
func on_lethal(_context: HookContext) -> bool:
	return false


## Activos: se llama al usarlo. Devuelve true si se usó (y se gasta la carga).
func on_use(_context: HookContext) -> bool:
	return false


## Dispara `count` balas del jugador en anillo alrededor de él.
static func fire_ring(player: Player, count: int) -> void:
	fire_from(player, player.global_position + Vector2(0, -2), PatternMath.ring(count, player.aim_direction.angle()))


## Dispara balas del jugador desde `center` con sus stats actuales: heredan rebote, perforación y
## teledirigido como cualquier disparo.
static func fire_from(player: Player, center: Vector2, directions: Array[Vector2]) -> void:
	var spec := ShotSpec.build(RunState.stats, RunState.BASE_WEAPON)
	for direction: Vector2 in directions:
		Bullet.spawn(player.get_tree(), Bullet.default_scene(), spec, center + direction * 6.0, direction,
				PhysicsLayers.PLAYER_BULLET, PhysicsLayers.WALL | PhysicsLayers.ENEMY_HURTBOX)
