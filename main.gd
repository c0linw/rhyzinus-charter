extends Control

var chart_node: Chart
signal stream_changed(songaudioplayer)

# Called when the node enters the scene tree for the first time.
func _ready():
	chart_node = find_node("Chart")
	yield(VisualServer, "frame_post_draw")
	
	$Loadscreen.visible = false
	
	$PanelContainer/VBoxContainer/TabContainer.set_current_tab(1)
	$PanelContainer/VBoxContainer/TabContainer.set_tab_disabled(0, true)
	
	chart_node.SongAudioPlayer = $SongAudioPlayer


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DropdownFileMenu_item_pressed(id):
	match id:
		0: pass # new project
		1: $SaveFileDialog.popup_centered()
		2: $OpenFileDialog.popup_centered() # open .rzn file
		3: $ImportOsuDialog.popup_centered()


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


func _on_ImportOsuDialog_file_selected(path):
	var result = $OsuConverter.load_chart(path)
	if result == null:
		push_error(".osu chart loading failed")
		return
	chart_node.load_chart_data(result)


func _on_PlayButton_pressed():
	if $SongAudioPlayer.is_playing():
		$SongAudioPlayer.pause()
	else:
		$SongAudioPlayer.play_from_position($SongAudioPlayer.song_position)


func _on_VolumeSpinBox_value_changed(value):
	$SongAudioPlayer.set_volume(value/100.0)


func _on_SelectAudioButton_pressed():
	$OpenAudioDialog.popup_centered()


func _on_OpenAudioDialog_file_selected(path):
	var err = $SongAudioPlayer.load_audio(path)
	var audio_status_label = find_node("AudioSelectStatusLabel")
	audio_status_label.report_status(err)
	if err == OK:
		$PanelContainer/VBoxContainer/TabContainer.set_tab_disabled(0, false)


func _on_PlaySpeedOption_item_selected(index):
	var speed_options = [0.25, 0.5, 0.75, 1.0]
	$SongAudioPlayer.set_playback_speed(speed_options[index])
