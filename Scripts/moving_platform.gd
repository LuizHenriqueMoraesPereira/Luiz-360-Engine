class_name MovingPlatform extends Entity

var xPrevious : float
var yPrevious : float
var xStart : float
var yStart : float
var xAngle : float
var yAngle : float
var sinkAmount : float

export var platformXSpeed : float
export var platformYSpeed : float
export var xDistance : float
export var yDistance : float

var player : Entity
var camera : CameraController

func _ready() -> void:
	player = Global._find_node("Player")
	camera = Global._find_node("CameraController")
	
	._ready()
	
	xStart = xPosition
	yStart = yPosition
	
	xSpeed = platformXSpeed
	ySpeed = platformYSpeed

func _physics_process(delta : float) -> void:
	var deltaFrame : float = 60 * delta
	
	xAngle += xSpeed * deltaFrame
	yAngle += ySpeed * deltaFrame
	
	xAngle = fmod(xAngle, 360)
	yAngle = fmod(yAngle, 360)
	
	xPosition = xStart + (cos(deg2rad(xAngle)) * xDistance)
	yPosition = yStart + ((sin(deg2rad(yAngle)) * yDistance) + floor(sin(deg2rad(sinkAmount)) * 10))
	
	xPrevious = global_position.x
	yPrevious = global_position.y
	global_position.x = xPosition
	global_position.y = yPosition
	
	if sinkAmount > 0:
		sinkAmount = max(0, sinkAmount - (6 * deltaFrame))
	
	if player != null and camera != null:
		if player.ground and player.colliderFloor == self:
			sinkAmount = min(90, sinkAmount + (9 * deltaFrame))
			
			player.xPosition += xPosition - xPrevious
			player.yPosition += yPosition - yPrevious
			player.global_position.x = player.xPosition
			player.global_position.y = player.yPosition
			
			camera.cameraX += xPosition - xPrevious
			camera.cameraY += yPosition - yPrevious
			camera.global_position.x = camera.cameraX
			camera.global_position.y = camera.cameraY
