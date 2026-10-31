class_name StatCalculator
extends RefCounted
## Stats finales = (base + suma de todos los ADD) × producto de todos los MULT, recortados a sus
## límites. Se recalcula desde cero cada vez, así el resultado no depende del orden de los items.

## Mínimo y máximo de cada stat.
const LIMITS: Dictionary[StringName, Vector2] = {
	&"damage": Vector2(0.5, 99.0),
	&"fire_rate": Vector2(0.5, 30.0),
	&"shot_range": Vector2(16.0, 600.0),
	&"shot_speed": Vector2(40.0, 600.0),
	&"move_speed": Vector2(40.0, 180.0),
	&"luck": Vector2(-5.0, 10.0),
	&"max_health": Vector2(2.0, 24.0),
	&"bounces": Vector2(0.0, 5.0),
	&"pierce": Vector2(0.0, 5.0),
	&"homing": Vector2(0.0, 1.0),
	&"shot_size": Vector2(0.5, 3.0),
	&"burn_chance": Vector2(0.0, 1.0),
	&"poison_chance": Vector2(0.0, 1.0),
	&"corrupt_chance": Vector2(0.0, 1.0),
	&"douse_chance": Vector2(0.0, 1.0),
}


static func compute(base: StatBlock, items: Array[ItemData]) -> StatBlock:
	var adds: Dictionary[StringName, float] = {}
	var mults: Dictionary[StringName, float] = {}
	for item: ItemData in items:
		for modifier: StatModifier in item.modifiers:
			if modifier.op == StatModifier.Op.ADD:
				adds[modifier.stat] = adds.get(modifier.stat, 0.0) + modifier.value
			else:
				mults[modifier.stat] = mults.get(modifier.stat, 1.0) * modifier.value
	var result := StatBlock.new()
	for stat: StringName in StatBlock.STAT_NAMES:
		var base_value: float = base.get(stat)
		var added: float = adds.get(stat, 0.0)
		var multiplier: float = mults.get(stat, 1.0)
		var limits: Vector2 = LIMITS[stat]
		result.set(stat, clampf((base_value + added) * multiplier, limits.x, limits.y))
	return result
