class_name State
extends Node
## Un estado de una StateMachine. El nombre del nodo es el nombre del estado.
## Los estados concretos sobreescriben enter/exit/physics_update y piden cambios con
## `machine.transition_to(&"OtroEstado")`.

var machine: StateMachine


func enter(_previous: StringName) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
