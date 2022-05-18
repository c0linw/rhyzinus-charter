extends Node

var chart_data: Dictionary = {
	"notes": [],
	"timing_points": []
}
var current_section: String = ""
const NUM_LANES_IN_SOURCE: int = 14 # only supports 14-key charts for now

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# loads the chart file and processes every line until the end. 
# Returns null if failed, otherwise dict containing the processed notes/timing info
func load_chart(file_path: String):
	chart_data = {
		"notes": [],
		"timing_points": []
	}
	# get data from file
	var file := File.new()
	if not file.file_exists(file_path):
		print(".osu file not found at ", file_path)
		return
	var err := file.open(file_path, File.READ)
	if err:
		print("Error %s while opening file: %s" % [err, file_path])
		return
	while not file.eof_reached():
		var line := file.get_line()
		if line == "":
			continue
		if not process_chart_line(line, chart_data):
			print("skipped invalid line: ", line)
	file.close()
	return chart_data

# processes one line of the chart file. Returns true if the line was valid (even if skipped)
func process_chart_line(line: String, receiver: Dictionary) -> bool:
	if line.begins_with("["): # indicates new data section
		if line == "[TimingPoints]" || line == "[HitObjects]":
			current_section = line
			print("parsing section ", line)
		else: # another section that we don't need
			current_section = ""
			print("skipping section ", line)
		return true
		
	if current_section == "[TimingPoints]":
		var timing_data: Array = line.split(",")
		if len(timing_data) != 8:
			print("timing point has %s values, was expecting 8" % len(timing_data))
			return false
		var timing_type: String = "velocity" if timing_data[6] == "0" else "bpm"
		if timing_type == "bpm":
			var timing_point: Dictionary = {
				"time": get_time(timing_data[0]),
				"beat_length": float(timing_data[1]) / 1000.0, # beat length, in seconds
				"meter": int(timing_data[2]), # ignored if type == 1
				"type": timing_type
			}
			receiver.timing_points.append(timing_point)
		else:
			var timing_point: Dictionary = {
				"time": get_time(timing_data[0]),
				"velocity": -100.0/float(timing_data[1]),
				"type": timing_type
			}
			receiver.timing_points.append(timing_point)
		return true
		
	if current_section == "[HitObjects]":
		var note_data: Array = line.split(",")
		if len(note_data) != 6:
			print("hitobject has %s values, was expecting 6" % len(note_data))
			return false
		var note_type: String = get_note_type(note_data)
		if note_type == "tap": # tap note
			var note: Dictionary = {
				"lane": get_lane(note_data[0]),
				"time": get_time(note_data[2]),
				"type": note_type
			}
			receiver.notes.append(note)
			return true
		elif note_type == "hold_start": # hold note
			var start: Dictionary = {
				"lane": get_lane(note_data[0]),
				"time": get_time(note_data[2]),
				"end_time": get_time(note_data[5].split(":")[0]),
				"type": "hold_start"
			}
			var end: Dictionary = {
				"lane": start.lane,
				"time": get_time(note_data[5].split(":")[0]), # the first value of the comma-separated stuff at the end
				"type": "hold_end"
			}
			receiver.notes.append(start)
			receiver.notes.append(end)
			return true
		else:
			print("invalid note type ", note_type)
			return false
	return true

func get_lane(x: String) -> int:
	return int(x) * NUM_LANES_IN_SOURCE / 512
	
func get_time(x: String) -> float:
	return float(x) / 1000.0
	
func get_note_type(data: Array) -> String:
	var hold_flag: int = 1 << 7 # check the 7th bit, equivalent to 128
	var tap_flag: int = 1 # check the 0th bit
	if int(data[3]) & hold_flag != 0:
		return "hold_start"
	if int(data[3]) & tap_flag != 0:
		# possible extension: check hitsound to determine other types, which is why we pass in the whole array for this func
		return "tap"
	else: 
		return "other"
