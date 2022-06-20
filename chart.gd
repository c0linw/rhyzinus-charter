extends Control
class_name Chart

const ZOOM_INCREMENT = 64
const MAX_ZOOM = 1024
const MIN_ZOOM = 64

enum {LAYER_LOWER, LAYER_UPPER, LAYER_TIMING}

var notes: Array = [] # Array of ObjNote entities
var bpm_changes: Array = [] # Array of ObjTimingPoint instances, bpm changes only
var velocity_changes: Array = [] # Array of ObjTimingPoint instances, velocity changes only
var beats: Array = []
var pixels_per_second = 192 # determines "vertical" scale of chart display
var note_height = 16
var base_lane_width = 64
var current_song_position = 0
var song_length: float = 0
var current_subdivision: float = 4

var selected_layer = LAYER_LOWER
var selected_notetype = "tap_lower" # see notetype_button for enumeration of string types
var hold_pairs: Array = [] # an array of hold start/end pairs, which will be updated whenever notes are added/deleted

var ObjNote = preload("res://note.tscn")
var ObjTimingPoint = preload("res://timing_point.tscn")

signal anchor_scroll(percentage, new_size)
signal custom_scroll(dir_multiplier) # up is 1, down is -1

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
			
	static func sort_timingpoints_ascending(a, b) -> bool:
		if a.time < b.time:
			return true
		elif a.time == b.time:
			if a.type == "bpm" and b.type == "velocity":
				return true
			else: 
				return false
		else:
			return false


# Called when the node enters the scene tree for the first time.
func _ready():
	reset_chart_data()

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
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
	if selected_layer == LAYER_UPPER:
		draw_rect(Rect2(base_lane_width*2.5, 0, 2, rect_min_size.y), Color(0.4, 0.4, 0.6, 1))
		draw_rect(Rect2(base_lane_width*5.5, 0, 2, rect_min_size.y), Color(0.4, 0.4, 0.6, 1))
	if selected_layer == LAYER_LOWER:
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
		
	# draw hold note bodies
	for pair in hold_pairs:
		if pair[0].lane == 0 or pair[0].lane == 7:
			var hold_rect: Rect2 = Rect2(pair[1].rect_position.x, pair[1].rect_position.y + note_height, base_lane_width, (pair[1].time - pair[0].time) * pixels_per_second)
			draw_rect(hold_rect, Color(1,1,0,0.5))
		if pair[0].lane > 0 and pair[0].lane < 7:
			var hold_rect: Rect2 = Rect2(pair[1].rect_position.x, pair[1].rect_position.y + note_height, base_lane_width, (pair[1].time - pair[0].time) * pixels_per_second)
			draw_rect(hold_rect, Color(1,1,1,0.5))
		if pair[0].lane > 9 and pair[0].lane < 14:
			var hold_rect: Rect2 = Rect2(pair[1].rect_position.x, pair[1].rect_position.y + note_height, base_lane_width*1.5, (pair[1].time - pair[0].time) * pixels_per_second)
			draw_rect(hold_rect, Color(0.13,0.25,1, 0.4))
			
