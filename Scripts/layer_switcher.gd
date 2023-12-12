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
						i.layer = bottomRight
					else:
						i.layer = topRight
				elif i.yPosition > global_position.y:
					i.layer = bottomLeft
				else:
					i.layer = topLeft
