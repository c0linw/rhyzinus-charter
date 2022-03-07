extends Control

var notes: Array = [] # Array of lower or side note entities
var timing_points: Array = [] # Array of timing point entities 
var beats: Array = []
var pixels_per_second = 512 # determines "vertical" scale of chart display
var note_height = 32
var base_lane_width = 64
var current_song_position = 0
var song_length: float = 0

var ObjNote = preload("res://note.tscn")

class TimeSorter:
	static func sort_ascending(a, b) -> bool:
		return a.time < b.time
			
	static func sort_notes_ascending(a, b) -> bool:
		if a.time < b.time:
			return true
		elif a.time == b.time:
			return a.lane < b.lane # floor notes come before upper notes, guarantees the upper notes draw over them
		else:
			return false


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(0, 8):
		var note_data: Dictionary = {
			"time": i*0.5,
			"lane": i,
			"type": "tap"
		}
		add_note(note_data)
		
	for i in range(10,14):
		var note_data: Dictionary = {
			"time": i-10,
			"lane": i,
			"type": "tap"
		}
		add_note(note_data)
		
	timing_points.append({
		"time": 0,
		"beat_length": 0.5,
		"meter": 4,
		"type": "bpm"
	})
		
	notes.sort_custom(TimeSorter, "sort_notes_ascending")
	timing_points.sort_custom(TimeSorter, "sort_ascending")
	
	beats = generate_beats()
	
	update()
	update_note_positions()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _draw():
	# draw lane divisions
	draw_rect(Rect2(base_lane_width-3, 0, 4, rect_min_size.y), Color(0.4, 0.4, 0.4, 1))
		
	for i in range(2, 4):
		var divider_rect: Rect2 = Rect2(base_lane_width*i-1, 0, 2, rect_min_size.y)
		draw_rect(divider_rect, Color(0.4, 0.4, 0.4, 1))
		
	draw_rect(Rect2(base_lane_width*4-2, 0, 4, rect_min_size.y), Color(0.4, 0.4, 0.4, 1))
		
	for i in range(5, 7):
		var divider_rect: Rect2 = Rect2(base_lane_width*i-1, 0, 2, rect_min_size.y)
		draw_rect(divider_rect, Color(0.4, 0.4, 0.4, 1))
		
	draw_rect(Rect2(base_lane_width*7-1, 0, 4, rect_min_size.y), Color(0.4, 0.4, 0.4, 1))
	
	# draw beat lines
	for beat in beats:
		var thickness = 4 if beat.beat == 1 else 2
		var line_color = Color(0.75, 0.75, 0.75) if beat.beat == 1 else Color(0.5, 0.5, 0.5)
		var line_rect: Rect2 = Rect2(0, rect_min_size.y-beat.time*pixels_per_second-(thickness-1), rect_size.x, thickness)
		draw_rect(line_rect, line_color)
	
	# draw bpm changes
	for timing_point in timing_points:
		var line_rect: Rect2 = Rect2(0, rect_min_size.y-timing_point.time*pixels_per_second-4, rect_size.x, 4)
		draw_rect(line_rect, Color(1, 0, 0, 1))
			
func generate_beats():
	var data: Array = timing_points.duplicate()
	data.sort_custom(TimeSorter, "sort_ascending")
	var beat_output: Array = []
	var timestamp: float = data[0]["time"]
	var beat_length: float = data[0].beat_length
	var meter: int = data[0]["meter"]
	var measure: int = 1
	var beat = 1
	beat_output.append({
			"time": timestamp,
			"measure": measure,
			"beat": beat
		})
	var index: int = 0
	# var end_time: float = max(data[len(data)-1]["time"], notes[len(notes)-1]["time"]) + 2
	var end_time: float = song_length
	while timestamp <= end_time:
		if beat % meter == 0:
			measure += 1
			beat = 0
		var next_beat_time: float = timestamp + beat_length
		if index+1 < len(data) && next_beat_time >= data[index+1].time:
			if data[index+1].type == "bpm":
				timestamp = data[index+1].time
				beat_length = data[index+1].beat_length
				meter = data[index+1].meter
				beat = 0
			index += 1
		else:
			timestamp = next_beat_time
			beat += 1
			index += 1
		beat_output.append({
			"time": timestamp,
			"measure": measure,
			"beat": beat
		})
	return beat_output


