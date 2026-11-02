class_name BossMoves
extends RefCounted
## Arma el BossMove que corresponde a cada BossAttack.Kind.


static func create(owner_enemy: Enemy, data: BossAttack) -> BossMove:
	var move: BossMove
	match data.kind:
		BossAttack.Kind.DEBRIS:
			move = DebrisMove.new()
		BossAttack.Kind.FRAG_BOMBS:
			move = FragBombsMove.new()
		BossAttack.Kind.DARK_CLAWS:
			move = DarkClawsMove.new()
		BossAttack.Kind.SNIPE:
			move = SnipeMove.new()
		BossAttack.Kind.LEAP:
			move = LeapMove.new()
		BossAttack.Kind.CHARGES:
			move = ChargesMove.new()
		BossAttack.Kind.SUMMON:
			move = SummonMove.new()
		BossAttack.Kind.GROUND_LINES:
			move = GroundLinesMove.new()
		BossAttack.Kind.SWEEP:
			move = SweepMove.new()
		BossAttack.Kind.MOLTEN:
			move = MoltenMove.new()
		_:
			move = VolleyMove.new()
	move.enemy = owner_enemy
	move.attack = data
	return move
