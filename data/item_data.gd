class_name ItemData
extends Resource
## Un item: pasivo (cambia stats y/o tiene un hook), activo (se usa con Q y se recarga limpiando
## salas) o arma (da un WeaponData). Aparece en los pools marcados, con la rareza que pese cada pool.

enum Kind { PASSIVE, ACTIVE, WEAPON }
enum Rarity { COMMON, UNCOMMON, RARE }

## Pools (flags de `pools`).
const POOL_TREASURE: int = 1
const POOL_SHOP: int = 2
const POOL_BOSS: int = 4
const POOL_SECRET: int = 8

@export var id: StringName = &""
@export var display_name: String = ""
## Una línea; se muestra al agarrarlo.
@export var description: String = ""
@export var kind: Kind = Kind.PASSIVE
@export var rarity: Rarity = Rarity.COMMON
@export_flags("Tesoro", "Tienda", "Jefe", "Secreta") var pools: int = POOL_TREASURE
## Precio en la tienda, en monedas.
@export var price: int = 5
@export var modifiers: Array[StatModifier] = []
## Script que extiende ItemHook (opcional): comportamiento especial y uso de los activos.
@export var hook_script: GDScript
## Activos: salas limpias que hacen falta para volver a usarlo.
@export var max_charge: int = 0
## Armas: el arma que da.
@export var weapon: WeaponData

@export_group("Desbloqueo")
## Arranca fuera de los pools: entra al comprarlo en el Taller o al cumplir un logro.
@export var locked: bool = false
## Chispas que cuesta en el Taller (0 = no se vende: lo desbloquea un logro).
@export var unlock_cost: int = 0

@export_group("Visual placeholder")
## Ícono de píxeles ("#" = píxel). Las armas usan el de su WeaponData si este está vacío.
@export var icon: PackedStringArray = []
@export var icon_color: Color = Color.WHITE


func is_in_pool(pool: int) -> bool:
	return pools & pool != 0


func get_icon() -> PackedStringArray:
	if icon.is_empty() and weapon != null:
		return weapon.icon
	return icon


func get_icon_color() -> Color:
	if icon.is_empty() and weapon != null:
		return weapon.icon_color
	return icon_color
