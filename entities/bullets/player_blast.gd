class_name PlayerBlast
extends RefCounted
## Explosión de un arma del jugador (cohete de la bazuca, granada): lastima a todos los enemigos dentro
## del radio con el daño del disparo (los escudos no la frenan; a los que están bajo tierra o fantasma
## no les llega) y les aplica sus estados. No lastima al jugador ni rompe rocas: eso es de las bombas.

const WAVE_SCENE: PackedScene = preload("res://fx/pulse_wave.tscn")
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const LIGHT_FLASH_SCENE: PackedScene = preload("res://fx/light_flash.tscn")
const STAIN_SCENE: PackedScene = preload("res://fx/floor_stain.tscn")
const TRAUMA: float = 0.3
const FIRE_COLOR: Color = Color("ff9a3c")


static func explode(tree: SceneTree, at: Vector2, spec: ShotSpec) -> void:
	var radius: float = spec.blast_radius
	var wave := Fx.spawn(tree, WAVE_SCENE, at) as PulseWave
	wave.color = FIRE_COLOR
	wave.duration = 0.18
	wave.max_radius = radius
	var burst := Fx.spawn(tree, BURST_SCENE, at) as CPUParticles2D
	burst.color = FIRE_COLOR
	burst.amount = 16
	var glow := Fx.spawn(tree, LIGHT_FLASH_SCENE, at) as LightFlash
	glow.color = FIRE_COLOR
	glow.texture_scale = radius / 18.0
	glow.duration = 0.25
	var stain := Fx.spawn(tree, STAIN_SCENE, at, Fx.DECALS_GROUP) as FloorStain
	stain.color = Color(0.05, 0.04, 0.06)
	stain.radius = radius * 0.3
	EventBus.shake_requested.emit(TRAUMA)
	AudioManager.play_sfx(&"explosion", 0.15)
	for node: Node in tree.get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy.health.is_dead() or enemy.is_hidden():
			continue
		var offset: Vector2 = enemy.hurtbox.global_position - at
		if offset.length() > radius + enemy.data.hurtbox_radius:
			continue
		if enemy.hurtbox.receive_hit(HitInfo.create(spec.damage, offset, spec.knockback)):
			StatusComponent.apply_hit(enemy.hurtbox, spec)
