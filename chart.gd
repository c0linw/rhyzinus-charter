extends Control

const ZOOM_INCREMENT = 64
const MAX_ZOOM = 1024
const MIN_ZOOM = 64

enum {LAYER_LOWER, LAYER_UPPER, LAYER_TIMING}

var notes: Array = [] # Array of lower or side note entities
var timing_points: Array = [] # Array of timing point entities 
var beats: Array = []
var pixels_per_second = 512 # determines "vertical" scale of chart display
var note_height = 16
var base_lane_width = 64
var current_song_position = 0
var song_length: float = 0

var selected_layer = LAYER_LOWER

var ObjNote = preload("res://note.tscn")

signal anchor_scroll(percentage, new_size)

enum BeatType {MEASURE, BEAT, SUBDIVISION}

class TimeSorter:
	static func sort_ascending(a, b) -> bool:
		return a.time < b.time
			
	static func sort_notes_ascending(a, b) -> bool:
		if a.time < b.time:
			return true
		elif a.time == b.time:
			return a.lane < b.lane
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
	
	# left line
	draw_rect(Rect2(base_lane_width-3, 0, 4, rect_min_size.y), Color(0.4, 0.4, 0.4, 1))
	# center line
	draw_rect(Rect2(base_lane_width*4-2, 0, 4, rect_min_size.y), Color(0.4, 0.4, 0.4, 1))
	# right line
	draw_rect(Rect2(base_lane_width*7-1, 0, 4, rect_min_size.y), Color(0.4, 0.4, 0.4, 1))
		
	# the thinner lines between the left/middle/right lines
	if selected_layer == LAYER_UPPER || selected_layer == LAYER_TIMING:
		draw_rect(Rect2(base_lane_width*2.5, 0, 2, rect_min_size.y), Color(0.4, 0.4, 0.6, 1))
		draw_rect(Rect2(base_lane_width*5.5, 0, 2, rect_min_size.y), Color(0.4, 0.4, 0.6, 1))
	if selected_layer == LAYER_LOWER || selected_layer == LAYER_TIMING:
		for i in range(2, 4):
			var divider_rect: Rect2 = Rect2(base_lane_width*i-1, 0, 2, rect_min_size.y)
			draw_rect(divider_rect, Color(0.4, 0.4, 0.4, 1))
				
		for i in range(5, 7):
			var divider_rect: Rect2 = Rect2(base_lane_width*i-1, 0, 2, rect_min_size.y)
			draw_rect(divider_rect, Color(0.4, 0.4, 0.4, 1))
	
	
	# draw beat lines
	for beat in beats:
		var thickness
		var line_color
		match beat.type:
			BeatType.MEASURE:
				thickness = 4
				line_color = Color(0.75, 0.75, 0.75)
			BeatType.BEAT:
				thickness = 2
				line_color = Color(0.5, 0.5, 0.5)
			BeatType.SUBDIVISION:
				thickness = 2
				line_color = Color(0.25, 0.25, 0.25)
		
		var line_rect: Rect2 = Rect2(0, rect_min_size.y-beat.time*pixels_per_second-(thickness-1), rect_size.x, thickness)
		draw_rect(line_rect, line_color)
	
	# draw bpm changes
	for timing_point in timing_points:
		var line_rect: Rect2 = Rect2(0, rect_min_size.y-timing_point.time*pixels_per_second-4, rect_size.x, 4)
		draw_rect(line_rect, Color(1, 0, 0, 1))
			
func generate_beats(subdivision: int = 4):
	var data: Array = timing_points.duplicate()
	data.sort_custom(TimeSorter, "sort_ascending")
	var beat_output: Array = []
	var timestamp: float = data[0]["time"]
	var beat_length: float = data[0].beat_length
	var meter: int = data[0]["meter"]
	var measure: int = 1
	var beat: int = 1
	beat_output.append({
			"time": timestamp,
			"measure": measure,
			"beat": int(ceil(float(beat) / subdivision)),
			"sub_beat": beat % subdivision,
			"denominator": subdivision,
			"type": BeatType.MEASURE
		})
	var index: int = 0
	# var end_time: float = max(data[len(data)-1]["time"], notes[len(notes)-1]["time"]) + 2
	var end_time: float = song_length
	var beat_type
	while timestamp <= end_time:
		if beat % (meter*subdivision) == 0:
			measure += 1
			beat = 0
			beat_type = BeatType.MEASURE
		elif beat % subdivision == 0:
			beat_type = BeatType.BEAT
		else: 
			beat_type = BeatType.SUBDIVISION
		var next_beat_time: float = timestamp + beat_length / subdivision
		if index+1 < len(data) && next_beat_time >= data[index+1].time:
			if data[index+1].type == "bpm":
				timestamp = data[index+1].time
				beat_length = data[index+1].beat_length
				meter = data[index+1].meter
				beat = 0
				beat_type = BeatType.MEASURE
			index += 1
		else:
			timestamp = next_beat_time
			beat += 1
			index += 1
		beat_output.append({
			"time": timestamp,
			"measure": measure,
			"beat": int(ceil(float(beat) / subdivision)),
			"sub_beat": beat % subdivision,
			"denominator": subdivision,
			"type": beat_type
		})
	return beat_output


