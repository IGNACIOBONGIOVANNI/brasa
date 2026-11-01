class_name MechData
extends Resource
## Un armazón (mecha) que el jugador puede manejar. Se encuentra parado en el Galpón (sala especial
## HANGAR); tocarlo lo sube. Mientras lo maneja, los golpes le sacan blindaje en vez de vida, se mueve
## a su velocidad y dispara su arma (con los stats del jugador, así los items también suman). Rodar lo
## hace saltar afuera (el armazón queda parado con el blindaje que le quedaba) y si el blindaje llega
## a cero, revienta.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Golpes que aguanta (en medios corazones, como la vida).
@export var armor: float = 12.0
@export var move_speed: float = 70.0
## Su arma (munición infinita).
@export var weapon: WeaponData
@export var body_color: Color = Color("6b6278")
## Franjas, luces y la barra de blindaje del HUD.
@export var accent_color: Color = Color("ff8a3d")
