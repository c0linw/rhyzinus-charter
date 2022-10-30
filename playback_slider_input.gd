extends HSlider


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal playhead_scrub(percentage)
signal preview_playhead_scrub(percentage)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_PlaybackSliderInput_value_changed(value):
	emit_signal("playhead_scrub", value/max_value)


func _on_PreviewPlaybackSliderInput_value_changed(value):
	# this gets handled by the main game node to avoid any fuckery caused by signal ordering
	emit_signal("preview_playhead_scrub", value/max_value)