func generate_beats(subdivision: int):
	var data: Array = bpm_changes.duplicate()
	data.sort_custom(TimeSorter, "sort_timingpoints_ascending")
	var beat_output: Array = []
	var timestamp: float = data[0].time
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
			else:
				timestamp = next_beat_time
			index += 1
		else:
			timestamp = next_beat_time
		beat += 1
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
			print("current scroll: ", get_parent().scroll_vertical)
			var snapped_time: float = find_closest_beat(event.position)
			var type: String
			match selected_layer:
				LAYER_LOWER:
					match selected_notetype:
						"tap_lower":
							type = "tap" 
						"hold_start_lower":
							type = "hold_start"
						"hold_end_lower":
							type = "hold_end" 
						"swipe_lower":
							type = "swipe"
						_:
							print("invalid note type %s for selected layer %s" % [selected_notetype, selected_layer])
							return
				LAYER_UPPER:
					match selected_notetype:
						"tap_upper":
							type = "tap" 
						"hold_start_upper":
							type = "hold_start" 
						"hold_end_upper":
							type = "hold_end"
						_:
							print("invalid note type %s for selected layer %s" % [selected_notetype, selected_layer])
							return
				LAYER_TIMING:
					match selected_notetype:
						"bpm":
							type = "bpm"
						"velocity":
							type = "velocity"
						_:
							print("invalid note type %s for selected layer %s" % [selected_notetype, selected_layer])
							return
			if selected_layer == LAYER_TIMING:
				var new_timingpoint_data: Dictionary
				match type:
					"bpm":
						if len(get_tree().get_nodes_in_group("bpm_timingpoint_value")) != 1:
							push_error("did not find exactly one BPM value input")
							return
						var bpm_value_box = get_tree().get_nodes_in_group("bpm_timingpoint_value")[0]
						if bpm_value_box.valid:
							var bpm_value = float(bpm_value_box.text)
							new_timingpoint_data = {
								"time": snapped_time,
								"type": type,
								"beat_length": 60.0 / bpm_value,
								"meter": 4
							}
						else:
							return
					"velocity":
						if len(get_tree().get_nodes_in_group("velocity_timingpoint_value")) != 1:
							push_error("did not find exactly one velocity value input")
							return
						var velocity_value_box = get_tree().get_nodes_in_group("velocity_timingpoint_value")[0]
						if velocity_value_box.valid:
							var velocity_value = float(velocity_value_box.text)
							new_timingpoint_data = {
								"time": snapped_time,
								"type": type,
								"velocity": velocity_value,
							}
						else:
							return
				add_timingpoint(new_timingpoint_data)
			else:
				var snapped_lane: float = find_lane(event.position)
				var new_note_data: Dictionary = {
					"time": snapped_time,
					"lane": snapped_lane,
					"type": type
				}
				add_note(new_note_data)
		if event.button_index == BUTTON_RIGHT and event.pressed:
			pass
		if event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			emit_signal("custom_scroll", -1)
		if event.button_index == BUTTON_WHEEL_UP and event.pressed:
			emit_signal("custom_scroll", 1)
			
func _on_Note_gui_input(event, note):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			print("note pressed!")
			# TODO: implement dragging
		if event.button_index == BUTTON_RIGHT and event.pressed:
			delete_note(note)
			
func _on_TimingPoint_gui_input(event, timingpoint):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			print("timing point pressed!")
			# TODO: (maybe) implement dragging
		if event.button_index == BUTTON_RIGHT and event.pressed:
			delete_timingpoint(timingpoint)
			
func add_note(note_data: Dictionary):
	if note_data.lane < 0 or note_data.lane > 13 or (note_data.lane > 7 and note_data.lane < 10):
		return
	var latest_note_time = notes[len(notes)-1].time if len(notes) > 0 else 0
	var note_instance: Note = ObjNote.instance()
	note_instance.set_data(note_data)
	var duplicate_note = find_note(note_instance.time, note_instance.lane)
	if duplicate_note != null:
		delete_note(duplicate_note)
	notes.append(note_instance)
	if note_instance.lane >= 0 and note_instance.lane <= 7:
		$Lower.add_child(note_instance)
	elif note_instance.lane >= 10 and note_instance.lane <= 13:
		$Upper.add_child(note_instance)
	note_instance.connect("custom_gui_input", self, "_on_Note_gui_input")
	
	notes.sort_custom(TimeSorter, "sort_notes_ascending")
		
	hold_pairs = find_hold_pairs(notes)
	update_note_positions()
	update()
	EditorStatus.set_modified()
		
func delete_note(note):
	print("deleting note with time %s, lane %s" % [note.time, note.lane])
	notes.erase(note)
	note.queue_free()
	hold_pairs = find_hold_pairs(notes)
	update_note_positions()
	update()
	EditorStatus.set_modified()
	
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
	
	
func add_timingpoint(timingpoint_data: Dictionary):
	match timingpoint_data.type:
		"bpm":
			var timingpoint_instance: TimingPoint = ObjTimingPoint.instance()
			timingpoint_instance.set_data(timingpoint_data)
			var duplicate_point = find_timingpoint(timingpoint_instance.time, timingpoint_instance.type)
			if duplicate_point != null:
				print("timing point already exists, opening edit window instead")
				var dialog = get_tree().get_nodes_in_group("bpm_timingpoint_dialog")[0]
				dialog.setup(duplicate_point)
				dialog.popup()
				return
			bpm_changes.append(timingpoint_instance)
			$Timing.add_child(timingpoint_instance)
			timingpoint_instance.connect("custom_gui_input", self, "_on_TimingPoint_gui_input")
			bpm_changes.sort_custom(TimeSorter, "sort_ascending")
		"velocity":
			var timingpoint_instance: TimingPoint = ObjTimingPoint.instance()
			timingpoint_instance.set_data(timingpoint_data)
			var duplicate_point = find_timingpoint(timingpoint_instance.time, timingpoint_instance.type)
			if duplicate_point != null:
				velocity_changes.erase(duplicate_point)
			velocity_changes.append(timingpoint_instance)
			$Timing.add_child(timingpoint_instance)
			timingpoint_instance.connect("custom_gui_input", self, "_on_TimingPoint_gui_input")
			velocity_changes.sort_custom(TimeSorter, "sort_ascending")
		_:
			return
		
	beats = generate_beats(current_subdivision)
	update_timingpoint_positions()
	update_note_positions()
	update()
	EditorStatus.set_modified()
	
