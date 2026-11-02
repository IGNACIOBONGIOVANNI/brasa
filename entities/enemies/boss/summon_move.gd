class_name SummonMove
extends BossMove
## SUMMON: invoca `count` de `summon` alrededor suyo, sin pasar de `cap` vivos.

const SUMMON_DISTANCE: float = 16.0


func _begin() -> void:
	var count: int = mini(attack.count, attack.cap - enemy.living_children())
	if attack.summon == null or count <= 0:
		return
	var first_angle: float = rng().randf() * TAU
	for i: int in count:
		var direction: Vector2 = Vector2.from_angle(first_angle + TAU * i / count)
		enemy.spawn_child(attack.summon, enemy.landing_spot(enemy.global_position + direction * SUMMON_DISTANCE))
	enemy.visual.play_hit()
	AudioManager.play_sfx(&"summon", 0.1)
