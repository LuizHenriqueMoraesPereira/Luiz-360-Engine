extends Node2D

var xPosition : float
var yPosition : float
var xSpeed : float
var ySpeed : float
var ground : bool
var groundSpeed : float
var groundAngle : float
var visualAngle : float
var controlLock : float
var jumpVariable : bool
var direction : int
var skidding : float
var spindash : float
var action : int
var layer : int

var animation : String
var animationFinished : bool

var allowInput : bool = true
var allowDirection : bool = true

onready var skin : AnimatedSprite = $Sprite
onready var hitBox : Area2D = $HitBox

export var widthRadius : float
export var heightRadius : float
export var wallOffset : float

export var acceleration : float = 0.046875
export var airAcceleration : float = 0.09375
export var deceleration : float = 0.5
export var friction : float = 0.046875
export var rollFriction : float = 0.0234375
export var rollDeceleration : float = 0.125
export var topSpeed : float = 6
export var slopeFactor : float = 0.125
export var slopeRollUpFactor : float = 0.078125
export var slopeRollDownFactor : float = 0.3125
export var gravityForce : float = 0.21875
export var jumpForce : float = 6.5
export var jumpReleaseForce : float = -4

export var sfxJump : AudioStream
export var sfxSkid : AudioStream
export var sfxCharge : AudioStream
export var sfxRelease : AudioStream
export var sfxRoll : AudioStream

var space : Physics2DDirectSpaceState

func _ready() -> void:
	xPosition = global_position.x
	yPosition = global_position.y
	direction = 1
	layer = 1
	
	space = get_world_2d().direct_space_state

