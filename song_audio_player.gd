extends AudioStreamPlayer

const BUS_NAME = "Pitch"
const BUS_INDEX = 1
const EFF_INDEX = 0

var song_position: float = 0.0
var paused_position: float = 0.0

signal song_position_updated(new_position, max_position)
signal audio_loaded(new_length)

# Called when the node enters the scene tree for the first time.
func _ready():
	var shift = AudioEffectPitchShift.new()
	shift.pitch_scale = 1.0
	
	AudioServer.add_bus(BUS_INDEX)
	AudioServer.set_bus_name(BUS_INDEX, BUS_NAME)
	AudioServer.add_bus_effect(BUS_INDEX, shift, EFF_INDEX)
	bus = BUS_NAME
	

func load_audio(path: String):
	stream = load(path)
	song_position = 0.0
	paused_position = 0.0
	seek(song_position)
	emit_signal("audio_loaded", stream.get_length())
	emit_signal("song_position_updated", song_position, stream.get_length())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_song_position()

func update_song_position():
	if playing:
		var new_position = get_playback_position() + AudioServer.get_time_since_last_mix()
		new_position -= AudioServer.get_output_latency()
		if new_position > song_position:
			song_position = new_position
			emit_signal("song_position_updated", song_position, stream.get_length())

func play_with_parameters(from_position: float, speed: float):
	# AudioStreamPlayer's pitch_scale modifies the speed AND the pitch
	pitch_scale = speed 
	
	# to compensate, use an inverse pitch shift effect 
	var shift = AudioServer.get_bus_effect(BUS_INDEX, EFF_INDEX)
	shift.pitch_scale = 1.0/speed
	
	play(from_position)
	
func stop():
	.stop()
	song_position = 0.0

func pause():
	.stop()
	
func unpause():
	play(paused_position)


func _on_Chart_custom_scroll(dir_multiplier):
	var new_position = song_position + 1.0*dir_multiplier
	seek(new_position)
	song_position = new_position
	emit_signal("song_position_updated", song_position, stream.get_length())


func _on_PlaybackSliderInput_playhead_scrub(percentage):
	var new_position = stream.get_length() * percentage
	seek(new_position)
	song_position = new_position
	emit_signal("song_position_updated", song_position, stream.get_length())
