extends ColorRect
class_name TimingPoint

var time: float
var type: String

# values related to bpm timing point
var beat_length: float
var meter: int
var bpm_color: Color = Color(1,0,1,1)

# values related to velocity timing point
var velocity: float
var velocity_color: Color = Color(0,1,0,1)

signal custom_gui_input(event, timingpoint)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_data(timingpoint_data: Dictionary):
	time = timingpoint_data.time
	type = timingpoint_data.type
	match type:
		"bpm":
			beat_length = timingpoint_data.beat_length
			meter = timingpoint_data.meter
			color = bpm_color
			$RichTextLabel.add_color_override("default_color", bpm_color)
			$RichTextLabel.bbcode_text = "%s BPM %s/4" % [60.0/beat_length, meter]
		"velocity":
			velocity = timingpoint_data.velocity
			color = velocity_color
			$RichTextLabel.add_color_override("default_color", velocity_color)
			$RichTextLabel.bbcode_text = "[right]%sx[/right]" % velocity
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_TimingPoint_gui_input(event):
	emit_signal("custom_gui_input", event, self)
