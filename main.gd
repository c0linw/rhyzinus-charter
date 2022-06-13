extends Control

enum actions {NEW, SAVE, SAVEAS, OPEN, IMPORT}

var chart_node: Chart
var saved_path: String = ""
signal stream_changed(songaudioplayer)

# Called when the node enters the scene tree for the first time.
func _ready():
	chart_node = find_node("Chart")
	yield(VisualServer, "frame_post_draw")
	
	$Loadscreen.visible = false
	
	$PanelContainer/VBoxContainer/TabContainer.set_current_tab(1)
	$PanelContainer/VBoxContainer/TabContainer.set_tab_disabled(0, true)
	EditorStatus.set_status("Ready")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DropdownFileMenu_item_pressed(id):
	match id:
		0: perform_toolbar_action(actions.NEW)
		1: perform_toolbar_action(actions.SAVE)
		2: perform_toolbar_action(actions.SAVEAS)
		3: perform_toolbar_action(actions.OPEN)
		4: perform_toolbar_action(actions.IMPORT)


func _on_SaveFileDialog_file_selected(path):
	var file_data = chart_node.get_chart_data()
	file_data["audio_path"] = $SongAudioPlayer.audio_path
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(JSON.print(file_data))
	file.close()
	saved_path = path
	EditorStatus.set_saved()

func _on_OpenFileDialog_file_selected(path):
	var file = File.new()
	var err = file.open(path, File.READ)
	if err != OK:
		push_error("Failed to open file, err: %s" % err)
		return
	var chart_json = file.get_as_text()
	var result: JSONParseResult = JSON.parse(chart_json)
	if result.error != OK:
		push_error("File parsing failed at line %s: %s" % [result.error_line, result.error_string])
		return
	if typeof(result.result) != TYPE_DICTIONARY:
		push_error("chart data was not parsed as Dictionary")
		return
	load_audio(result.result.audio_path)
	chart_node.load_chart_data(result.result)
	saved_path = path

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
	load_audio(path)


func _on_PlaySpeedOption_item_selected(index):
	var speed_options = [0.25, 0.5, 0.75, 1.0]
	$SongAudioPlayer.set_playback_speed(speed_options[index])
	
func load_audio(path: String):
	var line_edit = find_node("AudioPathLineEdit")
	line_edit.text = path
	
	# quietly switch to "edit" tab while loading so that the chart size is properly updated, then switch back
	$Loadscreen.visible = true
	var tab_idx = $PanelContainer/VBoxContainer/TabContainer.current_tab
	$PanelContainer/VBoxContainer/TabContainer.set_current_tab(0)

	var err = $SongAudioPlayer.load_audio(path)
	yield(VisualServer, "frame_post_draw")
	
	if err != OK:
		$PanelContainer/VBoxContainer/TabContainer.set_current_tab(1)
		$PanelContainer/VBoxContainer/TabContainer.set_tab_disabled(0, true)
	else: 
		$SongAudioPlayer.emit_signal("song_position_updated", $SongAudioPlayer.song_position, $SongAudioPlayer.get_stream_length())
		$PanelContainer/VBoxContainer/TabContainer.set_current_tab(tab_idx)
		$PanelContainer/VBoxContainer/TabContainer.set_tab_disabled(0, false)
	
	$Loadscreen.visible = false
	var audio_status_label = find_node("AudioSelectStatusLabel")
	audio_status_label.report_status(err)
	
func new_project():
	# TODO: prompt if want to save?
	$SongAudioPlayer.unload_audio()
	$PanelContainer/VBoxContainer/TabContainer.set_current_tab(1)
	$PanelContainer/VBoxContainer/TabContainer.set_tab_disabled(0, true)
	chart_node.reset_chart_data()
	
	var line_edit = find_node("AudioPathLineEdit")
	line_edit.text = ""
	var audio_status_label = find_node("AudioSelectStatusLabel")
	audio_status_label.reset_status()
	saved_path = ""

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().quit() # default behavior. TODO: prompt user for save


func _on_TabContainer_tab_changed(tab):
	if tab != 0:
		$SongAudioPlayer.pause()
		
func _input(event):
	if event is InputEventKey and event.pressed and !event.echo:
		if event.control:
			match event.scancode:
				KEY_S:
					if event.shift:
						perform_toolbar_action(actions.SAVEAS)
					else:
						perform_toolbar_action(actions.SAVE)
				KEY_O:
					perform_toolbar_action(actions.OPEN)
				KEY_N:
					perform_toolbar_action(actions.NEW)
				KEY_I:
					perform_toolbar_action(actions.IMPORT)
					
func perform_toolbar_action(action: int):
	for node in get_tree().get_nodes_in_group("popups"):
		node.hide()
	match action:
		actions.NEW: new_project()
		actions.SAVE: 
			var file_valid: bool = false
			var file = File.new()
			if saved_path != "":
				var err = file.open(saved_path, File.WRITE)
				if err == OK:
					file_valid = true
			
			if file_valid:
				var file_data = chart_node.get_chart_data()
				file_data["audio_path"] = $SongAudioPlayer.audio_path
				file.store_line(JSON.print(file_data))
				EditorStatus.set_saved()
			else:
				$SaveFileDialog.popup_centered()
			file.close()
		actions.SAVEAS: $SaveFileDialog.popup_centered()
		actions.OPEN: $OpenFileDialog.popup_centered() # open .rzn file
		actions.IMPORT: $ImportOsuDialog.popup_centered()
