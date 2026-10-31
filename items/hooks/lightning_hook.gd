extends ItemHook
## Relámpago (activo): un rayo le pega a todos los enemigos vivos de la sala. Sin enemigos no se gasta.

const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const DAMAGE: float = 8.0
const PUSH: float = 90.0
const TRAUMA: float = 0.6
const HITSTOP: float = 0.06
const SPARK_COLOR: Color = Color("ffd166")


func on_use(context: HookContext) -> bool:
	var tree: SceneTree = context.player.get_tree()
	var targets: Array[Enemy] = []
	for node: Node in tree.get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy != null and not enemy.health.is_dead():
			targets.append(enemy)
	if targets.is_empty():
		AudioManager.play_sfx(&"empty")
		return false
	for enemy: Enemy in targets:
		var direction: Vector2 = (enemy.global_position - context.position).normalized()
		enemy.hurtbox.receive_hit(HitInfo.create(DAMAGE, direction, PUSH))
		var burst := Fx.spawn(tree, BURST_SCENE, enemy.global_position + Vector2(0, -4)) as CPUParticles2D
		burst.color = SPARK_COLOR
	EventBus.shake_requested.emit(TRAUMA)
	EventBus.hitstop_requested.emit(HITSTOP)
	AudioManager.play_sfx(&"lightning")
	return true
