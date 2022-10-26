extends Note3D
class_name NoteSwipe3D

const MAX_TOUCH_INPUTS: int = 20
const early_swipe: float = 0.150
const late_swipe: float = 0.150

# Declare member variables here. Examples:
var completed: bool = false
var touch_indices: Array = [] # activate and track valid swipes and their start positions here.

# Called when the node enters the scene tree for the first time.
func _ready():
	touch_indices.resize(MAX_TOUCH_INPUTS)
	for i in range(MAX_TOUCH_INPUTS):
		touch_indices[i] = {
			"activated": false,
			"start_position": null
		}
	add_to_group("swipes")


# returns either null, or a dict containing the judgement and offset
func judge(event_time: float):
	pass # swipe judgement is performed in game.gd's process() instead

func can_judge(event_time: float):
	return not completed and event_time >= time-early_swipe and event_time <= time+late_swipe

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	if lane > 0 && lane < 7:
		translation = Vector3(lane-0.5,0,-lane_depth*(chart_position-song_chart_position)/base_note_screen_time)
