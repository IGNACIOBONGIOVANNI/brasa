class_name HookContext
extends RefCounted
## Datos de un evento para los ItemHook. Siempre vienen `player` y `position`; además cada evento
## llena lo suyo: on_shoot → direction · on_hit → enemy, amount (daño) · on_kill → enemy ·
## on_room_clear → room_cell · on_damaged → amount · on_pickup → pickup · on_use → nada más.

var player: Player
var position: Vector2
var direction: Vector2
var enemy: Node2D
var amount: float
var room_cell: Vector2i
var pickup: PickupData
