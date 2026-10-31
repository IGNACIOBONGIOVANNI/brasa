class_name RunRecord
extends RefCounted
## Lo que la meta-progresión necesita saber de una run terminada (RunState.make_record).

var victory: bool = false
## Piso al que se llegó, desde 1.
var floor_reached: int = 1
var kills: int = 0
## Items al terminar (ver AchievementData.Condition.ITEMS_IN_RUN).
var items: int = 0
## ids de los jefes vencidos.
var bosses: Array[StringName] = []
var character: StringName = &""
