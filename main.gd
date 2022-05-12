extends Control

var chart_node: Chart

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
	var file_data = chart_node.get_chart_data()
	file_data["audio_path"] = ""
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(JSON.print(file_data))
	file.close()


func _on_OpenFileDialog_file_selected(path):
	var file = File.new()
	file.open(path, File.READ)
	var chart_json = file.get_as_text()
	var result: JSONParseResult = JSON.parse(chart_json)
	if result.error != OK:
		push_error("File parsing failed at line %s: %s" % [result.error_line, result.error_string])
		return
	if typeof(result.result) != TYPE_DICTIONARY:
		push_error("chart data was not parsed as Dictionary")
		return
	chart_node.load_chart_data(result.result)
