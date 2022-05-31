extends Control

var chart_node: Chart
signal stream_changed(songaudioplayer)

# Called when the node enters the scene tree for the first time.
func _ready():
	$SongAudioPlayer.stream = load("res://songs/neutralizeptbmix/audio.mp3")
	chart_node = find_node("Chart")
	chart_node.update_chart_length($SongAudioPlayer.stream.get_length())
	yield(VisualServer, "frame_post_draw")
	$Loadscreen.visible = false
	$PanelContainer/VBoxContainer/TabContainer.set_current_tab(1)
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
	if $SongAudioPlayer.playing:
		$SongAudioPlayer.pause()
	else:
		var speed_option_node = find_node("PlaySpeedOption")
		var playback_speed = 1.0
		if speed_option_node != null:
			playback_speed = float(speed_option_node.text)
		$SongAudioPlayer.play_with_parameters($SongAudioPlayer.song_position, playback_speed) # TODO: play based on cursor position


func _on_VolumeSpinBox_value_changed(value):
	$SongAudioPlayer.volume_db = linear2db(value/100.0)


func _on_SelectAudioButton_pressed():
	$OpenAudioDialog.popup_centered()


func _on_OpenAudioDialog_file_selected(path):
	$SongAudioPlayer.load_audio(path)
