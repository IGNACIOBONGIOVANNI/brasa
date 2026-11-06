class_name MechData
extends Resource
## Un armazón (mecha) que el jugador puede manejar. Se encuentra parado en el Galpón (sala especial
## HANGAR); tocarlo lo sube. Mientras lo maneja, los golpes le sacan blindaje en vez de vida, se mueve
## a su velocidad y dispara su arma (con los stats del jugador, así los items también suman). Rodar lo
## hace saltar afuera (el armazón queda parado con el blindaje que le quedaba) y si el blindaje llega
## a cero, revienta.
## `frame` es su chasis, que cambia todo el dibujo (MechDrawing): HEAVY (ancho y blindado, con
## hombreras, chimeneas y la cabina como una visera en el pecho), WALKER (patas de ave con la rodilla
## al revés y el piloto sentado arriba, a la vista) y STANDARD (de forma humana, con la cabina redonda
## y un fuelle en la espalda).

enum Frame { HEAVY, WALKER, STANDARD }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Golpes que aguanta (en medios corazones, como la vida).
@export var armor: float = 12.0
@export var move_speed: float = 70.0
## Su arma (munición infinita).
@export var weapon: WeaponData
@export var frame: Frame = Frame.STANDARD
@export var body_color: Color = Color("6b6278")
## Franjas, luces y la barra de blindaje del HUD.
@export var accent_color: Color = Color("ff8a3d")
