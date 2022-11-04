extends Spatial

# enums and constants
enum {CORRUPTED, CRACKED, DECRYPTED, FLAWLESS}
enum BeatType {MEASURE, BEAT, SUBDIVISION}

# audio stuff
var audio
var conductor: AudioStreamPlayerShinobu

# gameplay stuff
var audio_offset: float = 0.0
var note_speed: float # speed range: 1.0 - 10.0
var base_note_screen_time: float

var chart_data # load chart into this variable, and copy its child arrays to the below arrays
var notes_to_spawn: Array = []
var scrollmod_list: Array = []
var barlines_to_spawn: Array = []
var beat_data: Array = []
var simlines_to_spawn: Array = []

var onscreen_notes: Array = []
var onscreen_barlines: Array = []
var onscreen_simlines: Array = []

var starting_bpm: float
var sv_velocity: float = 1.0
var last_timestamp: float = 0.0
var chart_position: float = 0.0
var notecount: int = 0

# Measurements, useful for positioning-related calculations
var lane_depth: float

var lower_lane_width: float
var lower_lane_left: Vector2
var lower_lane_right: Vector2

var upper_lane_width: float
var upper_lane_left: Vector2
var upper_lane_right: Vector2

# Preload objects
var ObjNoteTap = preload("res://gameplay_previewer/notes/note_tap.tscn")
var ObjNoteTapSide = preload("res://gameplay_previewer/notes/note_tap_side.tscn")
var ObjNoteTapUpper = preload("res://gameplay_previewer/notes/note_tap_upper.tscn")
var ObjNoteHold = preload("res://gameplay_previewer/notes/note_hold.tscn")
var ObjNoteHoldSide = preload("res://gameplay_previewer/notes/note_hold_side.tscn")
var ObjNoteHoldUpper = preload("res://gameplay_previewer/notes/note_hold_upper.tscn")
var ObjNoteSwipe = preload("res://gameplay_previewer/notes/note_swipe.tscn")
var ObjNoteSwipeSide = preload("res://gameplay_previewer/notes/note_swipe_side.tscn")
var ObjBarline = preload("res://gameplay_previewer/entities/barline.tscn")
var ObjBarlineUpper = preload("res://gameplay_previewer/entities/barline_upper.tscn")
var ObjJudgementTexture = preload("res://gameplay_previewer/entities/judgement_texture.tscn")
var ObjSimline = preload("res://gameplay_previewer/entities/simline.tscn")
var ObjNoteEffect = preload("res://gameplay_previewer/effect/note_effect.tscn")

# Input-related stuff
var input_zones: Array = []
var lane_zones: Array = []
var touch_bindings: Array = [] # keeps track of touch input events
var input_offset: float = 0.0

const SWIPE_THRESHOLD_LANES: float = 0.2 # how many lanes of distance are required to activate a swipe
var swipe_threshold_px: float = 0 # set this value after lane dimensions are calculated

var judgement_sources: Dictionary = {
	"tap": 0,
	"release": 0,
	"end_miss": 0,
	"end_hit": 0,
	"start_hit": 0,
	"start_hit_tiebreaker": 0,
	"start_pass": 0,
	"note_pass": 0,
	"hold_tick": 0,
	"tiebreaker": 0,
}

# Effects
var lane_effects: Array = []
var judgement_textures: Array = []

signal note_judged(result)
signal beat(measure, beat)
signal pause

class TimeSorter:
	# denotes the order in which these should be sorted, if there are objects with the same time
	const type_enum: Dictionary = {
		"bpm": 0, 
		"velocity": 1,
		"barline": 2,
		"tap": 3,
		"swipe": 3,
		"hold_start": 3,
		"hold_end": 3,
		"hold": 3
	}
	
	static func sort_time_ascending(a: Dictionary, b: Dictionary) -> bool:
		return a["time"] < b["time"]
		
	# use this after adding the timing points and notes into one array
	static func sort_time_ascending_with_type_priority(a: Dictionary, b: Dictionary) -> bool:
		if a["time"] < b["time"]:
			return true
		elif a["time"] == b["time"]:
			return type_enum[a["type"]] < type_enum[b["type"]]
		else:
			return false
			
	static func sort_chart_position_ascending(a: Dictionary, b: Dictionary) -> bool:
		return a["position"] < b["position"]

