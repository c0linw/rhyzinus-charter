extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$SongAudioPlayer.stream = load("res://songs/neutralizeptbmix/audio.mp3")
	find_node("Chart").update_chart_length($SongAudioPlayer.stream.get_length())


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
