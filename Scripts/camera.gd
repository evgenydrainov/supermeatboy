extends Camera2D

var min_pos = Vector2()
var max_pos = Vector2()

onready var player = $"/root/Node2D/Player"
onready var screen_size = get_viewport_rect().size

func _ready():
	var bounds = $"/root/Node2D/LevelBounds"
	var pos = bounds.position
	var extents = bounds.get_node("CollisionShape2D").shape.extents
	
	min_pos = pos - extents + screen_size / 2
	max_pos = pos + extents - screen_size / 2

func _physics_process(delta):
	var camera_follow_speed = 0.5
	position = lerp(position, player.position, 1 - pow(1 - camera_follow_speed, delta * 60))
	
	if position.x > max_pos.x:
		position.x = max_pos.x
	if position.x < min_pos.x:
		position.x = min_pos.x
	
	if position.y > max_pos.y:
		position.y = max_pos.y
	if position.y < min_pos.y:
		position.y = min_pos.y
