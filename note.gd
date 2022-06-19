extends Control
class_name Note

var time: float
var lane: int
var type: String # "tap", "hold_start", "hold_end" or "swipe"

var note_height = 16
var base_lane_width = 64
var note_color: Color = Color(1,1,1,1)

signal custom_gui_input(event, note)

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
		#note_color = Color(1,1,1,1)
		match type:
			"hold_start":
				$TextureRect.texture = load("res://images/hold_start.png")
			"hold_end":
				$TextureRect.texture = load("res://images/hold_end.png")
			"tap":
				$TextureRect.texture = load("res://images/tap.png")
			"swipe":
				$TextureRect.texture = load("res://images/swipe.png")
	elif lane == 0 || lane == 7:
		set_size(Vector2(base_lane_width, note_height))
		note_color = Color(1,1,0.1,1)
		match type:
			"hold_start":
				$TextureRect.texture = load("res://images/hold_start.png")
			"hold_end":
				$TextureRect.texture = load("res://images/hold_end.png")
			"tap":
				$TextureRect.texture = load("res://images/tap.png")
			"swipe":
				$TextureRect.texture = load("res://images/swipe.png")
		modulate = note_color
	elif lane >= 10 and lane <= 13:
		set_size(Vector2(base_lane_width*1.5, note_height))
		match type:
			"hold_start":
				$TextureRect.texture = load("res://images/hold_start_upper.png")
			"hold_end":
				$TextureRect.texture = load("res://images/hold_end_upper.png")
			"tap":
				$TextureRect.texture = load("res://images/tap_upper.png")
		note_color = Color(0.13,0.25,1,0.5)
	$TextureRect.rect_size = rect_size


func _on_Note_gui_input(event):
	emit_signal("custom_gui_input", event, self)
