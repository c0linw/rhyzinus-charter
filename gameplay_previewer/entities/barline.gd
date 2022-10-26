extends Spatial

var time: float
var chart_position: float


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	translation = Vector3(0,-0.01,-lane_depth*(chart_position-song_chart_position)/base_note_screen_time)
