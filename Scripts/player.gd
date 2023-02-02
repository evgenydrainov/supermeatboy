extends KinematicBody2D

const RUN_MAX_SPEED = 600
const WALK_MAX_SPEED = 400
const RUN_ACC = 1400
const WALK_ACC = 1000
const RUN_TURN_ACC = 3000
const WALK_TURN_ACC = 2700

const JUMP_SPEED = 375
const WALL_JUMP_SPEED = 425
const WALL_JUMP_RUN_RECOIL = 500
const WALL_JUMP_WALK_RECOIL = 400
const GRAVITY = 600
const WALL_GRAVITY = 400
const JUMP_RELEASE = 50

const JUMP_BUFFER = 0.02 # 0.1
const COYOTE_TIME = 0.02 # 0.1

var velocity = Vector2()
var facing = 1
var wall_timer = 0
var state = IN_AIR
var move_dir = 0
var jump_buffer = 0
var coyote_timer = 0
var running = false

onready var camera = get_node("/root/Node2D/Camera2D")

enum {ON_GROUND, ON_WALL, IN_AIR}

func _process(delta):
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

func _physics_process(delta):
	move_dir = 0
	if Input.is_action_pressed("right"):
		move_dir += 1
	if Input.is_action_pressed("left"):
		move_dir -= 1
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER
	
	running = Input.is_action_pressed("run")
	
	match state:
		ON_GROUND:
			state_on_ground(delta)
		ON_WALL:
			state_on_wall(delta)
		IN_AIR:
			state_in_air(delta)
	
	if sign(velocity.x) != 0:
		facing = sign(velocity.x)
	
	jump_buffer = max(jump_buffer - delta, 0)
	
	var collision = get_last_slide_collision()
	if collision is KinematicCollision2D:
		var collider = collision.collider
		if collider.is_in_group("sawblade"):
			get_tree().reload_current_scene()
		elif collider.is_in_group("bandagegirl"):
			Global.level_index += 1
			Global.level_index %= len(Global.level_list)
			get_tree().change_scene(Global.level_list[Global.level_index])
			print("Global.level_index ", Global.level_index)

func state_on_ground(delta):
	wall_timer = 0
	
	accelerate(delta)
	
	if sign(velocity.x) != move_dir:
		velocity.x = 0
	
	if jump_buffer > 0:
		state = IN_AIR
		velocity.y = -JUMP_SPEED
		move(delta)
		jump_buffer = 0
		return
	
	apply_gravity(delta)
	
	move(delta)
	
	if !is_on_floor():
		state = IN_AIR
		coyote_timer = COYOTE_TIME
		return

func state_on_wall(delta):
	if move_dir == -facing:
		wall_timer += delta
	else:
		wall_timer = 0
	
	velocity.x = 100 * facing
	
	if jump_buffer > 0:
		velocity.y = -WALL_JUMP_SPEED
		velocity.x = (WALL_JUMP_RUN_RECOIL if running else WALL_JUMP_WALK_RECOIL) * -facing
		state = IN_AIR
		move(delta)
		jump_buffer = 0
		return
	
	jump_release()
	apply_gravity(delta, true)
	
	move(delta)
	
	if !is_on_wall() || wall_timer >= 0.25:
		state = IN_AIR
		velocity.x = 0
		return
	
	if is_on_floor():
		state = ON_GROUND
		velocity.x = 0
		return

func state_in_air(delta):
	wall_timer = 0
	
	accelerate(delta)
	
	if coyote_timer > 0:
		if jump_buffer > 0:
			velocity.y = -JUMP_SPEED
			jump_buffer = 0
			coyote_timer = 0
	
	coyote_timer = max(coyote_timer - delta, 0)
	
	jump_release()
	apply_gravity(delta)
	
	move(delta)
	
	if is_on_floor():
		state = ON_GROUND
		velocity.y = 0
		return
	
	if is_on_wall():
		state = ON_WALL
		return

func move(delta):
	velocity = move_and_slide_with_snap(velocity, Vector2.ZERO, Vector2.UP, true)

func jump_release():
	if !Input.is_action_pressed("jump"):
		velocity.y = max(velocity.y, -JUMP_RELEASE)

func apply_gravity(delta, wall = false):
	var grv = WALL_GRAVITY if wall else GRAVITY
	if velocity.y > 0:
		velocity.y += 2 * grv * delta
	else:
		velocity.y += grv * delta

func accelerate(delta):
	var acc = RUN_ACC if running else WALK_ACC
	var max_speed = RUN_MAX_SPEED if running else WALK_MAX_SPEED
	
	if move_dir == -facing:
		acc = RUN_TURN_ACC if running else WALK_TURN_ACC
	
	velocity.x += acc * move_dir * delta
	velocity.x = clamp(velocity.x, -max_speed, max_speed)
