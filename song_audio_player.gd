extends AudioStreamPlayer

const BUS_NAME = "Pitch"
const BUS_INDEX = 1
const EFF_INDEX = 0

var audio_path: String = ""

var custom_stream: ShinobuGodotSoundPlayback
var pitch_shift: ShinobuGodotEffectPitchShift

var song_position: float = 0.0
var paused_position: float = 0.0
var playback_speed: float = 1.0

signal song_position_updated(new_position, max_position)
signal audio_loaded(new_length)

# Called when the node enters the scene tree for the first time.
func _ready():
	ShinobuGodot.initialize()
	pitch_shift = ShinobuGodot.instantiate_pitch_shift()

func load_audio(path: String) -> int:
	# shinobu audio will literally try to load any file, so at least check the filetype (maybe try header check when i have more time)
	if not (path.ends_with(".mp3") or path.ends_with(".wav") or path.ends_with(".ogg")):
		return FAILED
	
	custom_stream = null
	ShinobuGodot.unregister_sound("music")
	var err = ShinobuGodot.register_sound_from_path(path, "music")
	if err != OK:
		return err
	audio_path = path
	custom_stream = ShinobuGodot.instantiate_sound("music", "")
	custom_stream.connect_sound_to_effect(pitch_shift)
	custom_stream.pitch_scale = playback_speed

	song_position = 0.0
	paused_position = 0.0
	seek(song_position)
	emit_signal("audio_loaded", get_stream_length())
	emit_signal("song_position_updated", song_position, get_stream_length())
	
	return OK

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_song_position()

func update_song_position():
	if custom_stream != null and custom_stream.is_playing():
		var new_position = get_playback_position()
		if new_position > song_position:
			song_position = new_position
			emit_signal("song_position_updated", song_position, get_stream_length())

func play_from_position(from_position: float):
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
	return (custom_stream.get_playback_position_msec() - ShinobuGodot.get_actual_buffer_size()) / 1000.0
	
func get_stream_length() -> float:
	return custom_stream.get_length_msec() / 1000.0
	
func is_playing() -> bool:
	return custom_stream.is_playing()
	
func set_volume(linear_volume: float):
	custom_stream.set_volume(linear_volume)
	
func set_playback_speed(speed: float):
	playback_speed = speed
	custom_stream.set_pitch_scale(speed)
	pitch_shift.set_pitch_scale(1.0/speed)

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
