class_name CharacterData
extends Resource
## Un personaje jugable: stats base (la vida incluida), el item con el que arranca la run y su color.
## Los bloqueados se desbloquean con un logro (AchievementData.unlock_characters). Cada uno es de un
## capítulo (RunConfig.number) y esquiva a su manera.

## Cómo esquiva: rueda, o embiste (PlayerChargeState: también invulnerable, lastima lo que atropella
## y rompe rocas).
enum Dodge { ROLL, CHARGE }
## Cómo se dibuja (PlayerVisual): la chispa o el carnero.
enum Look { SPARK, RAM }

@export var id: StringName = &""
@export var display_name: String = ""
## Una línea; se muestra al elegirlo.
@export var description: String = ""
@export var stats: StatBlock
## Item con el que arranca (pasivo, activo o arma). Opcional.
@export var start_item: ItemData
@export var locked: bool = false
## El capítulo que juega (RunConfig.number).
@export var chapter: int = 1
@export var dodge: Dodge = Dodge.ROLL

@export_group("Visual placeholder")
@export var look: Look = Look.SPARK
@export var body_color: Color = Color("e8c170")


## Corazones enteros con los que arranca.
func hearts() -> int:
	return roundi(stats.max_health / 2.0)