func _on_Chart_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			# TODO: search for a note that already exists at the time and lane, and replace it if necessary
			var snapped_time: float = find_closest_beat(event.position)
			var snapped_lane: float = find_lane(event.position)
			var new_note_data: Dictionary = {
				"time": snapped_time,
				"lane": snapped_lane,
				"type": "tap"
			}
			add_note(new_note_data)
		if event.button_index == BUTTON_RIGHT and event.pressed:
			pass
			
func _on_Note_gui_input(event, note):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			print("note pressed!")
		if event.button_index == BUTTON_RIGHT and event.pressed:
			delete_note(note)
			
func add_note(note_data: Dictionary):
	var latest_note_time = notes[len(notes)-1].time if len(notes) > 0 else 0
	var note_instance: Note = ObjNote.instance()
	note_instance.set_data(note_data)
	var duplicate_note = find_note(note_instance.time, note_instance.lane)
	if duplicate_note != null:
		print("duplicate note detected! Deleting old note...")
		delete_note(duplicate_note)
	print("adding note with time %s, lane %s" % [note_instance.time, note_instance.lane])
	notes.append(note_instance)
	add_child(note_instance)
	note_instance.connect("custom_gui_input", self, "_on_Note_gui_input")
	
	if note_instance.time < latest_note_time or duplicate_note != null:
		notes.sort_custom(TimeSorter, "sort_notes_ascending")
	update_note_positions()
		
func delete_note(note):
	print("deleting note with time %s, lane %s" % [note.time, note.lane])
	notes.erase(note)
	note.queue_free()
	
# returns a note entity, or null
func find_note(time: float, lane: int):
	# not sure how well binary search will deal with error margins and two sort parameters (time and lane), so just linear search for now
	
	# use an error margin in case of float rounding problems 
	var error_margin: float = 0.002
	for note in notes:
		if note.lane == lane and abs(note.time - time) <= error_margin:
			return note
		elif note.time > time + error_margin:
			return null
	return null
	
func update_chart_length(audio_length: float):
	#var latest_note = 0 if len(notes) == 0 else (notes[len(notes)-1].time+2) * pixels_per_second
	#var latest_timing_point = 0 if len(timing_points) == 0 else (timing_points[len(timing_points)-1].time+2) * pixels_per_second

	#var new_height = max(latest_note, latest_timing_point)
	song_length = audio_length
	rect_min_size = Vector2(rect_min_size.x, audio_length*pixels_per_second)
	update()
	beats = generate_beats()
	update_note_positions()
	
func update_note_positions():
	for note in notes:
		if note.lane >= 0 and note.lane <= 7:
			var x = note.lane*base_lane_width
			var y = rect_min_size.y - note.time*pixels_per_second - note_height
			note.set_position(Vector2(x,y))
		elif note.lane >= 10 and note.lane <= 13:			
			var x = base_lane_width + (note.lane-10)*base_lane_width*1.5
			var y = rect_min_size.y - note.time*pixels_per_second - note_height
			note.set_position(Vector2(x,y))

func find_closest_beat(position_on_chart: Vector2):
	# modified binary search
	var target: float = (rect_size.y - position_on_chart.y) / pixels_per_second # the time in seconds
	var lower: int = 0
	var upper: int = len(beats)
	var mid: int = 0
	
	# Corner cases
	if (len(beats) == 0):
		return 0
	if (target <= beats[0].time):
		return beats[0].time
	if (target >= beats[len(beats) - 1].time):
		return beats[len(beats) - 1].time
	
	while lower < upper:
		mid = (lower + upper) / 2
		if (beats[mid].time == target):
			return beats[mid].time
			
		if (target < beats[mid].time):
			if (mid > 0 and target > beats[mid-1].time):
				return get_nearest_number(target, beats[mid-1].time, beats[mid].time)
			upper = mid
		else:
			if (mid < len(beats)-1 and target < beats[mid+1].time):
				return get_nearest_number(target, beats[mid].time, beats[mid + 1].time)
			lower = mid + 1
		
	return beats[mid].time
	
func get_nearest_number(target: float, val1: float, val2: float):
	if (abs(target - val1) < abs(target - val2)):
		return val1
	else:
		return val2
		
func find_lane(position_on_chart: Vector2):
	# TODO: this only handles lower notes atm, will need different formula when editing upper (blue) notes
	return int(floor(position_on_chart.x/base_lane_width))