func _physics_process(delta : float) -> void:
	var deltaFrame : float = 60 * delta
	var inputHorizontal : int = (1 if Input.is_action_pressed("Right") else 0) - (1 if Input.is_action_pressed("Left") else 0)
	var inputVertical : int = (1 if Input.is_action_pressed("Down") else 0) - (1 if Input.is_action_pressed("Up") else 0)
	
	if allowInput and ground and action != 6:
		groundSpeed -= slopeFactor * sin(deg2rad(groundAngle)) * deltaFrame
	
	if inputHorizontal < 0:
		if allowDirection: direction = -1
		
		if allowInput:
			if ground and controlLock <= 0:
				if groundSpeed > 0:
					groundSpeed -= deceleration * deltaFrame
					if groundSpeed <= 0:
						groundSpeed = -deceleration
				elif groundSpeed > -topSpeed:
					groundSpeed -= acceleration * deltaFrame
					if groundSpeed <= -topSpeed:
						groundSpeed = -topSpeed
			elif not ground:
				if xSpeed > -topSpeed:
					xSpeed -= airAcceleration * deltaFrame
					if xSpeed <= -topSpeed:
						xSpeed = -topSpeed
	
	if inputHorizontal > 0:
		if allowDirection: direction = 1
		
		if allowInput:
			if ground and controlLock <= 0:
				if groundSpeed < 0:
					groundSpeed += deceleration * deltaFrame
					if groundSpeed >= 0:
						groundSpeed = deceleration
				elif groundSpeed < topSpeed:
					groundSpeed += acceleration * deltaFrame
					if groundSpeed >= topSpeed:
						groundSpeed = topSpeed
			elif not ground:
				if xSpeed < topSpeed:
					xSpeed += airAcceleration * deltaFrame
					if xSpeed >= topSpeed:
						xSpeed = topSpeed
	
	if allowInput and ground and controlLock <= 0 and inputHorizontal == 0:
		groundSpeed -= min(abs(groundSpeed), friction) * sign(groundSpeed) * deltaFrame
		if abs(groundSpeed) < friction:
			groundSpeed = 0
	
	if not ground and ySpeed < 0 and ySpeed > -4:
		xSpeed -= ((floor(abs(xSpeed / 0.125)) * sign(xSpeed)) / 256) * deltaFrame
	
	if ground:
		xSpeed = groundSpeed * cos(deg2rad(groundAngle))
		ySpeed = groundSpeed * -sin(deg2rad(groundAngle))
	
	xPosition += xSpeed * deltaFrame
	yPosition += ySpeed * deltaFrame
	
	var steps = 1 + ceil(abs(sqrt((xSpeed * xSpeed) + (ySpeed * ySpeed))))
	while steps > 0:
		if (groundSpeed if ground else xSpeed) != 0:
			var dir = sign(groundSpeed if ground else xSpeed)
			var offset = wallOffset * (1 if (ground and fmod(round(groundAngle / 4), 90) == 0) else 0)
			var sensor = _sensor(Vector2(widthRadius * dir, offset), Vector2.RIGHT * dir)
			
			if sensor.collision:
				xPosition += sensor.destination.x
				yPosition += sensor.destination.y
				if ground: groundSpeed = 0
				else: xSpeed = 0
		
		if not ground and sign(ySpeed) != 0 or ground:
			var verticalLeft = _sensor(Vector2(-widthRadius + 2, heightRadius if ground else heightRadius * sign(ySpeed)), Vector2.DOWN if ground else Vector2.DOWN * sign(ySpeed), 16 if ground else 0)
			var verticalRight = _sensor(Vector2(widthRadius - 2, heightRadius if ground else heightRadius * sign(ySpeed)), Vector2.DOWN if ground else Vector2.DOWN * sign(ySpeed), 16 if ground else 0)
			var verticalCenter = _sensor(Vector2(0, heightRadius if ground else heightRadius * sign(ySpeed)), Vector2.DOWN if ground else Vector2.DOWN * sign(ySpeed), 16 if ground else 0)
			
			if verticalCenter.collision:
				if verticalLeft.collision or verticalRight.collision:
					if verticalCenter.distance > min(verticalLeft.distance, verticalRight.distance):
						if verticalRight.distance < verticalLeft.distance:
							xPosition += verticalRight.destination.x
							yPosition += verticalRight.destination.y
						else:
							xPosition += verticalLeft.destination.x
							yPosition += verticalLeft.destination.y
					else:
						xPosition += verticalCenter.destination.x
						yPosition += verticalCenter.destination.y
				else:
					xPosition += verticalCenter.destination.x
					yPosition += verticalCenter.destination.y
			elif verticalLeft.collision or verticalRight.collision:
				if verticalRight.distance < verticalLeft.distance:
					xPosition += verticalRight.destination.x
					yPosition += verticalRight.destination.y
				else:
					xPosition += verticalLeft.destination.x
					yPosition += verticalLeft.destination.y
			
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
						if groundAngle >= 22.5 and groundAngle < 45 or groundAngle > 315 and groundAngle <= 337.5:
							groundSpeed = ySpeed * 0.5 * -sign(sin(deg2rad(groundAngle)))
						elif groundAngle >= 45 and groundAngle <= 315:
							groundSpeed = ySpeed * -sign(sin(deg2rad(groundAngle)))
					ground = true
				else:
					if ySpeed < -1 and normal.y < 0.75:
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
	
	if ground:
		if abs(fmod(0 - groundAngle + 540, 360) - 180) >= 40:
			visualAngle += deg2rad((fmod(groundAngle - rad2deg(visualAngle) + 540, 360) - 180) * max(0.165, abs(groundSpeed) / 16))
		else:
			visualAngle += deg2rad((fmod(0 - rad2deg(visualAngle) + 540, 360) - 180) * max(0.165, abs(groundSpeed) / 16))
		
		visualAngle = deg2rad(fmod(720 + rad2deg(visualAngle), 360))
	else:
		if rad2deg(visualAngle) < 180:
			visualAngle = deg2rad(max(rad2deg(visualAngle) - (4 * deltaFrame), 0))
		else:
			visualAngle = deg2rad(min(rad2deg(visualAngle) + (4 * deltaFrame), 360))
	
	if animation == "jump":
		visualAngle = 0
	
	if xPosition <= 16 and xSpeed < 0:
		xPosition = 16
		if ground: groundSpeed = max(0, groundSpeed)
		else: xSpeed = max(0, xSpeed)
	
	if not ground:
		ySpeed += gravityForce * deltaFrame
		if ySpeed > 16:
			ySpeed = 16
	
	if action != 5:
		spindash = 0
	
	match action:
		0:
			if ground:
				if abs(groundSpeed) <= 0:
					_play_animation("idle")
				elif abs(groundSpeed) < 4:
					_play_animation("walk")
				elif abs(groundSpeed) < 6:
					_play_animation("jog")
				elif abs(groundSpeed) < 12:
					_play_animation("run")
				else:
					_play_animation("dash", true)
			elif abs(groundSpeed) < 6:
				_play_animation("air_walk")
			
			skin.speed_scale = 1 + (abs(groundSpeed) / 16)
			
			if ground and groundSpeed == 0:
				if inputVertical < 0:
					allowInput = false
					allowDirection = false
					action = 2
				if inputVertical > 0:
					allowInput = false
					allowDirection = false
					action = 3
			
			if ground and controlLock <= 0 and abs(groundSpeed) >= 4 and (groundSpeed > 0 and inputHorizontal < 0 or groundSpeed < 0 and inputHorizontal > 0) and not (groundAngle >= 45 and groundAngle <= 315):
				Audio._play_sample(sfxSkid)
				if inputHorizontal < 0: direction = 1
				if inputHorizontal > 0: direction = -1
				skidding = 20
				allowDirection = false
				action = 4
			
			if ground and Input.is_action_just_pressed("Jump"):
				Audio._play_sample(sfxJump)
				xSpeed -= jumpForce * sin(deg2rad(groundAngle))
				ySpeed -= jumpForce * cos(deg2rad(groundAngle))
				groundAngle = 0
				ground = false
				controlLock = 0
				jumpVariable = true
				action = 1
			
			if ground and inputHorizontal == 0 and inputVertical > 0 and abs(groundSpeed) >= 0.5:
				Audio._play_sample(sfxRoll)
				allowDirection = false
				allowInput = false
				action = 6
		1:
			_play_animation("jump")
			skin.speed_scale = 1 + (abs(groundSpeed) / 8)
			
			if jumpVariable and ySpeed < jumpReleaseForce and not Input.is_action_pressed("Jump"):
				ySpeed = jumpReleaseForce
			
			if ground:
				allowInput = true
				allowDirection = true
				action = 0
		2:
			if inputVertical < 0:
				if animation != "look_up":
					_play_animation("look_up")
			else:
				if animation != "look_up_r":
					_play_animation("look_up_r")
				elif animationFinished:
					allowInput = true
					allowDirection = true
					action = 0
			
			if not ground or groundSpeed != 0:
				allowInput = true
				allowDirection = true
				action = 0
		3:
			if inputVertical > 0:
				if animation != "crouch_down":
					_play_animation("crouch_down")
			else:
				if animation != "crouch_down_r":
					_play_animation("crouch_down_r")
				elif animationFinished:
					allowInput = true
					allowDirection = true
					action = 0
			
			if not ground or groundSpeed != 0:
				allowInput = true
				allowDirection = true
				action = 0
			
			if Input.is_action_just_pressed("Jump"):
				Audio._play_sample(sfxCharge)
				allowDirection = false
				allowInput = false
				action = 5
		4:
			skin.speed_scale = 1
			
			if skidding > 0:
				skidding -= deltaFrame
			elif inputHorizontal <= 0 and groundSpeed < 0 or inputHorizontal >= 0 and groundSpeed > 0:
				allowDirection = true
				action = 0
			
			if not ground:
				_play_animation("air_walk")
				allowDirection = true
				action = 0
			
			if animation != "skid_turn":
				_play_animation("skid", true)
				if animation == "skid_loop" and abs(groundSpeed) <= 1.5:
					direction *= -1
					_play_animation("skid_turn")
			elif animationFinished:
				allowDirection = true
				action = 0
			
			if ground and Input.is_action_just_pressed("Jump"):
				Audio._play_sample(sfxJump)
				xSpeed -= jumpForce * sin(deg2rad(groundAngle))
				ySpeed -= jumpForce * cos(deg2rad(groundAngle))
				groundAngle = 0
				ground = false
				controlLock = 0
				skidding = 0
				allowDirection = true
				jumpVariable = true
				action = 1
		5:
			_play_animation("spindash")
			skin.speed_scale = 1 + (spindash / 8)
			spindash -= (floor(spindash / 0.125) / 512) * deltaFrame
			
			if Input.is_action_just_pressed("Jump"):
				skin.frame = 0
				Audio._stop_sample(sfxCharge)
				Audio._play_sample(sfxCharge)
				spindash += 2
			
			if inputVertical <= 0:
				Audio._stop_sample(sfxCharge)
				Audio._play_sample(sfxRelease)
				groundSpeed = (8 + floor(spindash / 2)) * direction
				action = 6
		6:
			_play_animation("jump")
			skin.speed_scale = 1 + (abs(groundSpeed) / 8)
			
			if inputHorizontal < 0:
				if groundSpeed > 0:
					groundSpeed -= rollDeceleration * deltaFrame
					if groundSpeed <= 0:
						groundSpeed = -rollDeceleration
				else:
					groundSpeed -= min(abs(groundSpeed), rollFriction) * sign(groundSpeed) * deltaFrame
			
			if inputHorizontal > 0:
				if groundSpeed < 0:
					groundSpeed += rollDeceleration * deltaFrame
					if groundSpeed >= 0:
						groundSpeed = rollDeceleration
				else:
					groundSpeed -= min(abs(groundSpeed), rollFriction) * sign(groundSpeed) * deltaFrame
			
			if inputHorizontal == 0:
				groundSpeed -= min(abs(groundSpeed), rollFriction) * sign(groundSpeed) * deltaFrame
				if abs(groundSpeed) < rollFriction:
					groundSpeed = 0
			
			if ground:
				if sign(groundSpeed) == sign(sin(deg2rad(groundAngle))):
					groundSpeed -= slopeRollUpFactor * sin(deg2rad(groundAngle)) * deltaFrame
				else:
					groundSpeed -= slopeRollDownFactor * sin(deg2rad(groundAngle)) * deltaFrame
			else:
				allowDirection = true
				allowInput = true
				jumpVariable = false
				action = 1
			
			if ground and Input.is_action_just_pressed("Jump"):
				Audio._play_sample(sfxJump)
				xSpeed -= jumpForce * sin(deg2rad(groundAngle))
				ySpeed -= jumpForce * cos(deg2rad(groundAngle))
				groundAngle = 0
				ground = false
				controlLock = 0
				skidding = 0
				allowInput = true
				allowDirection = true
				jumpVariable = true
				action = 1
			
			if ground and abs(groundSpeed) < rollDeceleration:
				allowDirection = true
				allowInput = true
				action = 0
	
	if ground:
		if controlLock <= 0:
			if abs(groundSpeed) < 2.5 and groundAngle >= 35 and groundAngle <= 325:
				controlLock = 30
				
				if groundAngle >= 75 and groundAngle <= 285:
					xSpeed = groundSpeed * cos(deg2rad(groundAngle))
					ySpeed = groundSpeed * -sin(deg2rad(groundAngle))
					groundAngle = 0
					ground = false
				else:
					if groundAngle < 180:
						groundSpeed -= deceleration
					else:
						groundSpeed += deceleration
		else:
			controlLock -= deltaFrame
	
	if skin.animation != animation:
		skin.play(animation)
		animationFinished = false
	call_deferred("_render")

