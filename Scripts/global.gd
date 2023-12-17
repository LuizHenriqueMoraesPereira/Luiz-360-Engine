extends Node

var currentLevel : Level = null
var rings : int = 0

func _ready() -> void:
	var root = get_tree().root
	currentLevel = root.get_child(root.get_child_count() - 1)

func _find_node(node_name : String) -> Node2D:
	for i in currentLevel.get_children():
		if i.name == node_name:
			return i
	
	return null
