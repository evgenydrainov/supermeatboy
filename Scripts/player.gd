extends KinematicBody2D

const MAX_RUN_SPEED_AIR = 630
const MAX_RUN_SPEED_GROUND = 570
const MAX_WALK_SPEED_AIR = 400
const MAX_WALK_SPEED_GROUND = 400
const RUN_ACC = 1600
const WALK_ACC = 1000
const RUN_TURN_ACC = 3200
const WALK_TURN_ACC = 2700

const JUMP_SPEED = 390
const WALL_JUMP_SPEED = 440
const GRAVITY = 600
const WALL_GRAVITY = 400
const JUMP_RELEASE = 50

const WALL_JUMP_RECOIL_RUN = 500
const WALL_JUMP_RECOIL_WALK = 400

const JUMP_BUFFER = 0.02 # 0.1
const COYOTE_TIME = 0.02 # 0.1

var velocity = Vector2()
var facing = 1
var wall_timer = 0
var state = IN_AIR
var move = 0
var jump_buffer = 0
var coyote_timer = 0
var running = false

onready var camera = $"/root/Node2D/Camera2D"

enum {ON_GROUND, ON_WALL, IN_AIR}

func _process(delta):
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()


func _physics_process(delta):
	move = 0
	if Input.is_action_pressed("right"):
		move += 1
	if Input.is_action_pressed("left"):
		move -= 1
	
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
	
	for i in get_slide_count():
		var collider = get_slide_collision(i).collider
		if collider.is_in_group("sawblade"):
			get_tree().reload_current_scene()
		elif collider.is_in_group("bandagegirl"):
			Global.level_index += 1
			Global.level_index %= len(Global.level_list)
			get_tree().change_scene(Global.level_list[Global.level_index])
			print("Global.level_index ", Global.level_index)
			return
#			var msg = "i " + String(i) + " in ["
#			for j in get_slide_count():
#				msg += get_slide_collision(i).collider.to_string() + ","
#			msg += "]"
#			print(msg)


func state_on_ground(delta):
	wall_timer = 0
	
	accelerate(delta)
	
	if sign(velocity.x) != move:
		velocity.x = 0
	
	if jump_buffer > 0:
		state = IN_AIR
		velocity.y = -JUMP_SPEED
		my_move(delta)
		jump_buffer = 0
		return
	
	apply_gravity(delta)
	
	my_move(delta)
	
	if !is_on_floor():
		state = IN_AIR
		coyote_timer = COYOTE_TIME
		return


func state_on_wall(delta):
	if move == -facing:
		wall_timer += delta
	else:
		wall_timer = 0
	
	velocity.x = 100 * facing
	
	if jump_buffer > 0:
		velocity.y = -WALL_JUMP_SPEED
		if move == facing:
			velocity.x = (WALL_JUMP_RECOIL_RUN if running else WALL_JUMP_RECOIL_WALK) * -facing
		else:
			velocity.x = (MAX_RUN_SPEED_AIR if running else MAX_WALK_SPEED_AIR) * -facing
		state = IN_AIR
		my_move(delta)
		jump_buffer = 0
		return
	
	jump_release()
	apply_gravity(delta)
	
	my_move(delta)
	
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
	
	my_move(delta)
	
	if is_on_floor():
		state = ON_GROUND
		velocity.y = 0
		return
	
	if is_on_wall():
		if move != -facing:
			state = ON_WALL
			return


func my_move(delta):
	velocity = move_and_slide_with_snap(velocity, Vector2.ZERO, Vector2.UP, true)


func jump_release():
	if !Input.is_action_pressed("jump"):
		velocity.y = max(velocity.y, -JUMP_RELEASE)


func apply_gravity(delta):
	var grv = WALL_GRAVITY if state == ON_WALL else GRAVITY
	if velocity.y > 0:
		velocity.y += 2 * grv * delta
	else:
		velocity.y += grv * delta


func accelerate(delta):
	var acc = RUN_ACC if running else WALK_ACC
	var max_speed = MAX_RUN_SPEED_GROUND if running else MAX_WALK_SPEED_GROUND
	
	if state == IN_AIR:
		max_speed = MAX_RUN_SPEED_AIR if running else MAX_WALK_SPEED_AIR
	
	if move == -facing:
		acc = RUN_TURN_ACC if running else WALK_TURN_ACC
	
	velocity.x += acc * move * delta
	velocity.x = clamp(velocity.x, -max_speed, max_speed)
