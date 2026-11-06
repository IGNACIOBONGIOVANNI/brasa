class_name RunSnapshot
extends RefCounted
## Foto de una run a medias, para seguirla después (se guarda al lado de la partida: ver
## SaveManager.save_run). Lo de la run (personaje, vida, items, armas, recursos, tiempo), el piso
## (en qué piso y sala está, qué salas vio, qué puertas abrió y lo sorteado en cada sala) y el estado
## de cada sala ya armada (si se limpió, los pedestales, los pickups del piso, las rocas rotas, el pozo
## y los armazones parados). El layout no se guarda: sale igual de la seed. Todo por id (items,
## pickups, armazones, personaje) o ruta (armas), así el JSON no depende de los recursos cargados.
## `from_dict` devuelve null si el formato no es este (una foto de otra versión no se sigue).

## Cambia si cambia lo que se guarda: una foto de otro formato se descarta.
## 2 (hito 24): los pisos del capítulo 1 tienen una sala más (la del minijefe), así que el layout de
## una foto vieja ya no sale igual de la seed; además se guarda la vida entregada en el Altar.
const FORMAT: int = 2


## Un pickup tirado en el piso de una sala.
class PickupState:
	var id: StringName = &""
	## En coordenadas de la sala.
	var position: Vector2 = Vector2.ZERO


## Un pedestal: su item (&"" = vacío) y lo que cuesta.
class PedestalState:
	var item: StringName = &""
	var price: int = 0
	var health_price: int = 0
	var position: Vector2 = Vector2.ZERO


## Un armazón parado.
class MechState:
	var id: StringName = &""
	var armor: float = 0.0
	var position: Vector2 = Vector2.ZERO


## Una sala ya armada.
class RoomState:
	var cleared: bool = false
	var pedestals: Array[PedestalState] = []
	var pickups: Array[PickupState] = []
	var broken_rocks: Array[Vector2i] = []
	var well_dry: bool = false
	var mechs: Array[MechState] = []


var run_seed: int = 0
var character: StringName = &""
var floor_index: int = 0
var run_time: float = 0.0
var kills: int = 0
var bosses_defeated: Array[StringName] = []
## Vida máxima entregada en el Altar.
var sacrificed_health: float = 0.0
var health: float = 0.0
var blanks: int = 0
var coins: int = 0
var bombs: int = 0
var keys: int = 0
var items: Array[StringName] = []
var active_item: StringName = &""
var active_charge: int = 0
## Ruta del WeaponData, balas en el cargador y reserva (-1 = infinita), en el orden de RunState.
var weapon_paths: Array[String] = []
var weapon_magazines: Array[int] = []
var weapon_reserves: Array[int] = []
var current_weapon: int = 0
## Items que ya salieron en la run (no vuelven a salir).
var taken: Array[StringName] = []
## El armazón que maneja (&"" = a pie) y su blindaje.
var mech: StringName = &""
var mech_armor: float = 0.0
## Sala donde está y dónde (en coordenadas de esa sala).
var cell: Vector2i = Vector2i.ZERO
var position: Vector2 = Vector2.ZERO
## Lo sorteado de cada sala del piso (items de sus pedestales y el armazón del Galpón).
var offers: Dictionary[Vector2i, Array] = {}
var hangar_mechs: Dictionary[Vector2i, StringName] = {}
var visited: Array[Vector2i] = []
var discovered_secrets: Array[Vector2i] = []
var map_revealed: bool = false
## Barreras abiertas (secreta destapada, tienda abierta): las dos celdas en un Vector4i.
var opened_edges: Array[Vector4i] = []
var rooms: Dictionary[Vector2i, RoomState] = {}


