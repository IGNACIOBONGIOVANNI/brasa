extends ItemHook
## Segunda chispa (S++): la primera vez que un golpe te mataría, volvés con toda la vida, un rato
## invulnerable y sin balas enemigas en pantalla. Después el item se gasta.

const INVULNERABLE_TIME: float = 2.0
const TRAUMA: float = 0.7
const BURST_COLOR: Color = Color("ffd24a")
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const PULSE_WAVE_SCENE: PackedScene = preload("res://fx/pulse_wave.tscn")


func on_lethal(context: HookContext) -> bool:
	var player: Player = context.player
	player.health.revive(player.health.max_health)
	player.health.grant_invulnerability(INVULNERABLE_TIME)
	# Viene de un callback de física (el golpe): las balas y los efectos, diferidos.
	_aftermath.call_deferred(player.get_instance_id())
	RunState.remove_item.call_deferred(item)
	return true


func _aftermath(player_id: int) -> void:
	var player := instance_from_id(player_id) as Player
	if player == null or not player.is_inside_tree():
		return
	player.flash.blink(INVULNERABLE_TIME)
	for node: Node in player.get_tree().get_nodes_in_group(Bullet.GROUP):
		var bullet := node as Bullet
		if bullet != null and bullet.is_hostile_to_player():
			bullet.destroy()
	Fx.spawn(player.get_tree(), PULSE_WAVE_SCENE, player.global_position)
	var burst := Fx.spawn(player.get_tree(), BURST_SCENE, player.global_position) as CPUParticles2D
	burst.color = BURST_COLOR
	burst.amount = 24
	EventBus.shake_requested.emit(TRAUMA)
	AudioManager.play_sfx(&"revive")
