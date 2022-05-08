extends Control

var chart_node: Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$SongAudioPlayer.stream = load("res://songs/neutralizeptbmix/audio.mp3")
	chart_node = find_node("Chart")
	chart_node.update_chart_length($SongAudioPlayer.stream.get_length())


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DropdownFileMenu_item_pressed(id):
	match id:
		0: $SaveFileDialog.popup_centered()
		1: $OpenFileDialog.popup_centered() # open .rzn file
		2: $ImportOsuDialog.popup_centered()


func _on_SaveFileDialog_file_selected(path):
	var note_data: Array = []
	for note in chart_node.notes:
		note_data.append({
			"time": note.time,
			"type": note.type,
			"lane": note.lane,
		})
	
	var timing_data: Array = []
	for timingpoint in chart_node.timing_points:
		var timingpoint_data = {
			"time": timingpoint.time,
			"type": timingpoint.type,
		}
		match timingpoint.type:
			"bpm": 
				timingpoint_data["beat_length"] = timingpoint.beat_length
				timingpoint_data["meter"] = timingpoint.meter
			"velocity":
				timingpoint_data["velocity"] = timingpoint.velocity
		timing_data.append(timingpoint_data)
	
	var file_data: Dictionary = {
		"audio_path": "",
		"notes": note_data,
		"timing_points": timing_data
	}
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(JSON.print(file_data))
	file.close()


func _on_OpenFileDialog_file_selected(path):
	pass # Replace with function body.