func to_dict() -> Dictionary:
	var room_data: Dictionary = {}
	for room_cell: Vector2i in rooms:
		room_data[_cell_key(room_cell)] = _room_to_dict(rooms[room_cell])
	var offer_data: Dictionary = {}
	for offer_cell: Vector2i in offers:
		offer_data[_cell_key(offer_cell)] = _strings(offers[offer_cell])
	var mech_data: Dictionary = {}
	for mech_cell: Vector2i in hangar_mechs:
		mech_data[_cell_key(mech_cell)] = String(hangar_mechs[mech_cell])
	var edges: Array = []
	for edge: Vector4i in opened_edges:
		edges.append([edge.x, edge.y, edge.z, edge.w])
	return {
		"version": 1,
		"format": FORMAT,
		"seed": run_seed,
		"character": String(character),
		"floor": floor_index,
		"run_time": run_time,
		"kills": kills,
		"bosses": _strings(bosses_defeated),
		"sacrificed": sacrificed_health,
		"health": health,
		"blanks": blanks,
		"coins": coins,
		"bombs": bombs,
		"keys": keys,
		"items": _strings(items),
		"active": String(active_item),
		"active_charge": active_charge,
		"weapons": weapon_paths.duplicate(),
		"magazines": weapon_magazines.duplicate(),
		"reserves": weapon_reserves.duplicate(),
		"current_weapon": current_weapon,
		"taken": _strings(taken),
		"mech": String(mech),
		"mech_armor": mech_armor,
		"cell": [cell.x, cell.y],
		"position": [position.x, position.y],
		"offers": offer_data,
		"hangar_mechs": mech_data,
		"visited": _cells_to_list(visited),
		"secrets": _cells_to_list(discovered_secrets),
		"map_revealed": map_revealed,
		"edges": edges,
		"rooms": room_data,
	}


## La foto guardada, o null si no es de este formato o le falta algo.
static func from_dict(data: Dictionary) -> RunSnapshot:
	if int(data.get("format", 0)) != FORMAT or not data.has("seed") or not data.has("character"):
		return null
	var snapshot := RunSnapshot.new()
	snapshot.run_seed = int(data.get("seed", 0))
	snapshot.character = StringName(str(data.get("character", "")))
	snapshot.floor_index = int(data.get("floor", 0))
	snapshot.run_time = float(data.get("run_time", 0.0))
	snapshot.kills = int(data.get("kills", 0))
	snapshot.bosses_defeated = _names(data.get("bosses", []))
	snapshot.sacrificed_health = float(data.get("sacrificed", 0.0))
	snapshot.health = float(data.get("health", 0.0))
	snapshot.blanks = int(data.get("blanks", 0))
	snapshot.coins = int(data.get("coins", 0))
	snapshot.bombs = int(data.get("bombs", 0))
	snapshot.keys = int(data.get("keys", 0))
	snapshot.items = _names(data.get("items", []))
	snapshot.active_item = StringName(str(data.get("active", "")))
	snapshot.active_charge = int(data.get("active_charge", 0))
	for path: Variant in _list(data.get("weapons", [])):
		snapshot.weapon_paths.append(str(path))
	for value: Variant in _list(data.get("magazines", [])):
		snapshot.weapon_magazines.append(int(value))
	for value: Variant in _list(data.get("reserves", [])):
		snapshot.weapon_reserves.append(int(value))
	snapshot.current_weapon = int(data.get("current_weapon", 0))
	snapshot.taken = _names(data.get("taken", []))
	snapshot.mech = StringName(str(data.get("mech", "")))
	snapshot.mech_armor = float(data.get("mech_armor", 0.0))
	snapshot.cell = _to_cell(data.get("cell", []))
	snapshot.position = _to_vector(data.get("position", []))
	var offer_data: Dictionary = _dict(data.get("offers", {}))
	for key: Variant in offer_data:
		snapshot.offers[_key_cell(str(key))] = _names(offer_data[key])
	var mech_data: Dictionary = _dict(data.get("hangar_mechs", {}))
	for key: Variant in mech_data:
		snapshot.hangar_mechs[_key_cell(str(key))] = StringName(str(mech_data[key]))
	snapshot.visited = _list_to_cells(data.get("visited", []))
	snapshot.discovered_secrets = _list_to_cells(data.get("secrets", []))
	snapshot.map_revealed = bool(data.get("map_revealed", false))
	for edge: Variant in _list(data.get("edges", [])):
		var values: Array = _list(edge)
		if values.size() == 4:
			snapshot.opened_edges.append(Vector4i(int(values[0]), int(values[1]), int(values[2]), int(values[3])))
	var room_data: Dictionary = _dict(data.get("rooms", {}))
	for key: Variant in room_data:
		snapshot.rooms[_key_cell(str(key))] = _room_from_dict(_dict(room_data[key]))
	return snapshot


