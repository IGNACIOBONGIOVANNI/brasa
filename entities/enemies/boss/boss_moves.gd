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
		BossAttack.Kind.SCISSORS:
			move = ScissorsMove.new()
		BossAttack.Kind.STAMPEDE:
			move = StampedeMove.new()
		BossAttack.Kind.SNOWBALL:
			move = SnowballMove.new()
		BossAttack.Kind.ICE_CAGE:
			move = IceCageMove.new()
		BossAttack.Kind.GUST:
			move = GustMove.new()
		BossAttack.Kind.HANGING_CUT:
			move = HangingCutMove.new()
		BossAttack.Kind.DIVE:
			move = DiveMove.new()
		BossAttack.Kind.CHARGED_ORB:
			move = ChargedOrbMove.new()
		BossAttack.Kind.TOLL:
			move = TollMove.new()
		BossAttack.Kind.CROWN_BOOMERANG:
			move = CrownBoomerangMove.new()
		BossAttack.Kind.BURROWERS:
			move = BurrowersMove.new()
		BossAttack.Kind.BEAM_CROSS:
			move = BeamCrossMove.new()
		BossAttack.Kind.THREAD_TRAIL:
			move = ThreadTrailMove.new()
		BossAttack.Kind.ECHO_CHARGES:
			move = EchoChargesMove.new()
		BossAttack.Kind.ICE_SPIRAL:
			move = IceSpiralMove.new()
		BossAttack.Kind.VORTEX:
			move = VortexMove.new()
		BossAttack.Kind.ORBITERS:
			move = OrbitersMove.new()
		BossAttack.Kind.CLOSING_RING:
			move = ClosingRingMove.new()
		BossAttack.Kind.BULLET_WALL:
			move = BulletWallMove.new()
		BossAttack.Kind.BLINK_STRIKE:
			move = BlinkStrikeMove.new()
		BossAttack.Kind.SOOT_SWEEP:
			move = SootSweepMove.new()
		_:
			move = VolleyMove.new()
	move.enemy = owner_enemy
	move.attack = data
	return move
