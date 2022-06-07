extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_SongAudioPlayer_song_position_updated(new_position, max_position):
	var new_whole = int(new_position)
	var new_decimal = str(new_position - new_whole).trim_prefix("0.").left(3)
	
	var max_whole = int(max_position)
	var max_decimal = str(max_position - max_whole).trim_prefix("0.").left(3)
	text = "%s:%02d.%s / %s:%02d.%s" % [new_whole/60, new_whole%60, new_decimal, max_whole/60, max_whole%60, max_decimal]
