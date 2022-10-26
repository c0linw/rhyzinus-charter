extends Node2D
# Loads the chart data from a file into the chart_data object, then switches the scene to Game

var audio_path: String
var chart_path: String
var current_section: String = ""
const NUM_LANES_IN_SOURCE: int = 14 # defaults to 14 key osu mania file, but supports anything 12 or above

# Called when the node enters the scene tree for the first time.
func _ready():
	chart_path = SceneSwitcher.get_param("chart_path")
	audio_path = SceneSwitcher.get_param("audio_path")
	if not load_chart(chart_path, $chart_data):
		var data: Dictionary = {
			"popup_msg": "Chart loading failed!"
		}
		print("attempting to change to song select")
		SceneSwitcher.change_scene("res://scenes/song_select/song_select.tscn", data)
		return

	Settings.read_settings_file()
	var options: Dictionary = {
		"audio_offset": Settings.setting_values["audio_offset"] / 1000.0,
		"input_offset": Settings.setting_values["input_offset"] / 1000.0,
		"note_speed": Settings.setting_values["note_speed"]
	}
	$chart_data.offset = options["audio_offset"]
	var data = {
		"chart_data": $chart_data.export_data(), 
		"audio_path": audio_path,
		"options": options,
		"song_title": SceneSwitcher.get_param("song_title"),
		"diff_name": SceneSwitcher.get_param("diff_name"),
		"diff_level": SceneSwitcher.get_param("diff_level"),
		"jacket_path": SceneSwitcher.get_param("jacket_path")
		}
	yield(get_tree(), "idle_frame")
	if SceneSwitcher.change_scene("res://scenes/game/game.tscn", data) != OK:
		print ("Error changing scene to Game")
		return


func load_chart(file_path: String, receiver: Node) -> bool:
	var file := File.new()
	if not file.file_exists(file_path):
		print("Missing chart file ", file_path)
		file.close()
		return false
	var err = file.open_compressed(file_path, File.READ, File.COMPRESSION_DEFLATE)
	if err:
		print("Error %s while opening file: %s" % [err, file_path])
		file.close()
		return false
	var chart_json = file.get_as_text()
	file.close()
	var result: JSONParseResult = JSON.parse(chart_json)
	if result.error != OK:
		push_error("File parsing failed at line %s: %s" % [result.error_line, result.error_string])
		return false
	if typeof(result.result) != TYPE_DICTIONARY:
		push_error("chart data was not parsed as Dictionary")
		return false
	receiver.notes = result.result.notes
	receiver.timing_points = result.result.bpm_changes
	receiver.timing_points.append_array(result.result.velocity_changes)
	return true

# loads the .osu chart file and processes every line until the end. Returns true if successful.
func load_chart_old(file_path: String, receiver: Node) -> bool:
	# get data from file
	var file := File.new()
	if not file.file_exists(file_path):
		print("Missing chart file ", file_path)
		return false
	var err := file.open(file_path, File.READ)
	if err:
		print("Error %s while opening file: %s" % [err, file_path])
		return false
	while not file.eof_reached():
		var line := file.get_line()
		if line == "":
			continue
		if not process_chart_line(line, receiver):
			print("skipped invalid line: ", line)
	file.close()
	return true

# processes one line of the chart file. Returns true if the line was valid (even if skipped)
func process_chart_line(line: String, receiver: Node) -> bool:
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
				"beat_length": float(timing_data[1]) / 1000.0, # beat length, in milliseconds
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

func prepare_conductor():
	pass