func delete_timingpoint(timingpoint):
	match timingpoint.type:
		"bpm":
			if len(bpm_changes) == 1:
				print("cannot delete timing point, at least one is required")
				return
			bpm_changes.erase(timingpoint)
		"velocity":
			velocity_changes.erase(timingpoint)
		_:
			return
			
	print("deleting timing point with time %s, type %s" % [timingpoint.time, timingpoint.type])
	timingpoint.queue_free()
	beats = generate_beats(current_subdivision)
	update_timingpoint_positions()
	update_note_positions()
	update()
	EditorStatus.set_modified()
	
# returns a note entity, or null
func find_timingpoint(time: float, type: String):
	var points: Array
	match type:
		"bpm":
			points = bpm_changes
		"velocity":
			points = velocity_changes
		_:
			return
	
	# not sure how well binary search will deal with error margins and two sort parameters (time and lane), so just linear search for now
	
	# use an error margin in case of float rounding problems 
	var error_margin: float = 0.002
	for point in points:
		if point.type == type and abs(point.time - time) <= error_margin:
			return point
		elif point.time > time + error_margin:
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
	beats = generate_beats(current_subdivision)
	update_note_positions()
	update_timingpoint_positions()
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
			
func update_timingpoint_positions():
	for timingpoint in bpm_changes:
		var y = rect_min_size.y - timingpoint.time*pixels_per_second - timingpoint.rect_size.y/2
		timingpoint.set_position(Vector2(0, y))
		timingpoint.rect_size.x = rect_size.x/2 - 4
	
	for timingpoint in velocity_changes:
		var y = rect_min_size.y - timingpoint.time*pixels_per_second - timingpoint.rect_size.y/2
		timingpoint.set_position(Vector2(rect_size.x/2 - 4, y))
		timingpoint.rect_size.x = rect_size.x/2 - 4
		
func chart_position_to_time(y: float) -> float:
	 return (rect_min_size.y - y) / pixels_per_second
	
func time_to_chart_position(time: float) -> float:
	return rect_min_size.y - time*pixels_per_second

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
				return min(beats[mid-1].time, beats[mid].time)
				#return get_nearest_number(target, beats[mid-1].time, beats[mid].time)
			upper = mid
		else:
			if (mid < len(beats)-1 and target < beats[mid+1].time):
				return min(beats[mid].time, beats[mid + 1].time)
				#return get_nearest_number(target, beats[mid].time, beats[mid + 1].time)
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


# assumes the notes array is sorted by time
func find_hold_pairs(notes: Array) -> Array:
	var pairs: Array = [] # an array of pairs of notes
	var unpaired_starts: Array = []
	for note in notes:
		if note.type == "hold_start":
			unpaired_starts.append(note)
		if note.type == "hold_end":
			for i in len(unpaired_starts):
				var hold_start = unpaired_starts[i]
				if hold_start.lane == note.lane:
					pairs.append([hold_start, note])
					unpaired_starts.remove(i)
					break
	return pairs

func is_onscreen(instance: Control):
	return (instance.rect_position.y > get_parent().scroll_vertical) and (instance.rect_position.y < get_parent().scroll_vertical + get_parent().rect_size.y)


func _on_SubdivisionOption_subdivision_changed(subdivision):
	current_subdivision = subdivision
	beats = generate_beats(current_subdivision)
	print("subdivision changed to %s" % subdivision)
	update()


