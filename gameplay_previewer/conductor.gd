extends AudioStreamPlayerShinobu

var bpm


# Tracking the beat and song position
var time_begin: float
var time_delay: float
var last_paused: float

var beat_data: Array = []

var played_sfxs: Array = [] # manually free these when each one is done

class TimeSorter:
	# denotes the order in which these should be sorted, if there are objects with the same time
	const type_enum: Dictionary = {
		"bpm": 0, 
		"velocity": 1,
		"barline": 2,
		"tap": 3,
		"hold_start": 3,
		"hold_end": 3,
		"hold": 3
	}
	
	static func sort_ascending(a: Dictionary, b: Dictionary) -> bool:
		return a["time"] < b["time"]
		
	# use this after adding the timing points and notes into one array
	static func sort_ascending_with_type_priority(a: Dictionary, b: Dictionary) -> bool:
		if a["time"] < b["time"]:
			return true
		elif a["time"] == b["time"]:
			return type_enum[a["type"]] < type_enum[b["type"]]
		else:
			return false

func _ready():
	pass
	
func _process(delta):
	if len(played_sfxs) > 0:
		for sfx_player in played_sfxs.duplicate():
			if sfx_player.is_at_stream_end():
				sfx_player.queue_free()
				played_sfxs.erase(sfx_player)
	if stream != null and stream.is_at_stream_end() and not finish_signal_sent:
		emit_signal("finished")
		finish_signal_sent = true


func play_sfx(sfx_enum_value: int):
	var sfx_source = ShinobuGlobals.sfx_sources[sfx_enum_value]
	if sfx_source != null:
		var sfx_player = sfx_source.instantiate(ShinobuGlobals.sfx_group)
		played_sfxs.append(sfx_player)
		sfx_player.start()
