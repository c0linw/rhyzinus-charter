extends AudioStreamPlayer


var song_position: float = 0.0
var paused_position: float = 0.0

signal song_position_updated(new_position, max_position)

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
			emit_signal("song_position_updated", song_position, stream.get_length())

func play_with_parameters(from_position: float, speed: float):
	pitch_scale = speed
	play(from_position)
	
func stop():
	.stop()
	song_position = 0.0

func pause():
	.stop()
	
func unpause():
	play(paused_position)


func _on_Chart_custom_scroll(dir_multiplier):
	var new_position = song_position + 0.5*dir_multiplier
	seek(new_position)
	song_position = new_position
	emit_signal("song_position_updated", song_position, stream.get_length())


func _on_PlaybackSliderInput_playhead_scrub(percentage):
	var new_position = stream.get_length() * percentage
	seek(new_position)
	song_position = new_position
	emit_signal("song_position_updated", song_position, stream.get_length())
