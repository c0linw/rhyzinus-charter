extends Note3D
class_name NoteHold3D

var end_time: float
var end_position: float
var held: bool = false
var activated: bool = false
var head_judged: bool = false
var ticks: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("holds")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func can_judge(event_time: float):
	return event_time >= time-early_cracked and not activated
	
# returns either null, or a dict containing the judgement and offset
func judge(event_time: float):
	activated = true
	if head_judged:
		return null
	head_judged = true
	if event_time >= time-early_flawless && event_time <= time + late_flawless:
		return {"judgement": FLAWLESS, "offset": event_time - time}
	if event_time >= time-early_decrypted && event_time <= time + late_decrypted:
		return {"judgement": DECRYPTED, "offset": event_time - time}
	elif event_time >= time-early_cracked && event_time <= time + late_cracked:
		return {"judgement": CRACKED, "offset": event_time - time}
	else:
		return {"judgement": ENCRYPTED, "offset": 0}

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	var head: float = chart_position
	var tail: float
	if lane > 0 && lane < 7:
		if end_position <= song_chart_position + base_note_screen_time:
			tail = end_position
		else:
			tail = song_chart_position + base_note_screen_time
			
		if held:
			head = song_chart_position
			$Body.get_surface_material(0).albedo_color = Color(1,1,1,0.7)
		else:
			$Body.get_surface_material(0).albedo_color = Color(1,1,1,0.5)
		translation = Vector3(lane-0.5,0,-lane_depth*(head-song_chart_position)/base_note_screen_time)
		$Body.scale = Vector3($Body.scale.x, $Body.scale.y, lane_depth*(tail - head)/base_note_screen_time)
		$Body.translation = Vector3(0,0,-$Body.scale.z/2.0)
