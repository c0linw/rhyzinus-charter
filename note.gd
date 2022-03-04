extends Control
class_name Note

var time: float
var lane: int
var type: String # "tap" or "hold"

var note_height = 32
var base_lane_width = 64
var note_color: Color = Color(1,1,1,1)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_data(note_data: Dictionary):
	time = note_data.time
	lane = note_data.lane
	type = note_data.type
	if lane > 0 and lane < 7:
		set_size(Vector2(base_lane_width, note_height))
		note_color = Color(1,1,1,1)
	elif lane == 0 || lane == 7:
		set_size(Vector2(base_lane_width, note_height))
		note_color = Color(1,1,0.1,1)
	elif lane >= 10 and lane <= 13:
		set_size(Vector2(base_lane_width*1.5, note_height))
		note_color = Color(0.13,0.25,1,0.5)

func _draw():
	var to_draw = Rect2(Vector2(0,0), rect_size)
	draw_rect(to_draw, note_color)
