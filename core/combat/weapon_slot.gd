class_name WeaponSlot
extends RefCounted
## Un arma que lleva el jugador y su munición: cargador, reserva y recarga. Sin cargador
## (magazine = -1) gasta directo de la reserva; con reserva -1 la munición es infinita.

var weapon: WeaponData
var in_magazine: int = 0
## -1 = infinita.
var reserve: int = -1
var _reload_left: float = 0.0


func _init(data: WeaponData) -> void:
	weapon = data
	reserve = data.ammo
	in_magazine = maxi(0, data.magazine)


func has_magazine() -> bool:
	return weapon.magazine > 0


func is_infinite() -> bool:
	return weapon.ammo < 0


func is_reloading() -> bool:
	return _reload_left > 0.0


## 0 al empezar a recargar, 1 al terminar.
func reload_progress() -> float:
	return 1.0 - _reload_left / weapon.reload_time if is_reloading() else 1.0


## Balas listas para disparar sin recargar (-1 = infinitas).
func loaded() -> int:
	if has_magazine():
		return in_magazine
	return -1 if is_infinite() else reserve


## Sin nada en el cargador ni en la reserva.
func is_empty() -> bool:
	return not is_infinite() and reserve <= 0 and (not has_magazine() or in_magazine <= 0)


func can_fire() -> bool:
	if is_reloading():
		return false
	if has_magazine():
		return in_magazine > 0
	return is_infinite() or reserve > 0


func consume() -> void:
	if has_magazine():
		in_magazine = maxi(0, in_magazine - 1)
	elif not is_infinite():
		reserve = maxi(0, reserve - 1)


## Empieza a recargar si hace falta y hay munición. Devuelve true si empezó.
func start_reload() -> bool:
	if not has_magazine() or is_reloading() or in_magazine >= weapon.magazine:
		return false
	if not is_infinite() and reserve <= 0:
		return false
	_reload_left = weapon.reload_time
	return true


func cancel_reload() -> void:
	_reload_left = 0.0


## Avanza la recarga. Devuelve true en el tick en que termina.
func update(delta: float) -> bool:
	if not is_reloading():
		return false
	_reload_left -= delta
	if _reload_left > 0.0:
		return false
	_reload_left = 0.0
	var wanted: int = weapon.magazine - in_magazine
	var moved: int = wanted if is_infinite() else mini(wanted, reserve)
	in_magazine += moved
	if not is_infinite():
		reserve -= moved
	return true


## Suma una fracción de la munición máxima a la reserva, sin pasarse del máximo.
func refill(fraction: float) -> void:
	if not is_infinite():
		reserve = mini(weapon.ammo, reserve + ceili(weapon.ammo * fraction))