func _render() -> void:
	global_position.x = xPosition
	global_position.y = yPosition
	hitBox.global_rotation_degrees = -groundAngle
	skin.global_rotation = -visualAngle
	skin.flip_h = direction < 0

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
	
	var result = space.intersect_ray(from, to, [], layer)
	if result and (result.collider.is_in_group("Solid") or not (result.collider.is_in_group("Solid") or result.collider.is_in_group("Platform")) or result.collider.is_in_group("Platform") and result.collider.global_position.y >= yPosition + (heightRadius - max(4, ySpeed))):
		return { "collision": true, "destination": result.position - anchor, "distance": from.distance_to(result.position), "point": result.position, "normal": result.normal }
	
	return { "collision": false, "destination": Vector2.ZERO, "distance": 99999, "point": anchor, "normal": Vector2.ZERO }

func _on_area_entered(area : Area2D) -> void:
	if "entities" in area:
		area.entities.append(self)

func _on_area_exited(area : Area2D) -> void:
	if "entities" in area:
		area.entities.erase(self)

func _on_animation_finished() -> void:
	animationFinished = true

func _play_animation(animationName : String, loop : bool = false) -> void:
	if animation != animationName + "_loop":
		if animation != animationName:
			animation = animationName
		elif animationFinished and loop:
			animation = animationName + "_loop"