static func _room_to_dict(room: RoomState) -> Dictionary:
	var pedestals: Array = []
	for pedestal: PedestalState in room.pedestals:
		pedestals.append({"item": String(pedestal.item), "price": pedestal.price, "health_price": pedestal.health_price,
				"position": [pedestal.position.x, pedestal.position.y]})
	var pickups: Array = []
	for pickup: PickupState in room.pickups:
		pickups.append({"id": String(pickup.id), "position": [pickup.position.x, pickup.position.y]})
	var mechs: Array = []
	for parked: MechState in room.mechs:
		mechs.append({"id": String(parked.id), "armor": parked.armor, "position": [parked.position.x, parked.position.y]})
	return {
		"cleared": room.cleared,
		"pedestals": pedestals,
		"pickups": pickups,
		"broken_rocks": _cells_to_list(room.broken_rocks),
		"well_dry": room.well_dry,
		"mechs": mechs,
	}


static func _room_from_dict(data: Dictionary) -> RoomState:
	var room := RoomState.new()
	room.cleared = bool(data.get("cleared", false))
	for entry: Variant in _list(data.get("pedestals", [])):
		var values: Dictionary = _dict(entry)
		var pedestal := PedestalState.new()
		pedestal.item = StringName(str(values.get("item", "")))
		pedestal.price = int(values.get("price", 0))
		pedestal.health_price = int(values.get("health_price", 0))
		pedestal.position = _to_vector(values.get("position", []))
		room.pedestals.append(pedestal)
	for entry: Variant in _list(data.get("pickups", [])):
		var values: Dictionary = _dict(entry)
		var pickup := PickupState.new()
		pickup.id = StringName(str(values.get("id", "")))
		pickup.position = _to_vector(values.get("position", []))
		room.pickups.append(pickup)
	room.broken_rocks = _list_to_cells(data.get("broken_rocks", []))
	room.well_dry = bool(data.get("well_dry", false))
	for entry: Variant in _list(data.get("mechs", [])):
		var values: Dictionary = _dict(entry)
		var parked := MechState.new()
		parked.id = StringName(str(values.get("id", "")))
		parked.armor = float(values.get("armor", 0.0))
		parked.position = _to_vector(values.get("position", []))
		room.mechs.append(parked)
	return room


static func _cell_key(value: Vector2i) -> String:
	return "%d,%d" % [value.x, value.y]


static func _key_cell(key: String) -> Vector2i:
	var parts: PackedStringArray = key.split(",")
	return Vector2i(int(parts[0]), int(parts[1])) if parts.size() == 2 else Vector2i.ZERO


static func _cells_to_list(cells: Array[Vector2i]) -> Array:
	var result: Array = []
	for value: Vector2i in cells:
		result.append([value.x, value.y])
	return result


static func _list_to_cells(data: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for entry: Variant in _list(data):
		result.append(_to_cell(entry))
	return result


static func _to_cell(data: Variant) -> Vector2i:
	var values: Array = _list(data)
	return Vector2i(int(values[0]), int(values[1])) if values.size() == 2 else Vector2i.ZERO


static func _to_vector(data: Variant) -> Vector2:
	var values: Array = _list(data)
	return Vector2(float(values[0]), float(values[1])) if values.size() == 2 else Vector2.ZERO


static func _strings(names: Array) -> Array:
	var result: Array = []
	for value: Variant in names:
		result.append(str(value))
	return result


static func _names(data: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in _list(data):
		result.append(StringName(str(value)))
	return result


static func _list(data: Variant) -> Array:
	return data if data is Array else []


static func _dict(data: Variant) -> Dictionary:
	return data if data is Dictionary else {}