# Called when the node enters the scene tree for the first time.
func _ready():
	var bg_dim_setting = 3
	var bg_dim_value = 0.125 + (5 - bg_dim_setting) * 0.050
	find_node("Gameplay_bg").self_modulate = Color(bg_dim_value, bg_dim_value, bg_dim_value, 1.0)
	
	note_speed = 7.5
	lane_depth = 24.0
	
	######## SETUP OBJECTS
	base_note_screen_time = get_note_screen_time(7.0) # default value, may get overridden by NoteSpeedSpinbox
	
	#notes_to_spawn = chart_data["notes"].duplicate()
	#scrollmod_list = chart_data["timing_points"].duplicate()
	#barlines_to_spawn = chart_data["barlines"].duplicate()
	#beat_data = chart_data["beats"].duplicate()
	#notecount = chart_data["notecount"]
	#simlines_to_spawn = chart_data["simlines"].duplicate()
	
	######## SETUP INPUT
	setup_judgement_textures()

func set_conductor_node(conductor_node: Node):
	conductor = conductor_node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if conductor == null or not conductor.is_playing():
		return
	var timestamp = conductor.song_position
	for sv in scrollmod_list:
		if timestamp >= sv["time"]:
			apply_timing_point(sv)
		else:
			break
	
	chart_position += (timestamp - last_timestamp) * sv_velocity
	
	spawn_entities(chart_position)
			
	var barlines_to_delete: Array
	for barline in onscreen_barlines:
		if chart_position >= barline.chart_position:
			barlines_to_delete.append(barline)
		else:
			barline.render(chart_position, lane_depth, base_note_screen_time)
	for barline in barlines_to_delete:
		remove_barline(barline)
			
	var simlines_to_delete: Array
	for simline in onscreen_simlines:
		if chart_position >= simline.chart_position:
			simlines_to_delete.append(simline)
		else:
			simline.render(chart_position, lane_depth, base_note_screen_time)
	for simline in simlines_to_delete:
		remove_simline(simline)

	
	var notes_to_delete: Array
	# check for notes that are too late, then render the rest
	for note in onscreen_notes:
		note.render(chart_position, lane_depth, base_note_screen_time)
		if note.is_in_group("swipes") and timestamp >= note.time + input_offset and note.completed:
			var result = {"judgement": FLAWLESS, "offset": 0}
			draw_judgement(result, note.lane)
			#$Conductor.play_sfx(ShinobuGlobals.sfx_enums.SFX_SWIPE)
			emit_signal("note_judged", result)
			notes_to_delete.append(note)
		if note.is_in_group("holds") and timestamp > note.end_time + input_offset:
			if note.held:
				var result = {"judgement": FLAWLESS, "offset": 0}
				draw_judgement(result, note.lane)
				#$Conductor.play_sfx(ShinobuGlobals.sfx_enums.SFX_CLICK)
				emit_signal("note_judged", result)
				judgement_sources["end_hit"] += 1
				notes_to_delete.append(note)
			if !note.held and timestamp > note.end_time + note.late_cracked + input_offset:
				var result = {"judgement": CORRUPTED, "offset": 0}
				draw_judgement(result, note.lane)
				emit_signal("note_judged", result)
				judgement_sources["end_miss"] += 1
				notes_to_delete.append(note)
		elif timestamp >= note.time + note.late_cracked + input_offset:
			if note.is_in_group("holds"):
				if !note.head_judged:
					if !note.activated:
						var result = {"judgement": CORRUPTED, "offset": 0}
						draw_judgement(result, note.lane)
						emit_signal("note_judged", result)
						judgement_sources["start_pass"] += 1
					note.head_judged = true
			else:
				var result = {"judgement": CORRUPTED, "offset": 0}
				draw_judgement(result, note.lane)
				emit_signal("note_judged", result)
				judgement_sources["note_pass"] += 1
				notes_to_delete.append(note)
	for note in notes_to_delete:
		delete_note(note)
		
	# check hold ticks
	for hold in get_tree().get_nodes_in_group("holds"):
		var ticks_to_delete: Array
		for tick in hold.ticks:
			if timestamp >= tick:
				var result: Dictionary
				if hold.activated and hold.held:
					result = {"judgement": FLAWLESS, "offset": 0}
				else:
					result = {"judgement": CORRUPTED, "offset": 0}
				draw_judgement(result, hold.lane)
				emit_signal("note_judged", result)
				judgement_sources["hold_tick"] += 1
				ticks_to_delete.append(tick)
			else:
				break
		for tick in ticks_to_delete:
			hold.ticks.erase(tick)
		
	var beats_to_delete: Array
	for beat in beat_data:
		if timestamp >= beat["time"]:
			emit_signal("beat", beat["measure"], beat["beat"])
			beats_to_delete.append(beat)
		else: 
			break
	for beat in beats_to_delete:
		beat_data.erase(beat)

	last_timestamp = timestamp
	
