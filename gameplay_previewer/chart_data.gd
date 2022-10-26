extends Node
# This object receives the parsed chart data and passes it to the gameplay scene

var leadin_time: float = 2.000
var offset: float = 0
var starting_bpm: float
var notes: Array = []
var timing_points: Array = []
var barlines: Array = []
var beat_data: Array = []
var simlines: Array = []
var notecount: int = 0

class TimeSorter:
	# denotes the order in which these should be sorted, if there are objects with the same time
	const type_enum: Dictionary = {
		"bpm": 0, 
		"velocity": 1,
		"barline": 2,
		"tap": 3,
		"swipe": 3,
		"hold_start": 3,
		"hold_end": 3,
		"hold": 3
	}
	
	static func sort_ascending(a: Dictionary, b: Dictionary) -> bool:
		return a["time"] < b["time"]
		
	# use this after adding the timing points and notes into one array
	static func sort_ascending_with_type_priority(a: Dictionary, b: Dictionary) -> bool:
		if a["time"] < b["time"]:
			return true
		elif a["time"] == b["time"]:
			return type_enum[a["type"]] < type_enum[b["type"]]
		else:
			return false
		
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Automatically adds 2 secs of lead-in time by default, but this can be changed
# Generates "position" based on timing points
	# "position" refers to the displayed "time" of the note. 
	# "position" is used by the renderer, and is subject to scroll speed changes.
# replaces the notes and timing_points arrays with their updated versions
func process_objects_for_gameplay():
	timing_points = generate_barlines(timing_points)
	var first_bpm_index := find_first_beat_index(timing_points)
	if first_bpm_index >= 0:
		starting_bpm = (60.0 / timing_points[first_bpm_index].beat_length)
	# make a new (sorted) array containing all the objects
	var objects: Array = timing_points.duplicate()
	objects.append_array(notes)
	objects.sort_custom(TimeSorter, "sort_ascending_with_type_priority")
	
	# add position to each object, calculating scroll speed changes
	var bpm: float = starting_bpm
	var sv_velocity: float = 1.0
	var curr_time: float = 0.0
	var curr_position: float = 0.0
	var processed_notes: Array = []
	var processed_timing_points: Array = []
	var processed_barlines: Array = []
	for object in objects:
		var time_delta: float = object["time"] - curr_time
		var position_delta: float = time_delta * sv_velocity
		curr_time += time_delta
		curr_position += position_delta
		if object["type"] == "bpm":
			var new_bpm: float = (60.0 / object["beat_length"])
			bpm = new_bpm
		elif object["type"] == "velocity":
			sv_velocity = object["velocity"]
		object["position"] = curr_position + offset
		object["time"] = object["time"] + offset
		if object["type"] == "bpm" || object["type"] == "velocity":
			processed_timing_points.append(object)
		elif object["type"] == "barline":
			processed_barlines.append(object)
		else:
			processed_notes.append(object)
	
	# merge hold ends with hold starts, and add hold ticks
	var processed_notes_with_holds: Array = []
	for i in processed_notes.size():
		var note: Dictionary = processed_notes[i]
		if note["type"] == "hold_start":
			var new_note: Dictionary = {
				"lane": note["lane"],
				"time": note["time"],
				"type": "hold",
				"position": note["position"],
				"end_time": note["end_time"] + offset,
				"end_position": get_end_position(note, i, processed_notes),
				"ticks": []
			}
			
			# get index of closest bpm marker:
			# for i in processed timing points.size():
				# if the marker's time is later than the new_note["time"], break
				# if the marker is not a bpm marker, continue
				# if the marker is a bpm marker, set the index
			var curr_timing_index: int = 0
			for j in processed_timing_points.size():
				if processed_timing_points[j]["time"] > new_note["time"]:
					break
				if processed_timing_points[j]["type"] != "bpm":
					continue
				curr_timing_index = j
			
			# while the current beat is before (end_time - early_cracked):
				# add the beat to the ticks array
				# increment beat by using timing point info
				# if this new beat is later than the "next" bpm marker, use that instead, and set the current index to that marker's index
			var curr_beat_length: float = processed_timing_points[curr_timing_index]["beat_length"]
			var curr_tick: float = new_note["time"]

			# generate ticks until a leniency window before the end
			while curr_tick < new_note["end_time"] - 0.120:
				var tick_valid := false
				var next_tick: float = curr_tick + curr_beat_length
				# tick is either curr + beat_length, or the time of the next bpm change, whichever comes first
				if curr_timing_index+1 < len(processed_timing_points) and next_tick >= processed_timing_points[curr_timing_index+1]["time"]:
					if processed_timing_points[curr_timing_index+1]["type"] == "bpm":
						curr_tick = processed_timing_points[curr_timing_index+1]["time"]
						curr_beat_length = processed_timing_points[curr_timing_index+1]["beat_length"]
						tick_valid = true
					curr_timing_index += 1
				else: 
					curr_tick = next_tick
					tick_valid = true
				
				if tick_valid:
					new_note["ticks"].append(curr_tick)
					notecount += 1
					
			processed_notes_with_holds.append(new_note)
		elif note["type"] == "hold_end":
			notecount += 1
		else:
			processed_notes_with_holds.append(note)
	
	notecount += len(processed_notes_with_holds)
	notes = processed_notes_with_holds
	timing_points = processed_timing_points
	barlines = processed_barlines
	
	generate_beats(processed_timing_points)
	generate_simlines(processed_notes_with_holds)
	
