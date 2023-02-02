extends Label

onready var player = get_node("/root/Node2D/Player")

func _physics_process(delta):
	text =\
		"state "+ String(player.state) +\
		"\nvelocity " + String(player.velocity) +\
		"\nmove_dir " + String(player.move_dir) +\
		"\njump buffer " + String(player.jump_buffer) +\
		"\ncoyote timer " + String(player.coyote_timer)
