extends Node2D

onready var player : Node2D = $"../Player"

var cameraX : float
var cameraY : float

var lagTimer : float
var shakeTimer : float
var lookUpTimer : float
var crouchDownTimer : float

var shiftX : float
var shiftY : float
var finalShiftX : float
var finalShiftY : float

export var minX : float
export var minY : float
export var maxX : float
export var maxY : float

export var marginL : float = -16
export var marginR : float = 0
export var marginT : float = -48
export var marginB : float = 16

var groundOld : bool
var groundOffset : float

var windowHalfWidth : int = 212
var windowHalfHeight : int = 120

func _ready() -> void:
	cameraX = player.xPosition
	cameraY = player.yPosition

func _physics_process(delta : float) -> void:
	var deltaFrame = 60 * delta
	
	if player.ground:
		if player.ground != groundOld:
			groundOffset = cameraY - player.yPosition
		
		if groundOffset > 0:
			groundOffset = max(groundOffset - (3 * deltaFrame), 0)
		elif groundOffset < 0:
			groundOffset = min(groundOffset + (3 * deltaFrame), 0)
		
		cameraY = clamp(player.yPosition + groundOffset, minY + windowHalfHeight, maxY - windowHalfHeight)
	
	if lagTimer <= 0:
		if player.xPosition < cameraX + marginL and cameraX > minX + windowHalfWidth:
			cameraX += max(-16 * deltaFrame, (player.xPosition - marginL) - cameraX)
		
		if player.xPosition > cameraX + marginR and cameraX < maxX - windowHalfWidth:
			cameraX += min(16 * deltaFrame, (player.xPosition - marginR) - cameraX)
	
	if not player.ground:
		if player.yPosition < cameraY + marginT and cameraY > minY + windowHalfHeight:
			cameraY += max(-16 * deltaFrame, (player.yPosition - marginT) - cameraY)
		
		if player.yPosition > cameraY + marginB and cameraY < maxY - windowHalfHeight:
			cameraY += min(16 * deltaFrame, (player.yPosition - marginB) - cameraY)
	
	if lagTimer <= 0:
		if player.action == 2:
			lookUpTimer = min(lookUpTimer + deltaFrame, 120)
		else:
			lookUpTimer = 0
		
		if player.action == 3:
			crouchDownTimer = min(crouchDownTimer + deltaFrame, 120)
		else:
			crouchDownTimer = 0
		
		if lookUpTimer >= 120:
			shiftY = max(shiftY - (2 * deltaFrame), -96)
		
		if crouchDownTimer >= 120:
			shiftY = min(shiftY + (2 * deltaFrame), 96)
		
		if lookUpTimer < 120 and crouchDownTimer < 120:
			shiftY = max(abs(shiftY) - (2 * deltaFrame), 0) * sign(shiftY)
		
		if player.ground:
			if abs(player.groundSpeed) >= 6:
				shiftX = min(abs(shiftX) + (3 * deltaFrame), 85) * sign(player.groundSpeed)
			elif player.action == 5:
				shiftX = min(abs(shiftX) + (2.5 * deltaFrame), 85) * player.direction
			else:
				shiftX = max(abs(shiftX) - (3 * deltaFrame), 0) * sign(shiftX)
		else:
			shiftX = max(abs(shiftX) - (3 * deltaFrame), 0) * sign(shiftX)
	
	if cameraX < minX + windowHalfWidth:
		cameraX = min(cameraX + (2 * deltaFrame), minX + windowHalfWidth)
	
	if cameraX > maxX - windowHalfWidth:
		cameraX = max(cameraX - (2 * deltaFrame), maxX - windowHalfWidth)
	
	if cameraY < minY + windowHalfHeight:
		cameraY = min(cameraY + (2 * deltaFrame), minY + windowHalfHeight)
	
	if cameraY > maxY - windowHalfHeight:
		cameraY = max(cameraY - (2 * deltaFrame), maxY - windowHalfHeight)
	
	finalShiftX = shiftX
	
	if cameraX <= minX + windowHalfWidth - shiftX:
		finalShiftX = clamp(minX + windowHalfWidth - cameraX, shiftX, 0)
	
	if cameraX >= maxX - windowHalfWidth - shiftX:
		finalShiftX = clamp(maxX - windowHalfWidth - cameraX, 0, shiftX)
	
	if finalShiftX > 0:
		finalShiftX = clamp(finalShiftX - (cameraX - player.xPosition), 0, finalShiftX)
	
	if finalShiftX < 0:
		finalShiftX = clamp(finalShiftX - (cameraX - player.xPosition), finalShiftX, 0)
	
	finalShiftY = shiftY
	
	if cameraY <= minY + windowHalfHeight - shiftY:
		finalShiftY = clamp(minY + windowHalfHeight - cameraY, shiftY, 0)
	
	if cameraY >= maxY - windowHalfHeight - shiftY:
		finalShiftY = clamp(minY + windowHalfHeight - cameraY, 0, shiftY)
	
	if finalShiftY > 0:
		finalShiftY = clamp(finalShiftY - (cameraY - player.yPosition), 0, finalShiftY)
	
	if finalShiftY < 0:
		finalShiftY = clamp(finalShiftY - (cameraY - player.yPosition), finalShiftY, 0)
	
	lagTimer = max(lagTimer - deltaFrame, 0)
	call_deferred("_render")
	
	groundOld = player.ground

func _render() -> void:
	global_position.x = cameraX + finalShiftX
	global_position.y = cameraY + finalShiftY