func _on_LayerSelectTabs_tab_selected(name):
	print("tab selected: ", name)
	var layers: Array = [
		{"instance": $Lower, "enable": false},
		{"instance": $Upper, "enable": false},
		{"instance": $Timing, "enable": false},
	]
	match name:
		"Lower":
			layers[0].enable = true
			selected_layer = LAYER_LOWER
			_on_notetype_selected("tap_lower")
		"Upper":
			layers[1].enable = true
			selected_layer = LAYER_UPPER
			_on_notetype_selected("tap_upper")
		"Timing":
			layers[2].enable = true
			selected_layer = LAYER_TIMING
			_on_notetype_selected("bpm")
		_:
			return
	for layer in layers:
		if layer.enable:
			for child in layer.instance.get_children():
				child.mouse_filter = MOUSE_FILTER_PASS
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
	var new_length = update_chart_length(song_length)
	yield(VisualServer, "frame_post_draw")
	emit_signal("anchor_scroll", old_scroll_percent, new_length)


func _on_notetype_selected(type: String):
	selected_notetype = type
	for notetype_button in get_tree().get_nodes_in_group("notetype_buttons"):
		notetype_button.set_selected(notetype_button.type == type)


func _on_BPMTimingPointDialog_set_bpm_point(instance, offset, bpm, meter):
	for timing_point in bpm_changes:
		if timing_point == instance:		
			var new_data: Dictionary = {
				"time": offset,
				"beat_length": 60.0/bpm,
				"meter": meter,
				"type": "bpm"
			}
			timing_point.set_data(new_data)
			
			bpm_changes.sort_custom(TimeSorter, "sort_ascending")
				
			beats = generate_beats(current_subdivision)
			update_timingpoint_positions()
			update_note_positions()
			update()
			
			get_tree().get_nodes_in_group("bpm_timingpoint_dialog")[0].hide()
			return


func get_chart_data() -> Dictionary:
	var note_data: Array = []
	for note in notes:
		note_data.append({
			"time": note.time,
			"type": note.type,
			"lane": note.lane,
		})
	
	var bpm_data: Array = []
	for timingpoint in bpm_changes:
		var bpm_change = {
			"time": timingpoint.time,
			"type": timingpoint.type,
			"beat_length": timingpoint.beat_length,
			"meter": timingpoint.meter
		}
		bpm_data.append(bpm_change)

	var velocity_data: Array = []
	for timingpoint in velocity_changes:
		var velocity_change = {
			"time": timingpoint.time,
			"type": timingpoint.type,
			"velocity": timingpoint.velocity
		}
		velocity_data.append(velocity_change)
	
	var chart_data: Dictionary = {
		"notes": note_data,
		"bpm_changes": bpm_data,
		"velocity_changes": velocity_data
	}
	return chart_data
	

func load_chart_data(chart_data: Dictionary):
	for note in notes:
		note.queue_free()
	for timingpoint in bpm_changes:
		timingpoint.queue_free()
	for timingpoint in velocity_changes:
		timingpoint.queue_free()
	notes = []
	bpm_changes = []
	velocity_changes = []
	
	# TODO: optimize by not calling add_note and add_timingpoint repeatedly
	for note_data in chart_data.notes:
		add_note(note_data)
	for timingpoint_data in chart_data.bpm_changes:
		add_timingpoint(timingpoint_data)
	for timingpoint_data in chart_data.velocity_changes:
		add_timingpoint(timingpoint_data)
	EditorStatus.set_saved()
	EditorStatus.set_status("Ready")

func reset_chart_data():
	for note in notes:
		note.queue_free()
	for timingpoint in bpm_changes:
		timingpoint.queue_free()
	for timingpoint in velocity_changes:
		timingpoint.queue_free()
	notes = []
	bpm_changes = []
	velocity_changes = []
	hold_pairs = []
	
	add_timingpoint({
		"time": 0,
		"beat_length": 0.5,
		"meter": 4,
		"type": "bpm"
	})
	
	beats = generate_beats(current_subdivision)
	
	update()
	update_note_positions()
	update_timingpoint_positions()
	
	EditorStatus.set_saved()
	EditorStatus.set_status("Ready")

func _on_SongAudioPlayer_audio_loaded(new_length):
	update_chart_length(new_length)

func get_note_times_since_time(time: float) -> Array:
	var times = []
	for note in notes:
		if note.time > time and note.type != "hold_end":
			times.append(note.time)
	return times
