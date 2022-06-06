extends Label


# Declare member variables here. Examples:
const DEFAULT_MSG = "Please select an audio file to access the \"Edit\" tab."
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func report_status(err: int):
	if err != OK:
		add_color_override("font_color", Color(1.0, 0.5, 0.5))
		text = "Error loading audio: error code = %s" % err
	else:
		add_color_override("font_color", Color(0.5, 1.0, 0.5))
		text = "Audio successfully loaded from file! You can now edit the chart in the Edit tab."

func reset_status():
	add_color_override("font_color", Color(1.0, 1.0, 1.0))
	text = DEFAULT_MSG
