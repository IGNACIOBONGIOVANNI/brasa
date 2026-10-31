class_name EnemyBlast
extends RefCounted
## Explosión de un enemigo (la Mecha al reventar, la bola del Fogonero al caer): onda, chispas, luz y
## sacudida; lastima al jugador si está dentro del radio (rodando no) y suelta un anillo de balas (el
## patrón que se le pase, si hay).

const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")
const WAVE_SCENE: PackedScene = preload("res://fx/pulse_wave.tscn")
const BURST_SCENE: PackedScene = preload("res://fx/burst.tscn")
const LIGHT_FLASH_SCENE: PackedScene = preload("res://fx/light_flash.tscn")
const STAIN_SCENE: PackedScene = preload("res://fx/floor_stain.tscn")
const KNOCKBACK: float = 160.0
const TRAUMA: float = 0.35
## Margen sobre el radio (el cuerpo del jugador).
const REACH: float = 4.0


static func explode(tree: SceneTree, at: Vector2, radius: float, damage: float, pattern: BulletPatternData,
		speed_multiplier: float, color: Color) -> void:
	var wave := Fx.spawn(tree, WAVE_SCENE, at) as PulseWave
	wave.color = color
	wave.duration = 0.2
	wave.max_radius = radius + REACH
	var burst := Fx.spawn(tree, BURST_SCENE, at) as CPUParticles2D
	burst.color = color
	burst.amount = 18
	var glow := Fx.spawn(tree, LIGHT_FLASH_SCENE, at) as LightFlash
	glow.color = color
	glow.texture_scale = radius / 20.0
	glow.duration = 0.3
	var stain := Fx.spawn(tree, STAIN_SCENE, at, Fx.DECALS_GROUP) as FloorStain
	stain.color = Color(0.05, 0.04, 0.06)
	stain.radius = radius * 0.35
	EventBus.shake_requested.emit(TRAUMA)
	AudioManager.play_sfx(&"explosion", 0.1)
	for node: Node in tree.get_nodes_in_group(Player.GROUP):
		var player := node as Player
		var offset: Vector2 = player.global_position - at
		if offset.length() <= radius + REACH:
			player.hurtbox.receive_hit(HitInfo.create(damage, offset, KNOCKBACK))
	if pattern == null:
		return
	var spec := ShotSpec.from_pattern(pattern)
	spec.speed *= speed_multiplier
	for direction: Vector2 in PatternMath.ring(pattern.count, deg_to_rad(pattern.angle_offset_degrees)):
		Bullet.spawn(tree, BULLET_SCENE, spec, at + direction * REACH, direction, PhysicsLayers.ENEMY_BULLET,
				PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)