func spawn_entities(chart_position: float): 
	var spawnable_barlines: Array
	for barline_data in barlines_to_spawn:
		if chart_position >= barline_data["position"] - base_note_screen_time:
			spawnable_barlines.append(barline_data)
		else:
			break # assumes all barlines are stored in ascending time
	for barline_data in spawnable_barlines:
		spawn_barline(barline_data)
	
	var spawnable_notes: Array
	for note_data in notes_to_spawn:
		if chart_position >= note_data["position"] - base_note_screen_time:
			spawnable_notes.append(note_data)
		else:
			break # assumes all notes are stored in ascending time
	for note_data in spawnable_notes:
		spawn_note(note_data)
			
	var spawnable_simlines: Array
	for simline_data in simlines_to_spawn:
		if chart_position >= simline_data["position"] - base_note_screen_time:
			spawnable_simlines.append(simline_data)
		else:
			break # assumes all simlines are stored in ascending time
	for simline_data in spawnable_simlines:
		spawn_simline(simline_data)

func apply_timing_point(sv: Dictionary):
	# account for any bit of the old scrollmod that was missed
	chart_position += (sv["time"]-last_timestamp)*sv_velocity 
	if sv["type"] == "bpm":
		var new_bpm: float = (60.0 / sv["beat_length"])
		# TODO: keep or remove? might be useful later
	elif sv["type"] == "velocity":
		sv_velocity = sv["velocity"]
	last_timestamp = sv["time"] # set up to add remaining part under new scrollmod
	scrollmod_list.erase(sv)
	
func spawn_note(note_data: Dictionary):
	var note_instance: Note3D
	if note_data["type"] == "tap":
		if note_data["lane"] == 0 || note_data["lane"] == 7:
			note_instance = ObjNoteTapSide.instance()
		elif note_data["lane"] > 9:
			note_instance = ObjNoteTapUpper.instance()
		else:
			note_instance = ObjNoteTap.instance()
	elif note_data["type"] == "hold":
		if note_data["lane"] == 0 || note_data["lane"] == 7:
			note_instance = ObjNoteHoldSide.instance()
		elif note_data["lane"] > 9:
			note_instance = ObjNoteHoldUpper.instance()
		else:
			note_instance = ObjNoteHold.instance()
		note_instance.end_time = note_data["end_time"]
		note_instance.end_position = note_data["end_position"]
		note_instance.ticks = note_data["ticks"]
	elif note_data["type"] == "swipe":
		if note_data["lane"] == 0 || note_data["lane"] == 7:
			note_instance = ObjNoteSwipeSide.instance()
		else:
			note_instance = ObjNoteSwipe.instance()
	else:
		return
	note_instance.time = note_data["time"]
	note_instance.chart_position = note_data["position"]
	note_instance.lane = note_data["lane"]
	notes_to_spawn.erase(note_data)
	onscreen_notes.append(note_instance)
	if note_instance.lane == 0:
		$Lanes_lower/Left.add_child(note_instance)
	elif note_instance.lane < 7:
		$Lanes_lower.add_child(note_instance)
	elif note_instance.lane == 7:
		$Lanes_lower/Right.add_child(note_instance)
	else:
		$Lanes_upper.add_child(note_instance)
		
func spawn_barline(barline_data: Dictionary):
	var barline_lower = ObjBarline.instance()
	barline_lower.time = barline_data["time"]
	barline_lower.chart_position = barline_data["position"]
	barlines_to_spawn.erase(barline_data)
	onscreen_barlines.append(barline_lower)
	$Lanes_lower.add_child(barline_lower)
	
	var barline_upper = ObjBarlineUpper.instance()
	barline_upper.time = barline_data["time"]
	barline_upper.chart_position = barline_data["position"]
	barlines_to_spawn.erase(barline_data)
	onscreen_barlines.append(barline_upper)
	$Lanes_upper.add_child(barline_upper)
	
func remove_barline(barline_to_remove):
	onscreen_barlines.erase(barline_to_remove)
	barline_to_remove.queue_free()
	
func spawn_simline(simline_data: Dictionary):
	if len(simline_data.upper) == 0 or len(simline_data.lower) == 0:
		simlines_to_spawn.erase(simline_data)
		return
	for upper in simline_data.upper.keys():
		for lower in simline_data.lower.keys():
			var simline = ObjSimline.instance()
			simline.time = simline_data["time"]
			simline.chart_position = simline_data["position"]
			simlines_to_spawn.erase(simline_data)
			onscreen_simlines.append(simline)
			
			simline.set_ends(lower, upper, $Lanes_lower.translation, $Lanes_upper.translation)
			$Lanes_lower.add_child(simline)
	
func remove_simline(simline_to_remove):
	onscreen_simlines.erase(simline_to_remove)
	simline_to_remove.queue_free()


func setup_judgement_textures():
	judgement_textures.resize(1)
	var pics: Array = [
		load("res://gameplay_previewer/textures/flawless.png")
		]
	for i in len(judgement_textures):
		judgement_textures[i] = ImageTexture.new()
		judgement_textures[i].create_from_image(pics[i].get_data())


