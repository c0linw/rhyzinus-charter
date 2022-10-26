extends NoteHold3D
class_name NoteHoldUpper3D

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("holds")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	var head: float = chart_position
	var tail: float
	if lane > 9:
		if end_position <= song_chart_position + base_note_screen_time:
			tail = end_position
		else:
			tail = song_chart_position + base_note_screen_time
			
		if held:
			head = song_chart_position
			$Body.get_surface_material(0).albedo_color = Color(0.13,0.25,1,0.7)
		else:
			$Body.get_surface_material(0).albedo_color = Color(0.13,0.25,1,0.5)
		translation = Vector3((lane-10)*1.25+0.625,0,-lane_depth*(head-song_chart_position)/base_note_screen_time)
		$Body.scale = Vector3($Body.scale.x, $Body.scale.y, lane_depth*(tail - head)/base_note_screen_time)
		$Body.translation = Vector3(0,0,-$Body.scale.z/2.0)
