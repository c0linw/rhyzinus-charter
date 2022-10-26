extends Spatial

var time: float
var chart_position: float

var offset: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	translation = Vector3(translation.x,translation.y,-lane_depth*(chart_position-song_chart_position)/base_note_screen_time)

func set_ends(lower: int, upper: int, lower_translation: Vector3, upper_translation: Vector3):
	# lower and upper are the index numbers of the lanes.
	# in world space, lower lanes' x coordinates range from 0 to 6. The center of each lane is at 0.5 offset from the edges of the lane.
	var lower_point: Vector3 = Vector3(lower - 0.5, 0, 0) + lower_translation
	# in world space, upper lanes' x coordinates range from 0.5 to 5.5. The center of each lane is at 0.625 offset from the edges.
	var upper_point: Vector3 = Vector3((upper - 10) * 1.25 + 0.625, 0, 0) + upper_translation
	look_at_from_position(lower_point + (upper_point - lower_point)/2, upper_point, Vector3.UP)
	scale.y = abs(lower_point.distance_to(upper_point))
	translation -= lower_translation
	rotation.x -= PI/2