func draw_judgement(data: Dictionary, lane: int):
	var judgement = ObjJudgementTexture.instance()
	var tex: ImageTexture
	
	var play_effect := false
	match data["judgement"]:
		FLAWLESS: 
			tex = judgement_textures[FLAWLESS]
			play_effect = true
		_:
			return
	judgement.setup(tex, lower_lane_width)
	judgement.position = Vector2(input_zones[lane].center.x - lower_lane_width/2, input_zones[lane].center.y - lower_lane_width/2)
	$CanvasLayer.add_child(judgement)
	
	if play_effect:
		play_effect(lane)
	

func play_effect(lane: int):
	var fx = ObjNoteEffect.instance()
	fx.position = input_zones[lane].center
	var width = upper_lane_width if lane >= 10 else lower_lane_width
	fx.scale_to_width(width * 1.5)
	if lane == 0:
		fx.rotation_degrees = 90
	elif lane == 7:
		fx.rotation_degrees = -90
	$CanvasLayer.add_child(fx)
		
func delete_note(note: Note3D):
	onscreen_notes.erase(note)
	note.queue_free()


func _on_Chart_reload_preview(chart_node):
	reload_chart(chart_node)

# reset onscreen_notes and notes_to_spawn, etc. when seeking to new audio positon
func seek_to_playback_time(timestamp: float):
	for barline in onscreen_barlines:
		barline.queue_free()
	onscreen_barlines = []
	
	for simline in onscreen_simlines:
		simline.queue_free()
	onscreen_simlines = []
	
	for note in onscreen_notes:
		note.queue_free()
	onscreen_notes = []
	
	notes_to_spawn = chart_data.notes.duplicate()
	scrollmod_list = chart_data.timing_points.duplicate()
	barlines_to_spawn = chart_data.barlines.duplicate()
	beat_data = chart_data.beats.duplicate()
	simlines_to_spawn = chart_data.simlines.duplicate()
	
	# use scrollmods to calculate current chart position
	last_timestamp = 0.0
	sv_velocity = 1.0
	chart_position = 0.0
	for sv in scrollmod_list.duplicate():
		if timestamp >= sv["time"]:
			apply_timing_point(sv)
		else:
			break
	chart_position += (timestamp - last_timestamp) * sv_velocity
	
	# remove everything with timestamp before current chart position, and spawn anything that is within screen visible time
	# if chart_position >= barline_data["position"] - base_note_screen_time:)
	notes_to_spawn = truncate_values_before_position(notes_to_spawn, chart_position)
	barlines_to_spawn = truncate_values_before_position(barlines_to_spawn, chart_position)
	beat_data = truncate_values_before_time(beat_data, timestamp)
	simlines_to_spawn = truncate_values_before_position(simlines_to_spawn, chart_position)
	
	spawn_entities(chart_position)
	for note in onscreen_notes:
		note.render(chart_position, lane_depth, base_note_screen_time)
	for simline in onscreen_simlines:
		simline.render(chart_position, lane_depth, base_note_screen_time)
	for barline in onscreen_barlines:
		barline.render(chart_position, lane_depth, base_note_screen_time)
	
	last_timestamp = timestamp
	
func truncate_values_before_position(values: Array, chart_position: float) -> Array:
	var dummy := {"position": chart_position} # bsearch_custom needs a dictonary as input to make the comparisons work
	var i: int = values.bsearch_custom(dummy, TimeSorter, "sort_chart_position_ascending", false)
	return values.slice(i, len(values)-1)
	
func truncate_values_before_time(values: Array, timestamp: float) -> Array:
	var dummy := {"time": timestamp} # bsearch_custom needs a dictonary as input to make the comparisons work
	var i: int = values.bsearch_custom(dummy, TimeSorter, "sort_time_ascending", false)
	return values.slice(i, len(values)-1)

# reprocess all entities
func reload_chart(chart_node: Node):
	set_process(false)
	chart_data = $chart_data_processor.export_data(chart_node.get_chart_data())
	notes_to_spawn = chart_data.notes.duplicate()
	scrollmod_list = chart_data.timing_points.duplicate()
	barlines_to_spawn = chart_data.barlines.duplicate()
	beat_data = chart_data.beats.duplicate()
	notecount = chart_data.notecount
	simlines_to_spawn = chart_data.simlines.duplicate()
	
	if conductor:
		seek_to_playback_time(conductor.get_playback_position())
	set_process(true)
	

func _on_NoteSpeedSpinbox_value_changed(value):
	base_note_screen_time = get_note_screen_time(value)
	
func get_note_screen_time(note_speed: float) -> float:
	return (3 + (10-note_speed)) / note_speed
