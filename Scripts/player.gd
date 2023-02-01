extends KinematicBody2D

const RUN_MAX_SPEED = 500
const RUN_ACC = 800
const JUMP_SPEED = 300
const GRAVITY = 400
const JUMP_RELEASE = 50
const WALL_JUMP = 300
const TURN_ACC = 1500

var velocity = Vector2()
var facing = 1
var wall_timer = 0

onready var camera = get_node("/root/Node2D/Camera2D")
onready var label = get_node("/root/Node2D/Camera2D/Label")

func _physics_process(delta):
	var move = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	if is_on_floor():
		if sign(velocity.x) != move:
			velocity.x = 0
		
		velocity.x += RUN_ACC * move * delta
		velocity.x = clamp(velocity.x, -RUN_MAX_SPEED, RUN_MAX_SPEED)
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = -JUMP_SPEED
		
		wall_timer = 0
	elif is_on_wall():
		if move == -facing:
			wall_timer += delta
		else:
			wall_timer = 0
		
		if wall_timer < 0.25:
			velocity.x = facing
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = -JUMP_SPEED
			velocity.x = WALL_JUMP * -facing
	else:
		if move == -facing:
			velocity.x += TURN_ACC * move * delta
		else:
			velocity.x += RUN_ACC * move * delta
		velocity.x = clamp(velocity.x, -RUN_MAX_SPEED, RUN_MAX_SPEED)
		
		wall_timer = 0
	
	if !Input.is_action_pressed("jump"):
		velocity.y = max(velocity.y, -JUMP_RELEASE)
	
	if sign(velocity.x) != 0:
		facing = sign(velocity.x)
	
	if velocity.y > 0:
		velocity.y += 2 * GRAVITY * delta
	else:
		velocity.y += GRAVITY * delta
	
	velocity = move_and_slide_with_snap(velocity, Vector2.ZERO, Vector2.UP)
	
	camera.position = position
	
	label.text =\
		"velocity " + String(velocity) +\
		"\nfacing " + String(facing) +\
		"\nwall timer " + String(wall_timer) +\
		"\nmove " + String(move) +\
		"\nis on floor " + String(is_on_floor()) +\
		"\nis on wall " + String(is_on_wall()) +\
		"\ndelta " + String(delta)
