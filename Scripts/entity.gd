class_name Entity extends Node2D

var xPosition : float
var yPosition : float
var xSpeed : float
var ySpeed : float
var ground : bool
var groundSpeed : float
var groundAngle : float
var visualAngle : float
var layer : int

export var widthRadius : float
export var heightRadius : float
export var wallOffset : float

var space : Physics2DDirectSpaceState

var colliderFloor : Node2D
var colliderCeiling : Node2D
var colliderWall : Node2D

func _ready() -> void:
	xPosition = global_position.x
	yPosition = global_position.y
	
	layer = 17
	space = get_world_2d().direct_space_state

func _movement_process(deltaTime : float) -> void:
	if ground:
		xSpeed = groundSpeed * cos(deg2rad(groundAngle))
		ySpeed = groundSpeed * -sin(deg2rad(groundAngle))
	
	xPosition += xSpeed * deltaTime
	yPosition += ySpeed * deltaTime
	
	colliderFloor = null
	colliderCeiling = null
	colliderWall = null
	
	var steps = 1 + ceil(abs(sqrt((xSpeed * xSpeed) + (ySpeed * ySpeed))))
	while steps > 0:
		if (groundSpeed if ground else xSpeed) != 0:
			var dir = sign(groundSpeed if ground else xSpeed)
			var offset = wallOffset * (1 if (ground and fmod(round(groundAngle / 4), 90) == 0) else 0)
			var sensor = _sensor(Vector2(widthRadius * dir, offset), Vector2.RIGHT * dir)
			
			if sensor.collision:
				colliderWall = sensor.collider
				xPosition += sensor.destination.x
				yPosition += sensor.destination.y
				if ground: groundSpeed = 0
				else: xSpeed = 0
		
		if not ground and sign(ySpeed) != 0 or ground:
			var verticalLeft = _sensor(Vector2(-widthRadius + 2, heightRadius if ground else heightRadius * sign(ySpeed)), Vector2.DOWN if ground else Vector2.DOWN * sign(ySpeed), 16 if ground else 0)
			var verticalRight = _sensor(Vector2(widthRadius - 2, heightRadius if ground else heightRadius * sign(ySpeed)), Vector2.DOWN if ground else Vector2.DOWN * sign(ySpeed), 16 if ground else 0)
			var verticalCenter = _sensor(Vector2(0, heightRadius if ground else heightRadius * sign(ySpeed)), Vector2.DOWN if ground else Vector2.DOWN * sign(ySpeed), 16 if ground else 0)
			var colliderVertical : Node2D = null
			
			if verticalCenter.collision:
				if verticalLeft.collision or verticalRight.collision:
					if verticalCenter.distance > min(verticalLeft.distance, verticalRight.distance):
						if verticalRight.distance < verticalLeft.distance:
							colliderVertical = verticalRight.collider
							xPosition += verticalRight.destination.x
							yPosition += verticalRight.destination.y
						else:
							colliderVertical = verticalLeft.collider
							xPosition += verticalLeft.destination.x
							yPosition += verticalLeft.destination.y
					else:
						colliderVertical = verticalCenter.collider
						xPosition += verticalCenter.destination.x
						yPosition += verticalCenter.destination.y
				else:
					colliderVertical = verticalCenter.collider
					xPosition += verticalCenter.destination.x
					yPosition += verticalCenter.destination.y
			elif verticalLeft.collision or verticalRight.collision:
				if verticalRight.distance < verticalLeft.distance:
					colliderVertical = verticalRight.collider
					xPosition += verticalRight.destination.x
					yPosition += verticalRight.destination.y
				else:
					colliderVertical = verticalLeft.collider
					xPosition += verticalLeft.destination.x
					yPosition += verticalLeft.destination.y
			
			if colliderVertical != null:
				if ySpeed < 0 and not ground:
					colliderCeiling = colliderVertical
				else:
					colliderFloor = colliderVertical
			
			if not ground and (verticalCenter.collision or verticalLeft.collision or verticalRight.collision):
				var normal = Vector2.ZERO
				
				if verticalCenter.distance > min(verticalLeft.distance, verticalRight.distance):
					if verticalRight.distance < verticalLeft.distance:
						normal = verticalRight.normal
					else:
						normal = verticalLeft.normal
				else:
					normal = verticalCenter.normal
				
				if ySpeed >= 0:
					groundAngle = fmod(720 - rad2deg(atan2(normal.x, -normal.y)), 360)
					groundSpeed = xSpeed
					if abs(xSpeed) <= abs(ySpeed):
						if groundAngle >= 22.5 and groundAngle <= 337.5:
							groundSpeed = ySpeed * 0.84 * -sign(sin(deg2rad(groundAngle)))
					ground = true
				else:
					if ySpeed < -1 and normal.y < 0.9:
						groundAngle = fmod(720 - rad2deg(atan2(normal.x, -normal.y)), 360)
						groundSpeed = ySpeed * 0.84 * -sign(sin(deg2rad(groundAngle)))
						ground = true
					
					ySpeed = 0
			
			if ground and not (verticalCenter.collision or verticalLeft.collision or verticalRight.collision):
				xSpeed = groundSpeed * cos(deg2rad(groundAngle))
				ySpeed = groundSpeed * -sin(deg2rad(groundAngle))
				groundAngle = 0
				ground = false
		
		if ground:
			var angleLeft = _sensor(Vector2(-widthRadius + 2, heightRadius), Vector2.DOWN, 16)
			var angleRight = _sensor(Vector2(widthRadius - 2, heightRadius), Vector2.DOWN, 16)
			
			if angleLeft.collision or angleRight.collision:
				var nx = 0
				var ny = -1
				
				if angleRight.distance < angleLeft.distance:
					nx = angleRight.normal.x
					ny = angleRight.normal.y
				else:
					nx = angleLeft.normal.x
					ny = angleLeft.normal.y
				
				if angleLeft.collision and angleRight.collision:
					ny = -(angleRight.point.x - angleLeft.point.x)
					nx = angleRight.point.y - angleLeft.point.y
				
				groundAngle = fmod(720 - rad2deg(atan2(nx, -ny)), 360)
		
		steps -= 1

func _render() -> void:
	global_position.x = xPosition
	global_position.y = yPosition
	global_rotation = -visualAngle

func _sensor(anchor : Vector2, direction : Vector2, extension : float = 0) -> Dictionary:
	var absDir = Vector2(abs(direction.x), abs(direction.y))
	
	var from : Vector2 = (anchor * (Vector2.ONE - absDir)).rotated(deg2rad(-groundAngle))
	from.x += xPosition
	from.y += yPosition
	
	var to : Vector2 = (anchor + (direction * extension)).rotated(deg2rad(-groundAngle))
	to.x += xPosition
	to.y += yPosition
	
	anchor = anchor.rotated(deg2rad(-groundAngle))
	anchor.x += xPosition
	anchor.y += yPosition
	
	var result = space.intersect_ray(from, to, [self], layer)
	if result and (result.collider.collision_layer < 16 or result.collider.is_in_group("Solid") or result.collider.is_in_group("Platform") and (not ground and ySpeed >= 0 or ground) and direction.y > 0 and result.collider.global_position.y >= yPosition + (heightRadius - max(4, ySpeed))):
		return { "collision": true, "destination": result.position - anchor, "distance": from.distance_to(result.position), "point": result.position, "normal": result.normal, "collider": result.collider }
	
	return { "collision": false, "destination": Vector2.ZERO, "distance": 99999, "point": anchor, "normal": Vector2.ZERO, "collider": null }
