extends Area2D

export var topLeft : int
export var topRight : int
export var bottomLeft : int
export var bottomRight : int

export var groundedOnly : bool

var entities := []

func _physics_process(_delta : float) -> void:
	if entities.size() > 0:
		for i in entities:
			if i.ground or not groundedOnly:
				if i.xPosition > global_position.x:
					if i.yPosition > global_position.y:
						i.layer = bottomRight + (16 * bottomRight)
					else:
						i.layer = topRight + (16 * topRight)
				elif i.yPosition > global_position.y:
					i.layer = bottomLeft + (16 * bottomLeft)
				else:
					i.layer = topLeft + (16 * topLeft)

func _on_area_entered(area : Node2D) -> void:
	if area.get_parent().is_in_group("Player"):
		entities.append(area.get_parent())

func _on_area_exited(area : Node2D) -> void:
	if area.get_parent().is_in_group("Player"):
		entities.erase(area.get_parent())
