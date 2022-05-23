extends AudioStreamPlayer


var song_position: float = 0.0


# Called when the node enters the scene tree for the first time.
#func _ready():
	#stream = load("res://songs/neutralizeptbmix/audio.mp3")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_song_position()

func update_song_position():
	if playing:
		var new_position = get_playback_position() + AudioServer.get_time_since_last_mix()
		new_position -= AudioServer.get_output_latency()
		if new_position > song_position:
			song_position = new_position
