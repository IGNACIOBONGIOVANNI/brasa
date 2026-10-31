class_name StateMachine
extends Node
## Máquina de estados con nodos State como hijos. El dueño la arranca con start() desde su _ready
## y la avanza llamando a physics_update(delta) desde su _physics_process, así controla el orden.

signal state_changed(previous: StringName, current: StringName)

@export var initial_state: State

var current: State
var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child: Node in get_children():
		var state := child as State
		if state != null:
			state.machine = self
			_states[state.name] = state


## Entra al estado inicial. Llamarlo cuando el dueño ya está listo.
func start() -> void:
	assert(initial_state != null, "StateMachine: falta initial_state")
	current = initial_state
	current.enter(&"")
	state_changed.emit(&"", current.name)


func physics_update(delta: float) -> void:
	if current != null:
		current.physics_update(delta)


func transition_to(state_name: StringName) -> void:
	assert(_states.has(state_name), "StateMachine: no existe el estado %s" % state_name)
	var previous: StringName = get_state_name()
	if current != null:
		current.exit()
	current = _states[state_name]
	current.enter(previous)
	state_changed.emit(previous, state_name)


func get_state_name() -> StringName:
	return current.name if current != null else &""
