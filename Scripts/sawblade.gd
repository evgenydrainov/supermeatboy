extends StaticBody2D

func _ready():
	var anim_player = $AnimationPlayer
	anim_player.playback_speed = rand_range(1, 1.5)
	if rand_range(0, 1) > 0.5:
		anim_player.playback_speed = -anim_player.playback_speed
