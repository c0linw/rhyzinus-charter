extends HSlider


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal playhead_scrub(percentage)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_PlaybackSliderInput_value_changed(value):
	emit_signal("playhead_scrub", value/max_value)
