class_name Player extends Entity

var allowInput : bool = true
var allowDirection : bool = true
var animation : String = "none"
var animationFinished : bool = false

var camera : CameraController
var controlLock : float
var direction : int
var action : int
var jumpVariable : bool
var skidding : float
var spindash : float

onready var skin := $Sprite
onready var hitBox := $CharacterBox

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

func _ready() -> void:
	camera = Global._find_node("CameraController")
	
	._ready()
	
	direction = 1

func _physics_process(delta : float) -> void:
	var deltaTime = 60 * delta
	var inputHorizontal = (1 if Input.is_action_pressed("Right") else 0) - (1 if Input.is_action_pressed("Left") else 0)
	var inputVertical = (1 if Input.is_action_pressed("Down") else 0) - (1 if Input.is_action_pressed("Up") else 0)
	
	if allowInput and ground and action != 6:
		groundSpeed -= slopeFactor * sin(deg2rad(groundAngle)) * deltaTime
	
	if inputHorizontal < 0:
		if allowDirection: direction = -1
		
		if allowInput:
			if ground and controlLock <= 0:
				if groundSpeed > 0:
					groundSpeed -= deceleration * deltaTime
					if groundSpeed <= 0:
						groundSpeed = -deceleration
				elif groundSpeed > -topSpeed:
					groundSpeed -= acceleration * deltaTime
					if groundSpeed <= -topSpeed:
						groundSpeed = -topSpeed
			elif not ground:
				if xSpeed > -topSpeed:
					xSpeed -= airAcceleration * deltaTime
					if xSpeed <= -topSpeed:
						xSpeed = -topSpeed
	
	if inputHorizontal > 0:
		if allowDirection: direction = 1
		
		if allowInput:
			if ground and controlLock <= 0:
				if groundSpeed < 0:
					groundSpeed += deceleration * deltaTime
					if groundSpeed >= 0:
						groundSpeed = deceleration
				elif groundSpeed < topSpeed:
					groundSpeed += acceleration * deltaTime
					if groundSpeed >= topSpeed:
						groundSpeed = topSpeed
			elif not ground:
				if xSpeed < topSpeed:
					xSpeed += airAcceleration * deltaTime
					if xSpeed >= topSpeed:
						xSpeed = topSpeed
	
	if allowInput and ground and controlLock <= 0 and inputHorizontal == 0:
		groundSpeed -= min(abs(groundSpeed), friction) * sign(groundSpeed) * deltaTime
		if abs(groundSpeed) < friction:
			groundSpeed = 0
	
	if not ground and ySpeed < 0 and ySpeed > -4:
		xSpeed -= ((floor(abs(xSpeed / 0.125)) * sign(xSpeed)) / 256) * deltaTime
	
	_movement_process(deltaTime)
	
	if ground:
		if abs(fmod(0 - groundAngle + 540, 360) - 180) >= 40:
			visualAngle += deg2rad((fmod(groundAngle - rad2deg(visualAngle) + 540, 360) - 180) * max(0.165, abs(groundSpeed) / 16))
		else:
			visualAngle += deg2rad((fmod(0 - rad2deg(visualAngle) + 540, 360) - 180) * max(0.165, abs(groundSpeed) / 16))
		
		visualAngle = deg2rad(fmod(720 + rad2deg(visualAngle), 360))
	else:
		if rad2deg(visualAngle) < 180:
			visualAngle = deg2rad(max(rad2deg(visualAngle) - (4 * deltaTime), 0))
		else:
			visualAngle = deg2rad(min(rad2deg(visualAngle) + (4 * deltaTime), 360))
	
	if animation == "jump":
		visualAngle = 0
	
	if xPosition <= camera.minX + 16 and xSpeed < 0:
		xPosition = camera.minX + 16
		if ground: groundSpeed = max(0, groundSpeed)
		else: xSpeed = max(0, xSpeed)
	
	if xPosition >= camera.maxX - 16 and xSpeed > 0:
		xPosition = camera.maxX - 16
		if ground: groundSpeed = min(0, groundSpeed)
		else: xSpeed = min(0, xSpeed)
	
	if not ground:
		ySpeed += gravityForce * deltaTime
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
				skidding -= deltaTime
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
			spindash -= (floor(spindash / 0.125) / 512) * deltaTime
			
			if Input.is_action_just_pressed("Jump"):
				skin.frame = 0
				Audio._stop_sample(sfxCharge)
				Audio._play_sample(sfxCharge)
				spindash += 2
				Audio._set_sample_pitch(sfxCharge, 1 + (spindash * 0.03))
			
			if inputVertical <= 0:
				Audio._stop_sample(sfxCharge)
				Audio._play_sample(sfxRelease)
				groundSpeed = (8 + floor(spindash / 2)) * direction
				camera.lagTimer = 16
				action = 6
		6:
			_play_animation("jump")
			skin.speed_scale = 1 + (abs(groundSpeed) / 8)
			
			if inputHorizontal < 0:
				if groundSpeed > 0:
					groundSpeed -= rollDeceleration * deltaTime
					if groundSpeed <= 0:
						groundSpeed = -rollDeceleration
				else:
					groundSpeed -= min(abs(groundSpeed), rollFriction) * sign(groundSpeed) * deltaTime
			
			if inputHorizontal > 0:
				if groundSpeed < 0:
					groundSpeed += rollDeceleration * deltaTime
					if groundSpeed >= 0:
						groundSpeed = rollDeceleration
				else:
					groundSpeed -= min(abs(groundSpeed), rollFriction) * sign(groundSpeed) * deltaTime
			
			if inputHorizontal == 0:
				groundSpeed -= min(abs(groundSpeed), rollFriction) * sign(groundSpeed) * deltaTime
				if abs(groundSpeed) < rollFriction:
					groundSpeed = 0
			
			if ground:
				if sign(groundSpeed) == sign(sin(deg2rad(groundAngle))):
					groundSpeed -= slopeRollUpFactor * sin(deg2rad(groundAngle)) * deltaTime
				else:
					groundSpeed -= slopeRollDownFactor * sin(deg2rad(groundAngle)) * deltaTime
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
			controlLock -= deltaTime
	
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

func _on_animation_finished() -> void:
	animationFinished = true

func _play_animation(animationName : String, loop : bool = false) -> void:
	if animation != animationName + "_loop":
		if animation != animationName:
			animation = animationName
		elif animationFinished and loop:
			animation = animationName + "_loop"
