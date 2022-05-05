extends LineEdit

var valid: bool
var type: String

var bpm_color: Color = Color.magenta
var velocity_color: Color = Color.green
var invalid_color: Color = Color.red

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func setup(type_input: String):
	type = type_input
	match type_input:
		"bpm":
			placeholder_text = "BPM"
			add_color_override("font_color", bpm_color)
			text = "120.0"
			add_to_group("bpm_timingpoint_value")
		"velocity":
			placeholder_text = "Velocity"
			add_color_override("font_color", velocity_color)
			text = "1.0"
			add_to_group("velocity_timingpoint_value")
	valid = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func is_valid_timingpoint_value(text: String):
	if text.is_valid_float():
		var num: float = float(text)
		if num > 0:
			return true
	return false

func _on_ValueEdit_text_changed(new_text):
	if not is_valid_timingpoint_value(new_text):
		if valid:
			valid = false
			add_color_override("font_color", invalid_color)
	else:
		if not valid:
			valid = true
			match type:
				"bpm":
					add_color_override("font_color", bpm_color)
				"velocity":
					add_color_override("font_color", velocity_color)
