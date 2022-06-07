extends HSlider

signal playback_scrub(percentage)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_SongAudioPlayer_song_position_updated(new_position, max_position):
	value = max_value * new_position/max_position
