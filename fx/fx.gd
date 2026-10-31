class_name Fx
extends RefCounted
## Atajo para instanciar efectos visuales en los contenedores de la escena de juego.

## Efectos por encima de las entidades (partículas, ondas).
const EFFECTS_GROUP: StringName = &"effects"
## Cosas pegadas al piso, por debajo de las entidades (manchas).
const DECALS_GROUP: StringName = &"decals"


## Instancia `scene` en la posición global `at`, dentro del nodo del grupo `group` (o en la escena
## actual si no hay). Se agrega diferido, así es seguro llamarlo desde callbacks de física.
## Devuelve el nodo para configurarlo antes de que entre al árbol.
static func spawn(tree: SceneTree, scene: PackedScene, at: Vector2, group: StringName = EFFECTS_GROUP) -> Node2D:
	var node := scene.instantiate() as Node2D
	var container: Node = tree.get_first_node_in_group(group)
	if container == null:
		container = tree.current_scene if tree.current_scene != null else tree.root
	var container_2d := container as Node2D
	node.position = container_2d.to_local(at) if container_2d != null else at
	_attach.call_deferred(container.get_instance_id(), node)
	return node


## Si el contenedor se liberó antes del agregado diferido (fin de la run), libera el efecto para
## que no quede huérfano. Recibe el id y no el nodo: un objeto ya liberado no se puede pasar
## como argumento tipado.
static func _attach(container_id: int, node: Node) -> void:
	var container := instance_from_id(container_id) as Node
	if container != null and container.is_inside_tree():
		container.add_child(node)
	else:
		node.free()
