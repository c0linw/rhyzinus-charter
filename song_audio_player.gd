extends AudioStreamPlayer

const BUS_NAME = "Pitch"
const BUS_INDEX = 1
const EFF_INDEX = 0

var custom_stream: ShinobuGodotSoundPlayback

var song_position: float = 0.0
var paused_position: float = 0.0

signal song_position_updated(new_position, max_position)
signal audio_loaded(new_length)

# Called when the node enters the scene tree for the first time.
func _ready():
	ShinobuGodot.initialize()
#	var shift = AudioEffectPitchShift.new()
#	shift.pitch_scale = 1.0
#
#	AudioServer.add_bus(BUS_INDEX)
#	AudioServer.set_bus_name(BUS_INDEX, BUS_NAME)
#	AudioServer.add_bus_effect(BUS_INDEX, shift, EFF_INDEX)
#	bus = BUS_NAME
	

func load_audio(path: String):
	var err = ShinobuGodot.register_sound_from_path(path, "music")
	if err != OK:
		push_error(err)
	custom_stream = ShinobuGodot.instantiate_sound("music", "")
	print(custom_stream.get_playback_position_msec())
	print(custom_stream.get_length_msec())

	song_position = 0.0
	paused_position = 0.0
	#seek(song_position)
	#emit_signal("audio_loaded", stream.get_length())
	#emit_signal("song_position_updated", song_position, stream.get_length())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_song_position()

func update_song_position():
	if custom_stream != null and custom_stream.is_playing():
		var new_position = get_playback_position()
		if new_position > song_position:
			song_position = new_position
			emit_signal("song_position_updated", song_position, get_stream_length())

func play_with_parameters(from_position: float, speed: float):
	# AudioStreamPlayer's pitch_scale modifies the speed AND the pitch
	#pitch_scale = speed
	
	# to compensate, use an inverse pitch shift effect 
	#var shift = AudioServer.get_bus_effect(BUS_INDEX, EFF_INDEX)
	#shift.pitch_scale = 1.0/speed
	
	seek(from_position)
	song_position = from_position
	custom_stream.start()
	
func stop():
	custom_stream.stop()
	song_position = 0.0

func pause():
	custom_stream.stop()

func seek(to_position: float):
	var previously_playing = custom_stream.is_playing()
	var new_position_ms = to_position * 1000
	custom_stream.seek(new_position_ms)
	song_position = to_position
	if previously_playing:
		custom_stream.start()
	
func get_playback_position() -> float:
	return custom_stream.get_playback_position_msec() / 1000.0
	
func get_stream_length() -> float:
	return custom_stream.get_length_msec() / 1000.0
	
func is_playing() -> bool:
	return custom_stream.is_playing()

func _on_Chart_custom_scroll(dir_multiplier):
	var new_position = song_position + 1.0*dir_multiplier
	seek(new_position)
	song_position = new_position
	emit_signal("song_position_updated", song_position, get_stream_length())


func _on_PlaybackSliderInput_playhead_scrub(percentage):
	var new_position = get_stream_length() * percentage
	seek(new_position)
	song_position = new_position
	emit_signal("song_position_updated", song_position, get_stream_length())
