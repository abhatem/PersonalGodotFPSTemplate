#script basedo n https://www.youtube.com/watch?v=A3HLeyaBCq4
extends CharacterBody3D

var speed 
const SPEED_WALK = 5.0
const SPEED_SPRINT = 8.0
const JUMP_VELOCITY = 5
const SENSITIVITY = 0.002


#bob variables 
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0

# we change FOV based on speed
const BASE_FOV = 75.0
const FOV_CHANGE = 0.75 # multiplied by speed and added to base fov

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var footstep_audio = $Footstep
@onready var running_audio = $Running


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_window().size = Vector2i(1024, 768)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))
		

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint
	if Input.is_action_pressed("sprint"):
		speed = SPEED_SPRINT
	else:
		speed = SPEED_WALK
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var cam_look = Input.get_axis("look", "right")
	
	var direction = (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction: # if direction is not 0
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# inertia before stoping
			velocity.x = lerp(velocity.x, 0.0, delta * 8.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 8.0)
	else:
		# inertia while in air
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	
	# headbob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# footsteps 
	if is_on_floor() and direction.length() != 0 and not footstep_audio.playing and not running_audio.playing:
		if not Input.is_action_pressed("sprint"):
			footstep_audio.play()
		else:
			running_audio.play()
		
	if Input.is_action_just_released("sprint"):
		running_audio.stop()
		
	if not is_on_floor():
		running_audio.stop()
		footstep_audio.stop()
		
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED_SPRINT * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
