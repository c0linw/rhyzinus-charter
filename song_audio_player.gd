extends Node


const CUSTOM_STREAM_OFFSET = 0.05 # for some reason fire-and-forget sounds have a different latency from the instantiated sound

enum sfx_enums {SFX_NONE, SFX_CLICK, SFX_SWIPE}

var chart_node: Node
var audio_path: String = ""

var custom_stream: ShinobuSoundPlayer
var pitch_shift: ShinobuPitchShiftEffect
var music_group: ShinobuGroup
var sfx_group: ShinobuGroup

var song_position: float = 0.0
var paused_position: float = 0.0
var playback_speed: float = 1.0

var sfx_sources: Array
var queued_sfx_times: Array = [] # array of Dictionaries, containing note times and sound enumerator
var sfx_index: int = 0
var played_sfxs: Array = [] # manually free these when each one is done

signal song_position_updated(new_position, max_position)
signal audio_loaded(new_length)

# Called when the node enters the scene tree for the first time.
func _ready():
	Shinobu.initialize()
	pitch_shift = Shinobu.instantiate_pitch_shift()
	pitch_shift.connect_to_endpoint()
	
	chart_node = get_tree().get_nodes_in_group("chart")[0]
	
	# load the note sound effects
	var click_file = File.new()
	click_file.open("res://sound/click.wav", File.READ)
	var buffer = click_file.get_buffer(click_file.get_len())
	click_file.close()
	var click_source = Shinobu.register_sound_from_memory("click", buffer)
	
	var swipe_file = File.new()
	swipe_file.open("res://sound/swipe.wav", File.READ)
	var buffer2 = swipe_file.get_buffer(swipe_file.get_len())
	swipe_file.close()
	var swipe_source = Shinobu.register_sound_from_memory("swipe", buffer2)
	
	sfx_sources.resize(sfx_enums.size())
	sfx_sources[sfx_enums.SFX_CLICK] = click_source
	sfx_sources[sfx_enums.SFX_SWIPE] = swipe_source
	
	sfx_group = Shinobu.create_group("sfx_group", null)
	music_group = Shinobu.create_group("music", null)
	music_group.connect_to_effect(pitch_shift)

func load_audio(path: String) -> int:
	# shinobu audio will literally try to load any file, so at least check the filetype (maybe try header check when i have more time)
	if not (path.ends_with(".mp3") or path.ends_with(".wav") or path.ends_with(".ogg")):
		return FAILED
		
	unload_audio()
	
	var file = File.new()
	var err = file.open(path, File.READ)
	if err != OK:
		return err
	var buffer = file.get_buffer(file.get_len())
	file.close()
	var sound_source := Shinobu.register_sound_from_memory("music", buffer)
	audio_path = path
	custom_stream = sound_source.instantiate(music_group)
	#custom_stream.connect_sound_to_effect(pitch_shift)
	custom_stream.pitch_scale = playback_speed
	add_child(custom_stream)

	song_position = 0.0
	paused_position = 0.0
	seek(song_position)
	emit_signal("audio_loaded", get_stream_length())
	emit_signal("song_position_updated", song_position, get_stream_length())
	
	return OK

func unload_audio():
	if custom_stream != null:
		custom_stream.queue_free()
		remove_child(custom_stream)
		custom_stream = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_song_position()
	if custom_stream != null and custom_stream.is_playing() and len(queued_sfx_times) > 0:
		while sfx_index < len(queued_sfx_times) and song_position >= queued_sfx_times[sfx_index].time:
			var sfx_source = sfx_sources[queued_sfx_times[sfx_index].type]
			if sfx_source != null:
				var sfx_player = sfx_source.instantiate(sfx_group)
				played_sfxs.append(sfx_player)
				sfx_player.start()
			sfx_index += 1
	for sfx_player in played_sfxs.duplicate():
		if sfx_player.is_at_stream_end():
			sfx_player.queue_free()
			played_sfxs.erase(sfx_player)

func update_song_position():
	if custom_stream != null and custom_stream.is_playing():
		var new_position = get_playback_position() - Shinobu.get_actual_buffer_size() / 1000.0
		if new_position > song_position:
			song_position = new_position
			emit_signal("song_position_updated", song_position, get_stream_length())

func play_from_position(from_position: float):
	if custom_stream != null:
		seek(from_position)
		song_position = from_position
		var err = custom_stream.start()
		if err != OK:
			print(err)
	
func stop():
	if custom_stream != null:
		var err = custom_stream.stop()
		if err != OK:
			print(err)
		song_position = 0.0

func pause():
	if custom_stream != null:
		custom_stream.stop()

func seek(to_position: float):
	if custom_stream == null:
		return
	var previously_playing = custom_stream.is_playing()
	var new_position_ms = to_position * 1000
	var err = custom_stream.seek(new_position_ms)
	if err != OK:
		print(err)
	song_position = to_position
	
	queued_sfx_times = chart_node.get_note_times_since_time(to_position)
	sfx_index = 0
	
	if previously_playing:
		custom_stream.start()
	
func get_playback_position() -> float:
	if custom_stream == null:
		return 0.0
	return (custom_stream.get_playback_position_msec() - Shinobu.get_actual_buffer_size()) / 1000.0 - CUSTOM_STREAM_OFFSET
	
func get_stream_length() -> float:
	if custom_stream == null:
		return 0.0
	return custom_stream.get_length_msec() / 1000.0
	
func is_playing() -> bool:
	if custom_stream == null:
		return false
	return custom_stream.is_playing()
	
func set_volume(linear_volume: float):
	if custom_stream != null:
		custom_stream.set_volume(linear_volume)
		
func set_sfx_volume(linear_volume: float):
	sfx_group.set_volume(linear_volume)
	
func set_playback_speed(speed: float):
	pitch_shift.set_pitch_scale(1.0/speed)
	playback_speed = speed
	if custom_stream != null:
		custom_stream.set_pitch_scale(speed)

func _on_Chart_custom_scroll(dir_multiplier):
	var new_position = clamp(song_position + 0.5*dir_multiplier, 0.0, get_stream_length())
	seek(new_position)
	song_position = new_position
	emit_signal("song_position_updated", song_position, get_stream_length())

func _on_PlaybackSliderInput_playhead_scrub(percentage):
	var new_position = get_stream_length() * percentage
	seek(new_position)
	song_position = new_position
	emit_signal("song_position_updated", song_position, get_stream_length())
