class_name EnemyBossAttackState
extends State
## Un movimiento propio de jefe (BossPhase.attacks): elige el próximo (Enemy.next_boss_attack), lo
## corre de punta a punta con su BossMove (aviso incluido) y pasa a Recover con la pausa del
## movimiento. Si lo cortan (cambio de fase), el BossMove deja todo como estaba.

var _move: BossMove

@onready var enemy: Enemy = owner as Enemy


func enter(_previous: StringName) -> void:
	enemy.attack = enemy.next_boss_attack()
	_move = BossMoves.create(enemy, enemy.attack)
	_move.start()


func exit() -> void:
	if _move != null:
		_move.stop()
		_move = null
	enemy.next_recover = enemy.attack.recover


func physics_update(delta: float) -> void:
	if _move != null and _move.update(delta):
		machine.transition_to(&"Recover")
