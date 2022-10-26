extends Note3D
class_name NoteTapUpper3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	if lane > 9:
		translation = Vector3((lane-10)*1.25+0.625,0,-lane_depth*(chart_position-song_chart_position)/base_note_screen_time)