func _on_Chart_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
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
	if note_data.lane < 0 or note_data.lane > 13 or (note_data.lane > 7 and note_data.lane < 10):
		return
	var latest_note_time = notes[len(notes)-1].time if len(notes) > 0 else 0
	var note_instance: Note = ObjNote.instance()
	note_instance.set_data(note_data)
	var duplicate_note = find_note(note_instance.time, note_instance.lane)
	if duplicate_note != null:
		print("duplicate note detected! Deleting old note...")
		delete_note(duplicate_note)
	print("adding note with time %s, lane %s" % [note_instance.time, note_instance.lane])
	notes.append(note_instance)
	if note_instance.lane >= 0 and note_instance.lane <= 7:
		$Lower.add_child(note_instance)
	elif note_instance.lane >= 10 and note_instance.lane <= 13:
		$Upper.add_child(note_instance)
	note_instance.connect("custom_gui_input", self, "_on_Note_gui_input")
	
	if note_instance.time <= latest_note_time or duplicate_note != null:
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
	
func update_chart_length(audio_length: float) -> float:
	#var latest_note = 0 if len(notes) == 0 else (notes[len(notes)-1].time+2) * pixels_per_second
	#var latest_timing_point = 0 if len(timing_points) == 0 else (timing_points[len(timing_points)-1].time+2) * pixels_per_second

	#var new_height = max(latest_note, latest_timing_point)
	
	song_length = audio_length
	var new_length = audio_length*pixels_per_second
	rect_min_size = Vector2(rect_min_size.x, new_length)
	update()
	beats = generate_beats()
	update_note_positions()
	return new_length
	
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
	if selected_layer == LAYER_LOWER:
		return int(floor(position_on_chart.x/base_lane_width))
	if selected_layer == LAYER_UPPER:
		return int(floor((position_on_chart.x - base_lane_width)/(base_lane_width*1.5))) + 10


func _on_SubdivisionOption_subdivision_changed(subdivision):
	beats = generate_beats(subdivision)
	print("subdivision changed to %s" % subdivision)
	update()


func _on_LayerSelectTabs_tab_selected(name):
	var layers: Array = [
		{"instance": $Lower, "enable": false},
		{"instance": $Upper, "enable": false},
		{"instance": $Timing, "enable": false},
	]
	match name:
		"Lower":
			layers[0].enable = true
			selected_layer = LAYER_LOWER
		"Upper":
			layers[1].enable = true
			selected_layer = LAYER_UPPER
		"Timing":
			layers[2].enable = true
			selected_layer = LAYER_TIMING
		_:
			return
	for layer in layers:
		if layer.enable:
			for child in layer.instance.get_children():
				child.mouse_filter = MOUSE_FILTER_STOP
		else:
			for child in layer.instance.get_children():
				child.mouse_filter = MOUSE_FILTER_IGNORE
	update()


func _on_ZoomMinus_pressed():
	if pixels_per_second <= MIN_ZOOM :
		return
	pixels_per_second = max(pixels_per_second-ZOOM_INCREMENT, MIN_ZOOM)
	
	var old_scroll_percent = (get_parent().scroll_vertical + get_parent().rect_size.y) / rect_size.y
	var new_length = update_chart_length(song_length)
	yield(VisualServer, "frame_post_draw")
	emit_signal("anchor_scroll", old_scroll_percent, new_length)

func _on_ZoomPlus_pressed():
	if pixels_per_second >= MAX_ZOOM :
		return
	pixels_per_second = min(pixels_per_second+ZOOM_INCREMENT, MAX_ZOOM)
	
	var old_scroll_percent = (get_parent().scroll_vertical + get_parent().rect_size.y) / rect_size.y
	update_chart_length(song_length)
	var new_length = update_chart_length(song_length)
	yield(VisualServer, "frame_post_draw")
	emit_signal("anchor_scroll", old_scroll_percent, new_length)
