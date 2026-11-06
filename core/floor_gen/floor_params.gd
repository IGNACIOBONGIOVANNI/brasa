class_name FloorParams
extends RefCounted
## Parámetros de FloorGenerator. FloorController los arma desde el FloorTheme del piso.

var grid_size: Vector2i = Vector2i(9, 8)
## Salas sin contar la secreta ni las especiales extra (incluye inicio, jefe, tesoro y tienda).
var room_count_min: int = 8
var room_count_max: int = 10
## Pasos mínimos entre el inicio y el jefe.
var min_boss_distance: int = 3
## Chance de no abrir una rama: más alta = pisos más finos y ramificados.
var branch_skip_chance: float = 0.5
## Salas especiales de más (Prueba, Altar, Pozo, Galpón, minijefe): cada una suma una sala y va en un
## callejón.
var extra_rooms: Array[RoomSlot.Kind] = []