func export_data() -> Dictionary:
	process_objects_for_gameplay()
	return {
		"leadin_time": leadin_time,
		"offset": offset,
		"starting_bpm": starting_bpm,
		"notes": notes,
		"timing_points": timing_points,
		"barlines": barlines,
		"beats": beat_data,
		"notecount": notecount,
		"simlines": simlines
	}

func get_end_position(note: Dictionary, start_index: int, array_to_search: Array):
	var i: int = start_index + 1
	while i < array_to_search.size():
		var note_to_compare: Dictionary = array_to_search[i]
		i += 1
		if note_to_compare["lane"] != note["lane"]:
			continue
		if note_to_compare["type"] != "hold_end":
			continue
		if note_to_compare["time"] >= note["time"]:
			return note_to_compare["position"]
		i += 1
	return null
	
func generate_barlines(data: Array) -> Array:
	data.sort_custom(TimeSorter, "sort_ascending_with_type_priority")
	var return_data: Array = data.duplicate()
	var index: int = find_first_beat_index(data)
	var timestamp: float = data[index]["time"]
	var beat_length: float = data[index].beat_length
	var meter: int = data[index]["meter"]
	var beat: int = 0
	
	# use either the last note or the last timing point's time
	var end_time: float = max(data[len(data)-1]["time"], notes[len(notes)-1]["time"])
	while timestamp <= end_time:
		if beat % meter == 0:
			return_data.append({
				"time": timestamp,
				"type": "barline"
			})
		var next_beat_time: float = timestamp + beat_length
		if index+1 < len(data) and next_beat_time >= data[index+1]["time"]:
			if data[index+1]["type"] == "bpm":
				timestamp = data[index+1]["time"]
				beat_length = data[index+1]["beat_length"]
				meter = data[index+1]["meter"]
				beat = 0
			index += 1
		else:
			timestamp = next_beat_time
			beat += 1
	return return_data

func generate_beats(timing_points: Array):
	var data: Array = timing_points.duplicate()
	data.sort_custom(TimeSorter, "sort_ascending_with_type_priority")
	var beat_output: Array = []
	var index: int = find_first_beat_index(timing_points)
	var timestamp: float = data[index]["time"]
	var beat_length: float = data[index].beat_length
	var meter: int = data[index]["meter"]
	var measure: int = 1
	var beat = 1
	beat_output.append({
			"time": timestamp,
			"measure": measure,
			"beat": beat
		})
	
	# use either the last note or the last timing point's time
	var end_time: float = max(data[len(data)-1]["time"], notes[len(notes)-1]["time"])
	while timestamp <= end_time:
		if beat % meter == 0:
			measure += 1
			beat = 0
		var next_beat_time: float = timestamp + beat_length
		if index+1 < len(data) and next_beat_time >= data[index+1]["time"]:
			if data[index+1]["type"] == "bpm":
				timestamp = data[index+1]["time"]
				beat_length = data[index+1]["beat_length"]
				meter = data[index+1]["meter"]
				beat = 0
			index += 1
		else:
			timestamp = next_beat_time
			beat += 1
		beat_output.append({
			"time": timestamp,
			"measure": measure,
			"beat": beat
		})
	beat_data = beat_output
	
func generate_simlines(note_data: Array):
	var last_note_time = -1.0
	var last_note_lane = -1
	for note in note_data:
		if note.time == last_note_time:
			# simline already exists (3 note chord or more)
			if len(simlines) > 0 and simlines[len(simlines)-1].time == last_note_time:
				simlines[len(simlines)-1][get_lane_location(note.lane)][note.lane] = 1
			# create new simline with current and previous note lanes
			else:
				var new_simline = {
					"time": note.time,
					"position": note.position,
					"lower": {},
					"side": {},
					"upper": {},
				}
				new_simline[get_lane_location(note.lane)][note.lane] = 1
				new_simline[get_lane_location(last_note_lane)][last_note_lane] = 1
				simlines.append(new_simline)
		else: 
			last_note_time = note.time
			last_note_lane = note.lane
			
func get_lane_location(lane: int) -> String:
	if lane >= 1 and lane <= 6:
		return "lower"
	if lane >= 10 and lane <= 13:
		return "upper"
	if lane == 0 or lane == 7:
		return "side"
	return "unknown"

func find_first_beat_index(timing_points: Array) -> int:
	for i in len(timing_points):
		if timing_points[i].type == "bpm":
			return i
	return -1
